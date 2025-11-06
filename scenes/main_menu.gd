extends Control

func _ready():
	$VBoxContainer/Play.connect("pressed", _on_start_pressed)
#	$VBoxContainer/Settings.connect("pressed", _on_settings_pressed)
	$VBoxContainer/Exit.connect("pressed", _on_quit_pressed)

func _on_start_pressed():
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_quit_pressed():
	get_tree().quit()

#func _on_settings_pressed():
#	get_tree().change_scene_to_file("res://scenes/settings.tscn")
