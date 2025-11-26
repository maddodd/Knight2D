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
var is_dead := false

# ------------------------------------------------------------
# SWORD + SHIELD VARIABLES
# ------------------------------------------------------------
@export var slash_duration := 0.5
@export var slash_cooldown := 0.5
@export var block_duration := 0.3
@export var block_cooldown := 0.75
@onready var sword_hitbox: Area2D = $SwordHitbox
var is_slashing = false
var can_slash = true
var is_blocking = false
var can_block = true

# ------------------------------------------------------------
# HEALTH SYSTEM + LEVEL FINISH
# ------------------------------------------------------------
@export var max_health := 3
var current_health := max_health
var is_invulnerable := false

signal health_changed(new_value)
signal player_died
var in_finish_zone := false

# ------------------------------------------------------------
# ABILITY UNLOCKS
# ------------------------------------------------------------
var unlocked_abilities := {
	"dash": true,
	"shield": true,
	"sword": true
}

# ------------------------------------------------------------
# MOVEMENT
# ------------------------------------------------------------
func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	if is_dead:
		velocity.y += get_gravity().y * delta
		move_and_slide()
		return

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_rolling:
		velocity.y = JUMP_VELOCITY

	# Roll
	if Input.is_action_just_pressed("roll") and can_roll and not is_rolling and unlocked_abilities.get("dash", false):
		start_roll()

	# Sword
	if Input.is_action_just_pressed("sword") and can_slash and not is_slashing and unlocked_abilities.get("sword", false):
		start_slash()

	# Shield (hold to block)
	if Input.is_action_pressed("shield") and can_block and not is_blocking and unlocked_abilities.get("shield", false):
		start_block()
	elif not Input.is_action_pressed("shield") and is_blocking:
		end_block()

	# Normal movement
	if not is_rolling and not is_blocking:
		var direction := Input.get_axis("move_left", "move_right")
		if direction != 0:
			facing = sign(direction)
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
		animated_sprite.flip_h = facing < 0

	# ANIMATIONS
	var frames := animated_sprite.sprite_frames
	if is_slashing and frames.has_animation("sword"):
		animated_sprite.play("sword")
	elif is_blocking and frames.has_animation("shield"):
		animated_sprite.play("shield")
	elif is_rolling and frames.has_animation("roll"):
		animated_sprite.play("roll")
	elif not is_on_floor() and frames.has_animation("jump"):
		animated_sprite.play("jump")
	elif is_on_floor():
		if abs(velocity.x) > 10 and frames.has_animation("move"):
			animated_sprite.play("move")
		else:
			if frames.has_animation("idle"):
				animated_sprite.play("idle")
	if in_finish_zone and Input.is_action_just_pressed("interact"):
		gameManager.complete_level()

	move_and_slide()
# ------------------------------------------------------------
# ABILITY UNLOCKING
# ------------------------------------------------------------
func unlock_ability(ability: String) -> void:
	gameManager.unlock_ability(ability); unlocked_abilities[ability] = true

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
# SWORD SLASH
# ------------------------------------------------------------
func _on_sword_hitbox_body_entered(body):
	if body.is_in_group("enemies"):
		body.die()

func enable_sword_hitbox() -> void:
	sword_hitbox.monitoring = true
	sword_hitbox.position.x = 12 * facing

func disable_sword_hitbox() -> void:
	sword_hitbox.monitoring = false

func start_slash() -> void:
	is_slashing = true
	can_slash = false
	animated_sprite.play("sword")  
	enable_sword_hitbox()
	
	await animated_sprite.animation_finished
	disable_sword_hitbox()
	is_slashing = false
	await get_tree().create_timer(slash_cooldown).timeout
	can_slash = true

# ------------------------------------------------------------
# SHIELD BLOCK
# ------------------------------------------------------------
func start_block() -> void:
	is_blocking = true
	can_block = false
	animated_sprite.play("shield")

func end_block() -> void:
	is_blocking = false
	await get_tree().create_timer(block_cooldown).timeout
	can_block = true

# ------------------------------------------------------------
# GOOMBA STOMP
# ------------------------------------------------------------

func bounce() -> void:
	velocity.y = JUMP_VELOCITY * 0.6

# ------------------------------------------------------------
# DAMAGE + HEALTH
# ------------------------------------------------------------
func take_damage(amount: int = 1, source_position: Vector2 = Vector2.ZERO) -> void:
	if is_invulnerable or is_rolling or is_blocking:
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
	if not is_inside_tree():
		return
	
	is_dead = true
	$CollisionShape2D.disabled = true
	emit_signal("player_died")

	var frames := animated_sprite.sprite_frames
	if frames and frames.has_animation("die"):
		animated_sprite.play("die")

	Engine.time_scale = 0.5
	if timer:
		timer.start()

	# Disable collisions
	set_collision_layer_value(1, false)
	set_collision_mask_value(2, false)

	# Play death SFX
	var hurt_player = AudioStreamPlayer2D.new()
	add_child(hurt_player)
	var hurt_sound = load("res://assets/sounds/hurt.wav")
	if hurt_sound:
		hurt_player.stream = hurt_sound
		hurt_player.bus = "SFX"
		hurt_player.play()

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
# COIN MESSAGE
# ------------------------------------------------------------
var coins_collected := 0

func _ready() -> void:
	message_label.visible = false
	gameManager.ability_unlocked.connect(_on_ability_unlocked)
<<<<<<< HEAD
=======
	unlocked_abilities = gameManager.unlocked_abilities.duplicate(true)
>>>>>>> b44535a01413dd09e2f12f307fd8d13f728a13c4
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

func demo_ability(ability: String):
	var old_facing = facing
	var old_velocity = velocity
	facing = 1  
	animated_sprite.flip_h = false
	velocity = Vector2.ZERO
	
	match ability:
		"dash":
			start_roll()
		"shield":
			start_block()
			await get_tree().create_timer(0.5).timeout
			end_block()
		"sword":
			start_slash()
	

	facing = old_facing
	animated_sprite.flip_h = facing < 0
	velocity = old_velocity

func _on_finish_reached():  
	in_finish_zone = true

func _on_ability_unlocked(ability):
<<<<<<< HEAD
	show_floating_message("Unlocked: " + gameManager.abilities[ability].name + "!")  # Reuse your coin msg
=======
	show_floating_message("Unlocked: " + gameManager.abilities[ability].name + "!")
>>>>>>> b44535a01413dd09e2f12f307fd8d13f728a13c4
