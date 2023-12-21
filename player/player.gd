class_name Player
extends Character

signal die
signal kill
@onready var hit_particles = preload("res://player/hit_particles.tscn")

#Player variables
var speed: float = 10.0
var h_accel: float = 50.0
var movement_vector := Vector3.ZERO
var attack_range: float
var attack_mode: String = Global.combat_modes[0]

@onready var move_timer = get_node("/root/Main/MoveTimer")
var last_anim_played: String
#var action_taken: bool = false

func _physics_process(_delta):
	Global.debug.add_property("Attack mode", attack_mode)
	attack_mode_manager()
	
	move_and_slide()
	
	#if move_timer.time_left < (move_timer.wait_time - 0.1) and move_timer.time_left > 0.1:
		#action_taken = false

func attack_mode_manager():
	for child in $WeaponPivot.get_children(): #Hide all weapons not being used
		child.hide()
	
	var attack_range_material = $AttackRangeMesh.mesh.material
	match attack_mode: #Match current attack mode once the player has switched it
		"Sword":
			$WeaponPivot/SwordMesh.show() #Show weapon mesh
			attack_range = 4.0 #Set attack range
			attack_range_material.emission = Color.RED #Change range emission color
			attack_range_material.albedo_color = Color(1,0,0,0.4) #Change range material color
		"Gun":
			$WeaponPivot/GunMesh.show()
			attack_range = 10.0
			attack_range_material.emission = Color.ORANGE
			attack_range_material.albedo_color = Color(1,0.647,0,0.4)
		"Kick":
			$WeaponPivot/KickMesh.show()
			attack_range = 3.0
			attack_range_material.emission = Color.DARK_GREEN
			attack_range_material.albedo_color = Color(0,1,0,0.4)
		"Magic":
			$WeaponPivot/MagicMesh.show()
			attack_range = 7.0
			attack_range_material.emission = Color.BLUE
			attack_range_material.albedo_color = Color(0,0,1,0.4)
	
	$AttackRangeMesh.mesh.inner_radius = attack_range #Set attack range inner/outer radii
	$AttackRangeMesh.mesh.outer_radius = attack_range + 0.1

func attack(direction: Vector3):
	if last_anim_played == attack_mode:
		$AnimationPlayer.play_backwards(attack_mode)
		last_anim_played = ""
	else:
		$AnimationPlayer.play(attack_mode)
		last_anim_played = attack_mode
	
	#Move weapon mesh in direction of attack
	$WeaponPivot.position = direction
	$WeaponPivot.look_at(position + direction * 2)
	
	spawn_rays(direction)

func spawn_rays(direction: Vector3): #Spawn rays as a hitbox for enemy detection
	var enemy: Enemy
	
	#Create a ray that targets enemies, range based on attack type
	var ray := RayCast3D.new()
	ray.position = Vector3.ZERO
	ray.target_position = direction * attack_range
	ray.collision_mask = 4 #Enemy collision mask value
	
	#Spawn ray, kill enemy it collides with
	add_child(ray)
	ray.force_raycast_update()
	if ray.is_colliding():
		enemy = ray.get_collider()
		#Check if the enemy type matches the attack type
		if enemy.enemy_mode == attack_mode:
			kill_enemy(ray.get_collision_point())
			enemy.queue_free() #Kill enemy
			ray.enabled = false #Disable ray to not kill anymore enemies
	#Attack timer
	await get_tree().create_timer(0.1).timeout
	
	#Recheck collision at end of lifecycle
	ray.force_raycast_update()
	if ray.is_colliding() and ray.enabled:
		enemy = ray.get_collider()
		if enemy.enemy_mode == attack_mode:
			kill_enemy(ray.get_collision_point())
			enemy.queue_free()
	ray.queue_free()

func kill_enemy(spawn_location: Vector3):
	kill.emit()
	
	var particles = hit_particles.instantiate()
	add_child(particles)
	particles.global_position = spawn_location
	particles.get_child(0).emitting = true
	
	#Timer to wait out artifacting
	particles.get_child(1).hide()
	await get_tree().create_timer(0.1).timeout
	particles.get_child(1).show()
	
	await get_tree().create_timer(3).timeout
	particles.queue_free()

func _input(_event):
	#if move_timer.time_left > 0.1 and move_timer.time_left < (move_timer.wait_time - 0.1): return
	#if action_taken == true: return
	#Checking inputs for attacks in each direction
	if Input.is_action_just_pressed("attack_left"):
		attack(Vector3.LEFT)
		#action_taken = true
	if Input.is_action_just_pressed("attack_right"):
		attack(Vector3.RIGHT)
		#action_taken = true
	if Input.is_action_just_pressed("attack_forward"):
		attack(Vector3.FORWARD)
		#action_taken = true
	if Input.is_action_just_pressed("attack_backward"):
		attack(Vector3.BACK)
		#action_taken = true
		
	#Checking inputs for switching attack modes
	if Input.is_action_just_pressed("sword_mode"):
		attack_mode = Global.combat_modes[0]
		#action_taken = true
	if Input.is_action_just_pressed("gun_mode"):
		attack_mode = Global.combat_modes[1]
		#action_taken = true
	if Input.is_action_just_pressed("kick_mode"):
		attack_mode = Global.combat_modes[2]
		#action_taken = true
	if Input.is_action_just_pressed("magic_mode"):
		attack_mode = Global.combat_modes[3]
		#action_taken = true

func _on_player_hurt_area_body_entered(_body):
	die.emit()
	queue_free()
