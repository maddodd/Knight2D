extends VBoxContainer

@onready var button: TextureButton = $TextureButton
@onready var player = get_tree().get_first_node_in_group("player")

var ability: String

func setup(_ability: String):
	ability = _ability
	var data = gameManager.ABILITIES[ability]
	$Label.text = data.name
	$DescLabel.text = data.desc
	button.pressed.connect(_on_pressed)
	button.mouse_entered.connect(_on_hovered)
	button.mouse_exited.connect(_on_unhovered)

func _on_pressed():
	get_parent().get_parent().get_parent()._on_ability_selected(ability)

func _on_hovered():
	player.demo_ability(ability)

func _on_unhovered():
	player.animated_sprite.play("idle")
