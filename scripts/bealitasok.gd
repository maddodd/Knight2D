extends CanvasLayer
var master_label: Label 
var master_slider: HSlider
var music_label: Label
var music_slider: HSlider
var sfx_label: Label
var sfx_slider: HSlider

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
	
	# Panel - nagyobb a több csúszka miatt
	var panel_container = PanelContainer.new()
	panel_container.anchor_left = 0.5
	panel_container.anchor_top = 0.5
	panel_container.anchor_right = 0.5
	panel_container.anchor_bottom = 0.5
	panel_container.offset_left = -250
	panel_container.offset_top = -200
	panel_container.offset_right = 250
	panel_container.offset_bottom = 200
	
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
	vbox_container.add_theme_constant_override("separation", 15)
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
	
	# === MAIN HANGERŐ ===
	var master_volume_label = Label.new()
	master_volume_label.text = "Fő hangerő"
	master_volume_label.add_theme_font_size_override("font_size", 18)
	vbox_container.add_child(master_volume_label)
	
	master_slider = HSlider.new()
	master_slider.min_value = 0
	master_slider.max_value = 100
	master_slider.value = jelenlegi_hangerő("Master")
	master_slider.connect("value_changed", master_hang_valtozas)
	vbox_container.add_child(master_slider)
	
	master_label = Label.new()
	master_label.text = str(int(master_slider.value)) + "%"
	master_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	master_label.add_theme_font_size_override("font_size", 14)
	vbox_container.add_child(master_label)
	
	# Üres tér
	var ter_master = Control.new()
	ter_master.custom_minimum_size.y = 10
	vbox_container.add_child(ter_master)
	
	# === ZENE HANGERŐ ===
	var music_volume_label = Label.new()
	music_volume_label.text = "Zene hangerő"
	music_volume_label.add_theme_font_size_override("font_size", 18)
	vbox_container.add_child(music_volume_label)
	
	music_slider = HSlider.new()
	music_slider.min_value = 0
	music_slider.max_value = 100
	music_slider.value = jelenlegi_hangerő("Music")
	music_slider.connect("value_changed", music_hang_valtozas)
	vbox_container.add_child(music_slider)
	
	music_label = Label.new()
	music_label.text = str(int(music_slider.value)) + "%"
	music_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	music_label.add_theme_font_size_override("font_size", 14)
	vbox_container.add_child(music_label)
	
	# Üres tér
	var ter_music = Control.new()
	ter_music.custom_minimum_size.y = 10
	vbox_container.add_child(ter_music)
	
	# === SFX HANGERŐ ===
	var sfx_volume_label = Label.new()
	sfx_volume_label.text = "Hanghatások (SFX)"
	sfx_volume_label.add_theme_font_size_override("font_size", 18)
	vbox_container.add_child(sfx_volume_label)
	
	sfx_slider = HSlider.new()
	sfx_slider.min_value = 0
	sfx_slider.max_value = 100
	sfx_slider.value = jelenlegi_hangerő("SFX")
	sfx_slider.connect("value_changed", sfx_hang_valtozas)
	vbox_container.add_child(sfx_slider)
	
	sfx_label = Label.new()
	sfx_label.text = str(int(sfx_slider.value)) + "%"
	sfx_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sfx_label.add_theme_font_size_override("font_size", 14)
	vbox_container.add_child(sfx_label)
	
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

# A jelenlegi hangerőt lekéri bármelyik bus-ra
func jelenlegi_hangerő(bus_name: String):
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return 80.0  # Alapértelmezett ha nem létezik a bus
	var jelenlegi_db = AudioServer.get_bus_volume_db(bus_index)
	var hang_szazalek = db_to_linear(jelenlegi_db) * 100
	return hang_szazalek

# Hangerő beállítása bármelyik bus-ra
func hang_beallitas(bus_name: String, volume_percent: float):
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index != -1:
		var hang_db = linear_to_db(volume_percent / 100.0)
		AudioServer.set_bus_volume_db(bus_index, hang_db)

# === SIGNAL HANDLERS ===
func master_hang_valtozas(value: float):
	if master_label:
		master_label.text = str(int(value)) + "%"
	hang_beallitas("Master", value)

func music_hang_valtozas(value: float):
	if music_label:
		music_label.text = str(int(value)) + "%"
	hang_beallitas("Music", value)

func sfx_hang_valtozas(value: float):
	if sfx_label:
		sfx_label.text = str(int(value)) + "%"
	hang_beallitas("SFX", value)

func open():
	visible = true

func close():
	visible = false
	queue_free()

func _on_back_pressed():
	close()

func _input(event):
	if event.is_action_pressed("ui_cancel") and visible:
		get_viewport().set_input_as_handled()
		close()
