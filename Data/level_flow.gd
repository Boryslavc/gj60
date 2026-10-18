extends Node

## Order of the levels. New levels are appended here.
const LEVELS: Array[String] = [
	"res://Scenes/Playable Scenes/level1.tscn",
	"res://Scenes/Playable Scenes/level2.tscn",
	"res://Scenes/Playable Scenes/level3.tscn",
	"res://Scenes/Playable Scenes/level4.tscn",
]
const MAIN_MENU := "res://Scenes/Playable Scenes/MainMenu.tscn"
## Loaded after the last level.
const CREDITS := "res://Scenes/Playable Scenes/Credits.tscn"

signal level_started(index: int)

var current_index := -1


func start_game() -> void:
	_load_level(0)


func next_level() -> void:
	if current_index + 1 < LEVELS.size():
		_load_level(current_index + 1)
	else:
		to_credits()


func restart_level() -> void:
	_load_level(current_index)


func to_main_menu() -> void:
	current_index = -1
	get_tree().change_scene_to_file(MAIN_MENU)


func _load_level(index: int) -> void:
	if index < 0 or index >= LEVELS.size():
		return
	current_index = index
	get_tree().change_scene_to_file(LEVELS[index])
	level_started.emit(index)

func to_credits() -> void:
	current_index = -1
	get_tree().change_scene_to_file(CREDITS)