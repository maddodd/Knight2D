extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -250.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var message_label: Label = $ScoreLabel
@onready var timer: Timer = $Timer #Timer for damage and death logic

# ------------------------------------------------------------
# ROLL SYSTEM VARIABLES
# ------------------------------------------------------------

@export var speed = 100
@export var roll_speed = 225      # Roll movement speed
@export var roll_duration = 0.4     # How long the roll lasts (seconds)
@export var roll_cooldown = 0.5     # Time before next roll allowed
@export var afterimage_interval = 0.05  # Time between ghost images
@export var afterimage_fade_time = 0.3  # How long ghosts fade out

var is_rolling = false
var can_roll = true
var facing = 1  # 1 = right, -1 = left
var coins_collected: int = 0
var hp = 3

# ------------------------------------------------------------
# HEALTH SYSTEM VARIABLES
# ------------------------------------------------------------

@export var max_health := 3
var current_health := max_health
var is_invulnerable := false

signal health_changed(new_value)
signal player_died

# ------------------------------------------------------------
# ABILITY UNLOCK SYSTEM
# ------------------------------------------------------------

var unlocked_abilities = {
	"dash": true,
	"double_jump": false,
	"fireball": false
}

# ------------------------------------------------------------
# MOVEMENT + ROLL LOGIC
# ------------------------------------------------------------

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_rolling:
		velocity.y = JUMP_VELOCITY

	#Rolling check; can't roll if it isn't unlocked yet or the player is rolling already
	if Input.is_action_just_pressed("roll") and can_roll and not is_rolling and unlocked_abilities["dash"]:
		start_roll()

	# Handle horizontal movement (disabled during roll)
	if not is_rolling:
		var direction := Input.get_axis("move_left", "move_right")
		if direction != 0:
			facing = sign(direction)  # store last facing direction
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

		# Flip sprite based on facing
		animated_sprite.flip_h = facing < 0

	# Animations
	if is_rolling:
		animated_sprite.play("roll")
	elif is_on_floor():
		if velocity.x == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("move")
	else:
		animated_sprite.play("jump")

	move_and_slide()

func start_roll():
	is_rolling = true
	can_roll = false

	velocity.x = facing * roll_speed

	# Make player temporarily invulnerable
	set_collision_layer_value(1, false)
	set_collision_mask_value(2, false)

	# Start afterimage loop
	spawn_afterimages()

	await get_tree().create_timer(roll_duration).timeout

	is_rolling = false
	set_collision_layer_value(1, true)
	set_collision_mask_value(2, true)

	velocity.x = 0

	await get_tree().create_timer(roll_cooldown).timeout
	can_roll = true

# ------------------------------------------------------------
# AFTERIMAGE EFFECT
# ------------------------------------------------------------

func spawn_afterimages() -> void:
	# Start a concurrent thread-like coroutine (no nested func needed)
	await _afterimage_loop()


func _afterimage_loop() -> void:
	while is_rolling:
		create_afterimage()
		await get_tree().create_timer(afterimage_interval).timeout

func create_afterimage():
	var ghost := Sprite2D.new()
	var frames := animated_sprite.sprite_frames
	var anim_name := animated_sprite.animation
	var frame_idx := animated_sprite.frame
	var frame_texture := frames.get_frame_texture(anim_name, frame_idx)
	

	ghost.texture = frame_texture
	ghost.flip_h = animated_sprite.flip_h
	ghost.global_position = animated_sprite.global_position
	ghost.scale = animated_sprite.scale
	ghost.modulate = Color(0.991, 0.0, 0.677, 0.6)

	get_parent().add_child(ghost)

	# Tween fade-out and removal
	var tween = get_tree().create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, afterimage_fade_time)
	tween.finished.connect(func(): ghost.queue_free())

# ------------------------------------------------------------
# DAMAGE + HEALTH SYSTEM LOGIC
# ------------------------------------------------------------

func take_damage(amount := 1):
	if is_invulnerable or is_rolling:
		return  # can't take damage while invulnerable or rolling

	current_health -= amount
	emit_signal("health_changed", current_health)
	velocity.x = -facing * 200 #Damage knockback simulation
	flash_red()

	if current_health <= 0:
		die()
	else:
		become_invulnerable(1.0)  # 1 second of invulnerability

func heal(amount := 1):
	current_health = min(current_health + amount, max_health)
	emit_signal("health_changed", current_health)

func die():
	print("Player has died!")
	emit_signal("player_died")
	Engine.time_scale = 0.5 #slower engine for dramatic effect
	timer.start()
	#death SFX
	var hurt_hang_player = AudioStreamPlayer2D.new()
	add_child(hurt_hang_player)
	var hurt_hang = load("res://assets/sounds/hurt.wav")
	if hurt_hang:
		hurt_hang_player.stream = hurt_hang
		hurt_hang_player.bus = "SFX"
		hurt_hang_player.play()
	
	timer.start()

func _on_timer_timeout() -> void:
	Engine.time_scale = 1.0 #regular speed engine after respawn
	get_tree().reload_current_scene()


func become_invulnerable(duration: float):
	is_invulnerable = true
	var tween = get_tree().create_tween()
	tween.tween_property(animated_sprite, "modulate:a", 0.5, 0.1)
	tween.tween_property(animated_sprite, "modulate:a", 1.0, 0.1).set_delay(duration)
	tween.finished.connect(func(): is_invulnerable = false)


func flash_red():
	var tween = get_tree().create_tween()
	tween.tween_property(animated_sprite, "modulate", Color(1, 0.3, 0.3), 0.1)
	tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1), 0.1).set_delay(0.1)

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		take_damage(1)
		if current_health <= 0: 
			body.get_node("CollisionShape2D").queue_free()


# ------------------------------------------------------------
# COIN MESSAGE LOGIC
# ------------------------------------------------------------

func _ready():
	message_label.visible = false

func collect_coin():
	coins_collected += 1
	var msg = "You've collected %d coin%s!" % [coins_collected, ("" if coins_collected == 1 else "s")]
	show_floating_message(msg)

func show_floating_message(text: String):
	message_label.text = text
	message_label.visible = true
	message_label.modulate.a = 1.0
	message_label.size = message_label.get_minimum_size()
	message_label.position = Vector2(-message_label.size.x / 2, -40)

	var tween = create_tween()
	tween.tween_property(message_label, "position:y", message_label.position.y - 20, 1.5)
	tween.tween_property(message_label, "modulate:a", 0.0, 1.5)
	tween.finished.connect(func(): message_label.visible = false)
