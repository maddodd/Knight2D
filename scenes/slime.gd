extends CharacterBody2D

const SPEED := 60
var direction := 1

@onready var ray_left: RayCast2D = $RayCastBalra
@onready var ray_right: RayCast2D = $RayCastJobbra
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_collider: CollisionShape2D = $CollisionShape2D
@onready var hitbox: Area2D = $Hitbox

func _physics_process(delta: float) -> void:
	velocity.x = direction * SPEED

	
	if ray_right.is_colliding():
		direction = -1
		sprite.flip_h = true

	if ray_left.is_colliding():
		direction = 1
		sprite.flip_h = false

	move_and_slide()

func die():
	
	var tween = get_tree().create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 0.3, 0.3), 0.1)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	tween.finished.connect(queue_free)

func _on_Hitbox_body_entered(body):
	if not body.is_in_group("player"):
		return
	
	var stomp_offset := 24 
	
	var above: bool = body.global_position.y > global_position.y - stomp_offset
	var falling: bool = body.velocity.y > -20 


	if above and falling:
		body.bounce()
		die()
	else:
		body.take_damage(1, global_position)
