extends Node

# Score rendszer
var score = 0

@onready var score_label: Label = %ScoreLabel

func add_point():
	score += 1
	score_label.text = str(score) + " pontot szereztél."

# Map betöltő rendszer
var current_map: int = 0
var map_lista: Node2D
var current_map_instance: Node2D = null  # Az aktuálisan betöltött map instance

func _ready():
	# MapLista referenciája - a GameManager és MapLista testvérek, szóval a szülőn keresztül
	map_lista = get_parent().get_node("MapLista")
	
	# Első map betöltése
	load_map(0)

func _unhandled_input(event):
	# Gomb megnyomásra map váltás - csak számgombok és M gomb
	if event is InputEventKey and event.pressed and not event.echo:
		# M gomb = következő map
		if event.keycode == KEY_M:
			next_map()
			get_viewport().set_input_as_handled()
		# Szám gombokkal lehet közvetlenül map-ot választani
		elif event.keycode == KEY_1:
			load_map(0)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_2:
			load_map(1)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_3:
			load_map(2)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_4:
			load_map(3)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_5:
			load_map(4)
			get_viewport().set_input_as_handled()

func load_map(map_number: int):
	if not map_lista:
		print("HIBA: MapLista nincs inicializálva!")
		return
	
	# Töröljük az előző map-ot, ha van
	if current_map_instance:
		map_lista.remove_child(current_map_instance)
		current_map_instance.queue_free()
		current_map_instance = null
	
	# Betöltjük az új map-ot
	current_map = map_number
	var map_path = "res://scenes/map_" + str(map_number) + ".tscn"
	var map_scene = load(map_path)
	
	if map_scene:
		current_map_instance = map_scene.instantiate()
		current_map_instance.name = "Map" + str(map_number + 1)
		map_lista.add_child(current_map_instance)
		print("Map ", map_number, " betöltve: ", map_path)
	else:
		print("HIBA: Nem sikerült betölteni a map-ot: ", map_path)

func next_map():
	# Következő map betöltése
	current_map += 1
	load_map(current_map)
