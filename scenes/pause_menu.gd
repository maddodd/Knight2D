extends CanvasLayer

func _ready():
	visible = false
	$PanelContainer/VBoxContainer/Resume.connect("pressed", _on_resume_pressed)
#	$PanelContainer/VBoxContainer/Settings.connect("pressed", _on_settings_pressed)
	$"PanelContainer/VBoxContainer/Main Menu".connect("pressed", _on_main_menu_pressed)
	$"PanelContainer/VBoxContainer/Save and Quit".connect("pressed", _on_quit_pressed)



func _input(event):
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause():
	visible = not visible
	get_tree().paused = visible

func _on_resume_pressed():
	toggle_pause()

#func _on_settings_pressed():
#	get_tree().change_scene_to_file("res://scenes/settingsFromGame.tscn")

func _on_main_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/mainMenu.tscn")

func _on_quit_pressed():
	get_tree().quit()
