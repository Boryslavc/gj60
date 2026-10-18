extends Node2D

@export var building_parts_required: int = 10

var part_count: int = 0 # all parts
var rocket_part_count: int = 0 # METAL ROCKET parts

func _ready() -> void:
	find_item_nodes(get_tree().current_scene)
	$CanvasLayer/MarginContainer/Label.text = "0/"+ str(building_parts_required)

func find_item_nodes(node: Node) -> void:
	if node.get_script() == preload("res://Data/Conveyor/receiving_port.gd"):
		if node.has_signal("item_fed"):
			node.item_fed.connect(_on_building_part_fed)

	# Search all children recursively
	for child in node.get_children():
		find_item_nodes(child)
			
		
func _on_building_part_fed(item_type: int) -> void:
	print("A part entered an exit. Item type: ", Item.Type.keys()[item_type])
	part_count += 1
	if item_type == Item.Type.METAL:
		rocket_part_count += 1

	$CanvasLayer/MarginContainer/Label.text =  str(part_count)+"/"+str(building_parts_required)
	if part_count >= building_parts_required:
		LevelFlow.complete_level(calculate_score())


func calculate_score() -> int:
	var base_score:int = rocket_part_count
	if building_parts_required > 5:
		return round(base_score/2.0)
	return base_score
		
