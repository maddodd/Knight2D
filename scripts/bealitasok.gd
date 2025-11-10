extends CanvasLayer
var hang_label: Label 
var hang_slider: HSlider  # Ezt is hozzáadtam, hogy könnyen elérhető legyen

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	create_ui()

func create_ui():
	# Háttér overlay
	var background_overlay = ColorRect.new()
	background_overlay.name = "BackgroundOverlay"
	background_overlay.color = Color(0, 0, 0, 0.8)
	background_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_overlay.anchor_right = 1.0
	background_overlay.anchor_bottom = 1.0
	background_overlay.offset_left = 0
	background_overlay.offset_top = 0
	background_overlay.offset_right = 0
	background_overlay.offset_bottom = 0
	add_child(background_overlay)
	
	# Panel
	var panel_container = PanelContainer.new()
	panel_container.anchor_left = 0.5
	panel_container.anchor_top = 0.5
	panel_container.anchor_right = 0.5
	panel_container.anchor_bottom = 0.5
	panel_container.offset_left = -200
	panel_container.offset_top = -150
	panel_container.offset_right = 200
	panel_container.offset_bottom = 150
	
	# Egyszerű panel stílus
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.15, 0.15, 0.15)
	style_box.border_color = Color(0.4, 0.4, 0.4)
	style_box.border_width_left = 2
	style_box.border_width_top = 2
	style_box.border_width_right = 2
	style_box.border_width_bottom = 2
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_right = 8
	style_box.corner_radius_bottom_left = 8
	panel_container.add_theme_stylebox_override("panel", style_box)
	
	add_child(panel_container)
	
	var vbox_container = VBoxContainer.new()
	vbox_container.add_theme_constant_override("separation", 20)
	panel_container.add_child(vbox_container)
	
	# Cím
	var settings_label = Label.new()
	settings_label.text = "BEÁLLÍTÁSOK"
	settings_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings_label.add_theme_font_size_override("font_size", 24)
	vbox_container.add_child(settings_label)
	
	# Üres tér
	var ter1 = Control.new()
	ter1.custom_minimum_size.y = 10
	vbox_container.add_child(ter1)
	
	# Hangerő label
	var volume_label = Label.new()
	volume_label.text = "Hangerő"
	volume_label.add_theme_font_size_override("font_size", 18)
	vbox_container.add_child(volume_label)
	
	# Hangerő csúszka
	hang_slider = HSlider.new()  # Itt se használj var-t!
	hang_slider.min_value = 0
	hang_slider.max_value = 100
	hang_slider.value = jelenlegi_hangerő() 
	hang_slider.connect("value_changed", hang_valtozas)  # JAVÍTVA: "value_changed" kell legyen
	vbox_container.add_child(hang_slider)
	
	# Hangerő érték
	hang_label = Label.new()
	hang_label.text = str(int(hang_slider.value)) + "%"
	hang_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hang_label.add_theme_font_size_override("font_size", 14)
	vbox_container.add_child(hang_label)
	
	# Üres tér
	var ter2 = Control.new()
	ter2.custom_minimum_size.y = 20
	vbox_container.add_child(ter2)
	
	# Vissza gomb
	var vissza_button = Button.new()
	vissza_button.text = "Vissza"
	vissza_button.custom_minimum_size.y = 40
	vissza_button.connect("pressed", _on_back_pressed)
	vbox_container.add_child(vissza_button)

# A jelenlegi hangerőt lekéri
func jelenlegi_hangerő():  # JAVÍTVA: helyes ékezet
	# Master bus jelenlegi hangerője
	var master_index = AudioServer.get_bus_index("Master")
	var jelenlegi_db = AudioServer.get_bus_volume_db(master_index)
	var hang_szazalek = db_to_linear(jelenlegi_db) * 100
	return hang_szazalek

# Hangerő beállítása
func hang_beallitas(volume_percent: float):  # JAVÍTVA: logikusabb név
	var master_index = AudioServer.get_bus_index("Master")
	var hang_db = linear_to_db(volume_percent / 100.0)
	AudioServer.set_bus_volume_db(master_index, hang_db)

func open():
	visible = true

func close():
	visible = false
	queue_free()

func hang_valtozas(value: float):
	# Volume érték frissítése a label-en
	if hang_label:
		hang_label.text = str(int(value)) + "%"
	
	# Hangerő beállítása a rendszerben
	hang_beallitas(value)  # JAVÍTVA: helyes függvénynév
	
	print("Hangerő beállítva: ", value, "%")

func _on_back_pressed():
	close()

func _input(event):
	if event.is_action_pressed("ui_cancel") and visible:
		get_viewport().set_input_as_handled()
		close()
