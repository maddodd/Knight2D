extends Resource
class_name GameManagerResource

const save_path := "user://save.json"
const abilities := {
	"dash": {"name": "Dodge Roll", "desc": "Dash forward with [SHIFT] to dodge attacks and travel over gaps!", "anim": "roll"},
	"shield": {"name": "Shield Block", "desc": "Hold [E] to block incoming damage!", "anim": "shield"},
	"sword": {"name": "Sword Slash", "desc": "Swing your sword with [Q] to defeat enemies!", "anim": "sword"}
}

@export var unlocked_abilities = {
	"dash": false, "shield": false, "sword": false
}
@export var current_level: int = 0

signal ability_unlocked(ability: String)
signal level_completed(level: int)

func _init():
	load_game()

func save_game():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(to_dict()))
	file.close()

func load_game():
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		var data = JSON.parse_string(file.get_as_text())
		file.close()
		unlocked_abilities = data.get("unlocked_abilities", unlocked_abilities)
		current_level = data.get("current_level", 1)

func to_dict() -> Dictionary:
	return {
		"unlocked_abilities": unlocked_abilities,
		"current_level": current_level
	}

func unlock_ability(ability: String):
	if abilities.has(ability) and not unlocked_abilities[ability]:
		unlocked_abilities[ability] = true
		ability_unlocked.emit(ability)
		save_game()

func get_next_level() -> String:
	return "res://scenes/map_" + str(current_level) + ".tscn"

func complete_level():
	current_level += 1
	save_game()
	level_completed.emit(current_level - 1)
