extends Area2D

@onready var game_manager: Node = %GameManager
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _on_body_entered(body):
	if body.is_in_group("player"):
		body.collect_coin()
		queue_free()  # remove the coin
		animation_player.play("pickup")
