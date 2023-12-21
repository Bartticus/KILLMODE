extends Control

var score = 0
@export var multiplier = 1

func _ready():
	$Retry.hide()
	$ScoreLabel.hide()
	$FloatingText.hide()
	$FloatingText/Pivot/MeshInstance3D.mesh.text = "0"
	
	var player = get_node("/root/Main/Player")
	player.die.connect(_on_player_die)
	player.kill.connect(_on_enemy_kill)

func _on_player_die():
	multiplier = 1
	$FloatingText/AnimationPlayer.play("RESET", 1.0)

func _on_enemy_kill():
	score += 1
	$ScoreLabel.text = "Score: %s" % score
	
	$FloatingText/Pivot/MeshInstance3D.mesh.text = "%s!!!" % score
	$FloatingText/AnimationPlayer.play("spin", 1.0)
