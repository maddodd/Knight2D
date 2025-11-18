extends Node2D

const SPEED = 60
var direction = 1

@onready var ray_cast_jobbra: RayCast2D = $RayCastJobbra
@onready var ray_cast_balra: RayCast2D = $RayCastBalra
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox  # add a Hitbox Area2D in scene

func _process(delta: float) -> void:
	# Movement logic
	if ray_cast_jobbra.is_colliding():
		direction = -1
		animated_sprite.flip_h = true

	if ray_cast_balra.is_colliding():
		direction = 1
		animated_sprite.flip_h = false

	position.x += direction * SPEED * delta


func die():
	animated_sprite.play("die")

	var anim_len = animated_sprite.sprite_frames.get_animation_length("die")
	await get_tree().create_timer(anim_len).timeout

	queue_free()


func _on_Hitbox_body_entered(body):
	if body.is_in_group("player"):
		# Check stomp: player is falling down onto the slime
		if body.velocity.y > 0:
			body.bounce()
			die()
		else:
			body.take_damage(1, global_position)
