extends VBoxContainer

@onready var select: Button = $Button
@onready var player = get_tree().get_first_node_in_group("player")

var ability: String

func setup(_ability: String):
	ability = _ability
	var data = gameManager.abilities[ability]
	$Label.text = data.name
	$DescLabel.text = data.desc
	$TextureRect.texture = load("res://assets/sprites/knight_standing.png")
	select.pressed.connect(_on_pressed)
	select.mouse_entered.connect(_on_hovered)
	select.mouse_exited.connect(_on_unhovered)

func _on_pressed():
	get_parent().get_parent().get_parent()._on_ability_selected(ability)

func _on_hovered():
	player.demo_ability(ability)

func _on_unhovered():
	player.animated_sprite.play("idle")
