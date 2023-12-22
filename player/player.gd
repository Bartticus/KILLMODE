class_name Player
extends Character

signal die
signal kill
@onready var hit_particles = preload("res://player/hit_particles.tscn")
@onready var bullet_scene = preload("res://player/bullet.tscn")
@onready var arcane_scene = preload("res://player/arcane_bolt.tscn")

#Player variables
var speed: float = 10.0
var h_accel: float = 50.0
var movement_vector := Vector3.ZERO
var attack_range: float
var attack_mode: String = Global.combat_modes[0]
var sword_swung: bool = false

func _physics_process(_delta):
	Global.debug.add_property("Attack mode", attack_mode)
	attack_mode_manager()
	
	move_and_slide()

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
	#Move weapon mesh in direction of attack
	$WeaponPivot.position = direction
	$WeaponPivot.look_at(position + direction * 2)
	
	if attack_mode == "Sword": #If attacking with sword
		if sword_swung:
			$AnimationPlayer.play_backwards(attack_mode) #Reverse animation if already swung
			sword_swung = false
		else:
			$AnimationPlayer.play(attack_mode) #Otherwise play foward
			sword_swung = true
	else:
		$AnimationPlayer.play(attack_mode) #Just play other animations
	
	spawn_rays(direction)
	if attack_mode == "Gun" or attack_mode == "Magic": shoot(direction) #Spawn projectile for gun or magic

func shoot(direction: Vector3): #Shoot a projectile at the enemies
	var projectile: Area3D #Set projectile based on attack mode
	if attack_mode == "Gun": projectile = bullet_scene.instantiate()
	if attack_mode == "Magic": projectile = arcane_scene.instantiate()
	
	#Set projectile properties
	add_child(projectile)
	projectile.rotation.y = direction.x * 90
	projectile.global_position = direction
	var target_position = direction * attack_range + Vector3(0,0.5,0) #Set target position
	
	#Create a ray that targets enemies, range based on attack type
	var ray := RayCast3D.new()
	ray.position = Vector3.ZERO
	ray.target_position = direction * attack_range
	ray.collision_mask = 4 #Enemy collision mask value
	
	#Spawn ray to check for potential collisions before enemy is killed
	add_child(ray)
	ray.force_raycast_update()
	if ray.is_colliding(): target_position = ray.get_collision_point() #Change target position to collision point
	ray.queue_free()
	
	#Use tween to move projectile hitbox towards enemies
	var tween = get_tree().create_tween()
	tween.tween_property(projectile, "global_position", target_position, 0.1)
	tween.tween_callback(projectile.queue_free) #Remove projectile at end of tween	

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
	kill.emit() #Emit kill signal for score keeping in UI
	
	#Start spawning particles where enemy died
	var particles = hit_particles.instantiate()
	add_child(particles)
	particles.global_position = spawn_location
	particles.get_child(0).emitting = true
	
	#Timer to wait out artifacting
	particles.get_child(1).hide()
	await get_tree().create_timer(0.1).timeout
	particles.get_child(1).show()
	
	#Wait out particle effects before removing
	await get_tree().create_timer(3).timeout
	particles.queue_free()

func _input(_event):
	#Checking inputs for attacks in each direction
	if Input.is_action_just_pressed("attack_left"):
		attack(Vector3.LEFT)
	if Input.is_action_just_pressed("attack_right"):
		attack(Vector3.RIGHT)
	if Input.is_action_just_pressed("attack_forward"):
		attack(Vector3.FORWARD)
	if Input.is_action_just_pressed("attack_backward"):
		attack(Vector3.BACK)
	
	#Checking inputs for switching attack modes
	if Input.is_action_just_pressed("sword_mode"):
		attack_mode = Global.combat_modes[0]
	if Input.is_action_just_pressed("gun_mode"):
		attack_mode = Global.combat_modes[1]
	if Input.is_action_just_pressed("kick_mode"):
		attack_mode = Global.combat_modes[2]
	if Input.is_action_just_pressed("magic_mode"):
		attack_mode = Global.combat_modes[3]

func _on_player_hurt_area_body_entered(_body):
	die.emit() #Emit die signal for resetting UI
	queue_free()
