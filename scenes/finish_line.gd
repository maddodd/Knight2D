extends Area2D

var player_in_zone := false
signal finish_reached

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	collision_mask = 2

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_zone = true
		finish_reached.emit()

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_zone = false
