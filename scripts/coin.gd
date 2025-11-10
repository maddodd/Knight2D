extends Area2D

@onready var game_manager: Node = %GameManager
@onready var animation_player: AnimationPlayer = $AnimationPlayer
var audio_player: AudioStreamPlayer2D

func _ready():
	
	audio_player = AudioStreamPlayer2D.new()
	add_child(audio_player)
	# ccoin  hang
	var coin_hang = load("res://assets/sounds/coin.wav")
	if coin_hang:
		audio_player.stream = coin_hang
	audio_player.bus = "SFX"
	
	
func _on_body_entered(body):
	if body.is_in_group("player"):
		body.collect_coin()
		animation_player.play("pickup")
		audio_player.play()  # lejátsza a coin hangot
		
		# megvárja az animációt
		await animation_player.animation_finished
		queue_free()  # remove the coin
