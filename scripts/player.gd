extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -250.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var message_label: Label = $ScoreLabel

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

	
	if Input.is_action_just_pressed("roll") and can_roll and not is_rolling:
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

	# ✅ Use the correct Godot 4 method
	var frame_texture := frames.get_frame_texture(anim_name, frame_idx)

	ghost.texture = frame_texture
	ghost.flip_h = animated_sprite.flip_h
	ghost.global_position = animated_sprite.global_position
	ghost.scale = animated_sprite.scale
	ghost.modulate = Color(1, 1, 1, 0.6)  # semi-transparent

	get_parent().add_child(ghost)

	# Tween fade-out and removal
	var tween = get_tree().create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, afterimage_fade_time)
	tween.finished.connect(func(): ghost.queue_free())

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
