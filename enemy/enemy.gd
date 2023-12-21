class_name Enemy
extends RigidBody3D

@export var enemy_mode: String
@export var path_follow: PathFollow3D

func _ready():
	#Match enemy mode to corresponding color
	match enemy_mode:
		"Sword":
			$EnemyMesh.mesh.material.albedo_color = Color.RED
		"Gun":
			$EnemyMesh.mesh.material.albedo_color = Color.ORANGE
		"Kick":
			$EnemyMesh.mesh.material.albedo_color = Color.GREEN
		"Magic":
			$EnemyMesh.mesh.material.albedo_color = Color.BLUE
	
	#Spawn enemy at the start of it's chosen path
	global_position = path_follow.position
	Global.debug.add_property("Path", path_follow.get_parent().name)
	
	#Connect move timer signal to this enemy
	var timer = get_node("/root/Main/MoveTimer")
	timer.timeout.connect(_on_move_timer_timeout)

func _on_move_timer_timeout():
	move_along_path()

func move_along_path(): #Enemy will move down the path towards the center
	var progress_step: float = 0.1
	var new_progress := path_follow.progress_ratio + progress_step
	
	#Create a tween to interpolate between current progress and new progress
	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT) #Change tween type
	tween.tween_property(path_follow, "progress_ratio", new_progress, 0.5)
	

func _exit_tree(): #Upon dying
	path_follow.queue_free() #Delete the path follow create for this enemy
