extends CharacterBody2D



const SPEED = 100.0
const JUMP_VELOCITY = -250.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	
	
	
	
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")
	
	#Megfordítja az animációt
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
	
	#Animációk
	if is_on_floor():
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("move")
	else:
		animated_sprite.play("jump")

	
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

@onready var message_label: Label = $ScoreLabel
var coins_collected: int = 0

func _ready():
	message_label.visible = false

func collect_coin():
	coins_collected += 1
	show_floating_message("You've collected %d coins!" % coins_collected)

func show_floating_message(text: String):
	message_label.text = text
	message_label.visible = true
	message_label.modulate.a = 1.0  # full opacity
	
	# Center label horizontally above player, doesn't work with other tried solutions so this does the trick
	message_label.position = Vector2(-message_label.size.x / 2, -40)  # just above player head
	
	message_label.size = message_label.get_minimum_size()
	message_label.pivot_offset = message_label.size / 2.0
	
	var tween = create_tween()
	# Float upward 20 pixels over 1.5 seconds
	tween.tween_property(message_label, "position:y", message_label.position.y - 20, 1.5)
	# Fade out at the same time
	tween.tween_property(message_label, "modulate:a", 0.0, 1.5)

	# When done, hide the label
	tween.finished.connect(func():
		message_label.visible = false
	)
