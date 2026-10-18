extends Node2D

@export var building_parts_required: int = 10

var part_count: int = 0

func _ready() -> void:
	find_item_nodes(get_tree().current_scene)
	$CanvasLayer/MarginContainer/Label.text = "0/"+ str(building_parts_required)

func find_item_nodes(node: Node) -> void:
	if node.get_script() == preload("res://Data/Conveyor/receiving_port.gd"):
		if node.has_signal("part_fed") && node.name.begins_with("Input"):
			node.part_fed.connect(_on_building_part_fed)
			print(node.name)

	# Search all children recursively
	for child in node.get_children():
		find_item_nodes(child)
			
		
func _on_building_part_fed(name, dur):
	part_count += 1
	$CanvasLayer/MarginContainer/Label.text =  str(part_count)+"/"+str(building_parts_required)
	if part_count >= building_parts_required:
		pass
		
