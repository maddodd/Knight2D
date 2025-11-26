extends CanvasLayer
class_name CompletionUI

@onready var player: Node2D = get_tree().get_first_node_in_group("player")

func _ready():
	gameManager.level_completed.connect(show)
	visible = false
	setup_buttons()

func setup_buttons():
	var hbox = $UIContainer/VBoxContainer/HBoxContainer
	for ability in gameManager.abilities:
		var vbox = preload("res://scenes/AbilityOption.tscn").instantiate()
		vbox.setup(ability)
		hbox.add_child(vbox)

func show_ui(_level):
	get_tree().paused = true
	visible = true
	var tween = create_tween()
	$UIContainer.modulate.a = 0
	tween.tween_property($UIContainer, "modulate:a", 1.0, 0.5)

func hide_ui():
	get_tree().paused = false
	visible = false
	var next_scene = gameManager.get_next_level()
	if ResourceLoader.exists(next_scene):
		get_tree().change_scene_to_file(next_scene)
	else:
		get_tree().change_scene_to_file("res://MainMenu.tscn")

# Connect in editor or code: buttons' pressed/mouse_entered
func _on_ability_selected(ability: String):
	gameManager.unlock_ability(ability)
	var tween = create_tween()
	tween.tween_callback(hide).set_delay(1.0)  # Flash success
