extends Node

#Preload each enemy type
@onready var preloaded_enemy = preload("res://enemy/enemy.tscn")

func _ready():
	randomize() #Randomize rng on startup
	
	$MusicPlayer.play()
	$UserInterface2/HighScore.text = "High Score: %s" % load_score()
	
	$Player.die.connect(_on_player_die)

func reduce_timers(): #Decrease timer lengths to increase difficulty over time
	var new_wait_time = clampf($SpawnTimer.wait_time - 0.01, 0.5, 1.3)
	#Set new wait times, shorter each time
	$SpawnTimer.start(new_wait_time)
	$MoveTimer.start(new_wait_time)
	
	await $MoveTimer.timeout
	
	reduce_timers() #Repeat function

func _on_spawn_timer_timeout(): #Start spawning enemies when timer runs out
	var enemy_scene: PackedScene = preloaded_enemy
	var enemy: Enemy = enemy_scene.instantiate()
	
	var enemy_mode = randi_range(0,3) #Pick enemy type randomly
	var enemy_path: Path3D = [ #Pick enemy path to spawn on randomly
		$MoveTimer/NorthPath,
		$MoveTimer/EastPath,
		$MoveTimer/SouthPath,
		$MoveTimer/WestPath
	].pick_random()
	
	var path_follow = PathFollow3D.new() #Create path follow for each enemy
	enemy_path.add_child(path_follow) #Add path follow child to path
	
	#Set enemy variables
	enemy.enemy_mode = Global.combat_modes[enemy_mode]
	enemy.path_follow = path_follow
	path_follow.add_child(enemy) #Add enemy to path follow
	

func _unhandled_input(event):
	if Input.is_action_pressed("ui_cancel"):
		get_tree().quit() #Quit on escape
	if event.is_action_pressed("ui_accept") and $UserInterface2/Retry.visible:
		get_tree().reload_current_scene() #Reload on control
	elif event.is_action_pressed("ui_accept") and $UserInterface2/StartLabel.visible:
		$UserInterface2/GameStart.play() #Start game on enter
		$UserInterface2/StartLabel.hide()
		$UserInterface2/ScoreLabel.show()
		$UserInterface2/FloatingText.show()
		$UserInterface2/FloatingText/Pivot/MeshInstance3D.mesh.text = "0"
		reduce_timers()
		$SpawnTimer.start()

func _on_player_die():
	$MusicPlayer.stop()
	$DieSound.play()
	await get_tree().create_timer(1).timeout #Wait a second for dramatic effect
	$UserInterface2/ScoreLabel.hide()
	$UserInterface2/FloatingText.hide()
	$UserInterface2/Retry.show()
	
	#Get score to save it later as high score
	var score = $UserInterface2.score
	$UserInterface2/Retry/FinalScore.text = "Final Score: %s" % score
	
	#Overwrite save file if new score is higher
	var high_score = load_score()
	if score > high_score:
		save_score(score)
		high_score = score
		$UserInterface2/Retry/DeathLabel.text = "New high score!"
	
	$UserInterface2/HighScore.text = "High Score: %s" % high_score

#Save high score to file
func save_score(score):
	var file = FileAccess.open("user://save_game.dat",FileAccess.WRITE)
	file.store_32(score)

#Load high score from file
func load_score():
	var file = FileAccess.open("user://save_game.dat",FileAccess.READ)
	var high_score = 0
	if FileAccess.file_exists("user://save_game.dat"):
		high_score = file.get_32()
	return high_score
