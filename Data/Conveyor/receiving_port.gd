class_name ReceivingPort
extends Node2D
## Takes in items at the end of a belt, then stays blocked for a while.
## Place it as a child of the conveyor map, on the empty cell right after the last belt tile.

## Sent when an item was taken in. Connect it to the item generator.
signal part_fed(port_type: String, block_time: float)
## this incrementer goes when trash or metal is fed
signal item_fed(item_type: int)

## Sent to the generator with part_fed.
@export_enum("metal", "trash") var port_type: String = "metal"
## Seconds the port stays blocked after taking in this kind of item.
@export var metal_block_time: float = 2.0
@export var trash_block_time: float = 4.0

## Shows its first frame while the port is free and its second frame while it is blocked.
@export var sprite: AnimatedSprite2D

@onready var _map := get_parent() as ConveyorMap

var _cell: Vector2i
var _blocked := false
var _block_timer := Timer.new()

func _ready() -> void:
	if _map == null:
		set_physics_process(false)
		return
	_cell = _map.local_to_map(position)
	_block_timer.one_shot = true
	_block_timer.timeout.connect(_unblock)
	add_child(_block_timer)

func _physics_process(_delta: float) -> void:
	if _blocked:
		return
	var item := _map.get_holder(_cell) as Item
	if item != null and not item.is_moving():
		_take_in(item)


## Removes the item, reports it and blocks the cell for the matching time.
func _take_in(item: Item) -> void:
	var item_type := item.type
	var block_time := metal_block_time if item.type == Item.Type.METAL else trash_block_time

	# Hand the cell over from the item to the port, so the items behind it queue up.
	_map.release(_cell, item)
	_map.try_reserve(_cell, self)
	item.queue_free()

	_blocked = true
	_show_blocked(true)
	_block_timer.start(block_time)
	# Last, because a listener may end the level and remove this port from the tree.
	part_fed.emit(port_type, block_time)
	item_fed.emit(item_type)

func _unblock() -> void:
	_blocked = false
	_show_blocked(false)
	_map.release(_cell, self)

func _show_blocked(blocked: bool) -> void:
	if sprite != null:
		sprite.frame = 1 if blocked else 0
