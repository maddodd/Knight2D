extends CanvasLayer

@onready var background_overlay: ColorRect
@onready var panel_container: PanelContainer = $PanelContainer
@onready var vbox_container: VBoxContainer = $PanelContainer/VBoxContainer
@onready var paused_label: Label = $PanelContainer/VBoxContainer/Paused
@onready var resume_button: Button = $PanelContainer/VBoxContainer/Resume
@onready var settings_button: Button = $PanelContainer/VBoxContainer/Settings  # Settings button
@onready var main_menu_button: Button = $"PanelContainer/VBoxContainer/Main Menu"
@onready var quit_button: Button = $"PanelContainer/VBoxContainer/Save and Quit"

func _ready():
	# figyelni minidg hogy megvan e állitva a game
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	visible = false
	
	# Hozzuk létre a háttér overlay-t, ha még nincs
	if not has_node("BackgroundOverlay"):
		background_overlay = ColorRect.new()
		background_overlay.name = "BackgroundOverlay"
		background_overlay.color = Color(0, 0, 0, 0.7)  # Sötét háttér, 70% átlátszatlanság
		background_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(background_overlay)
		move_child(background_overlay, 0)  # Mozgassuk az első helyre
	else:
		background_overlay = $BackgroundOverlay
	
	# Állítsuk be a háttér overlay méretét
	background_overlay.anchor_right = 1.0
	background_overlay.anchor_bottom = 1.0
	background_overlay.offset_left = 0
	background_overlay.offset_top = 0
	background_overlay.offset_right = 0
	background_overlay.offset_bottom = 0
	
	# Állítsuk be a PanelContainer-t középre és megfelelő méretre
	var viewport_size = get_viewport().get_visible_rect().size
	panel_container.anchor_left = 0.5
	panel_container.anchor_top = 1
	panel_container.anchor_right = 0.5
	panel_container.anchor_bottom = 0.5
	panel_container.offset_left = -200  
	panel_container.offset_top = -150 
	panel_container.offset_right = 200
	panel_container.offset_bottom = 150
	
	# JÁTÉK SZÜNETELTETVE
	if paused_label:
		paused_label.text = "JÁTÉK SZÜNETELTETVE"
		paused_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	if resume_button:
		resume_button.text = "Folytatás"
		resume_button.connect("pressed", _on_resume_pressed)
	
	if settings_button:
		settings_button.text = "Beállítások"
		settings_button.connect("pressed", _on_settings_pressed)
	
	if main_menu_button:
		main_menu_button.text = "Főmenü"
		main_menu_button.connect("pressed", _on_main_menu_pressed)
	
	if quit_button:
		quit_button.text = "Kilépés"
		quit_button.connect("pressed", _on_quit_pressed)
	
	# Állítsuk be a VBoxContainer-t
	vbox_container.add_theme_constant_override("separation", 30)

func _input(event):
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		toggle_pause()

func toggle_pause():
	visible = not visible
	get_tree().paused = visible
	
	if background_overlay:
		background_overlay.visible = visible

func _on_resume_pressed():
	toggle_pause()

func _on_settings_pressed():
	print("Beállítások megnyitása")
	var settings_scene = load("res://scenes/bealitasok.tscn")
	var settings_instance = settings_scene.instantiate()
	get_tree().current_scene.add_child(settings_instance)
	settings_instance.open()

func _on_main_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/mainMenu.tscn")

func _on_quit_pressed():
	get_tree().quit()
