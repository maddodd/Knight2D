extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -250.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var message_label: Label = $ScoreLabel
@onready var timer: Timer = $Timer

# ------------------------------------------------------------
# ROLL VARIABLES
# ------------------------------------------------------------
@export var roll_speed := 225
@export var roll_duration := 0.4
@export var roll_cooldown := 0.5
@export var afterimage_interval := 0.05
@export var afterimage_fade_time := 0.3

var is_rolling = false
var can_roll = true
var facing := 1

# ------------------------------------------------------------
# HEALTH SYSTEM
# ------------------------------------------------------------
@export var max_health := 3
var current_health := max_health
var is_invulnerable := false

signal health_changed(new_value)
signal player_died

# ------------------------------------------------------------
# ABILITY UNLOCKS
# ------------------------------------------------------------
var unlocked_abilities := {
	"dash": true,
	"double_jump": false,
	"fireball": false
}

# ------------------------------------------------------------
# MOVEMENT
# ------------------------------------------------------------
func _physics_process(delta: float) -> void:

	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_rolling:
		velocity.y = JUMP_VELOCITY

	# Roll
	if Input.is_action_just_pressed("roll") and can_roll and not is_rolling and unlocked_abilities["dash"]:
		start_roll()

	# Normal movement
	if not is_rolling:
		var direction := Input.get_axis("move_left", "move_right")
		if direction != 0:
			facing = sign(direction)
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

		animated_sprite.flip_h = facing < 0

	# ANIMATIONS
	var frames := animated_sprite.sprite_frames

	if is_rolling and frames.has_animation("roll"):
		animated_sprite.play("roll")

	elif is_on_floor():
		if velocity.x == 0 and frames.has_animation("idle"):
			animated_sprite.play("idle")
		elif frames.has_animation("move"):
			animated_sprite.play("move")

	elif frames.has_animation("jump"):
		animated_sprite.play("jump")

	move_and_slide()

# ------------------------------------------------------------
# ROLLING
# ------------------------------------------------------------
func start_roll() -> void:
	is_rolling = true
	can_roll = false

	velocity.x = facing * roll_speed

	set_collision_layer_value(1, false)
	set_collision_mask_value(2, false)

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
	_afterimage_loop()

func _afterimage_loop() -> void:
	while is_rolling:
		create_afterimage()
		await get_tree().create_timer(afterimage_interval).timeout

func create_afterimage():

	var frames := animated_sprite.sprite_frames
	var anim := animated_sprite.animation
	var idx := animated_sprite.frame

	var tex: Texture2D = null
	if frames.has_animation(anim):
		tex = frames.get_frame_texture(anim, idx)

	if tex == null:
		return

	var ghost := Sprite2D.new()
	ghost.texture = tex
	ghost.global_position = animated_sprite.global_position
	ghost.flip_h = animated_sprite.flip_h
	ghost.scale = animated_sprite.scale
	ghost.modulate = Color(1,1,1,0.6)

	get_parent().add_child(ghost)

	var tween = get_tree().create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, afterimage_fade_time)
	tween.finished.connect(func(): ghost.queue_free())

# ------------------------------------------------------------
# DAMAGE + HEALTH
# ------------------------------------------------------------
func take_damage(amount: int = 1, source_position: Vector2 = Vector2.ZERO) -> void:
	if is_invulnerable or is_rolling:
		return

	current_health -= amount
	emit_signal("health_changed", current_health)

	# Knockback
	var dir: float = sign(global_position.x - source_position.x)
	velocity.x = dir * 200
	velocity.y = -120

	flash_red()

	if current_health <= 0:
		die()
	else:
		become_invulnerable(1.0)

func heal(amount := 1) -> void:
	current_health = min(current_health + amount, max_health)
	emit_signal("health_changed", current_health)

func die() -> void:
	if animated_sprite.sprite_frames.has_animation("die"):
		animated_sprite.play("die")

	emit_signal("player_died")

	Engine.time_scale = 0.5
	timer.start()

	set_collision_layer_value(1, false)
	set_collision_mask_value(2, false)

func _on_timer_timeout() -> void:
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()

func become_invulnerable(duration: float) -> void:
	is_invulnerable = true
	var tween = get_tree().create_tween()
	tween.tween_property(animated_sprite, "modulate:a", 0.5, 0.1)
	tween.tween_property(animated_sprite, "modulate:a", 1.0, 0.1).set_delay(duration)
	tween.finished.connect(func(): is_invulnerable = false)

func flash_red() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(animated_sprite, "modulate", Color(1,0.3,0.3), 0.08)
	tween.tween_property(animated_sprite, "modulate", Color(1,1,1), 0.08).set_delay(0.08)

# ------------------------------------------------------------
# ENEMY COLLISION (STOMP LOGIC)
# ------------------------------------------------------------
func _on_body_entered(body: Node) -> void:
	if body and body.is_in_group("enemies"):

		var stomp_offset := 8.0
		var stomp: bool = (velocity.y > 0 and global_position.y < body.global_position.y - stomp_offset)

		if stomp:
			if body.has_method("die"):
				body.die()
			velocity.y = JUMP_VELOCITY * 0.6
		else:
			take_damage(1, body.global_position)

# ------------------------------------------------------------
# COIN MESSAGE
# ------------------------------------------------------------
var coins_collected := 0

func _ready() -> void:
	message_label.visible = false

	if not is_in_group("player"):
		add_to_group("player")

func collect_coin() -> void:
	coins_collected += 1
	var msg = "You've collected %d coin%s!" % [coins_collected, ("" if coins_collected == 1 else "s")]
	show_floating_message(msg)

func show_floating_message(text: String) -> void:
	message_label.text = text
	message_label.visible = true
	message_label.modulate.a = 1.0

	message_label.size = message_label.get_minimum_size()
	message_label.position = Vector2(-message_label.size.x / 2, -40)

	var tween = create_tween()
	tween.tween_property(message_label, "position:y", message_label.position.y - 20, 1.5)
	tween.tween_property(message_label, "modulate:a", 0.0, 1.5)
	tween.finished.connect(func(): message_label.visible = false)
