extends Node2D

## Places on the rocket. The level ends when this many parts reached the rocket ports.
const ROCKET_SLOTS := 5

var rocket_part_count: int = 0 # metal parts in rocket ports
var trash_part_count: int = 0 # trash in rocket ports

@onready var _rocket_label: Label = %RocketCount
@onready var _trash_label: Label = %TrashCount

func _ready() -> void:
	find_item_nodes(get_tree().current_scene)
	_update_labels()

func find_item_nodes(node: Node) -> void:
	if node.get_script() == preload("res://Data/Conveyor/receiving_port.gd"):
		if node.has_signal("item_fed") and node.port_type == "metal":
			node.item_fed.connect(_on_building_part_fed)

	# Search all children recursively
	for child in node.get_children():
		find_item_nodes(child)


func _on_building_part_fed(item_type: int) -> void:
	if item_type == Item.Type.METAL:
		rocket_part_count += 1
	else:
		trash_part_count += 1

	_update_labels()
	if rocket_part_count + trash_part_count >= ROCKET_SLOTS:
		LevelFlow.complete_level(calculate_score())


func _update_labels() -> void:
	_rocket_label.text = str(rocket_part_count)
	_trash_label.text = str(trash_part_count)


func calculate_score() -> int:
	return rocket_part_count
