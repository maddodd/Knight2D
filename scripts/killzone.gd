extends Area2D

@onready var timer: Timer = $Timer
@export var instant_kill := true    # if true, kills outright; if false, deals full HP damage by calling take_damage

func _ready() -> void:
	# Ensure timer is stopped initially
	if timer:
		timer.stop()

func _on_body_entered(body: Node) -> void:
	# Only react to the player
	if not body:
		return
	if not body.is_in_group("player"):
		return

	# Dramatic slow-motion + sound
	Engine.time_scale = 0.5

	# Play hurt SFX
	var hurt_player = AudioStreamPlayer2D.new()
	add_child(hurt_player)
	var hurt_sound = load("res://assets/sounds/hurt.wav")
	if hurt_sound:
		hurt_player.stream = hurt_sound
		hurt_player.bus = "SFX"
		hurt_player.play()

	# If we want an instant kill, call player's die() if available
	if instant_kill and body.has_method("die"):
		# Let the player handle death (animation / timer / respawn)
		body.die()
	else:
		# Otherwise, attempt to deal damage equal to current health (force death)
		if body.has_method("take_damage"):
			# Pass killzone position so knockback direction is away from zone (optional)
			body.take_damage(body.current_health, global_position)

	# Start respawn timer (player die() may also start its own timer; this keeps current behaviour)
	if timer:
		timer.start()

func _on_timer_timeout() -> void:
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()
