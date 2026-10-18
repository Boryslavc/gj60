class_name Item
extends Node2D
## Moves along the conveyor belt from tile center to tile center. Reads the tile direction.
## Before each step it reserves the next cell. If that cell is taken, it waits, so items queue up.

@export var conveyor_map: ConveyorMap
## Pixels per second (64 = one tile per second).
@export var speed: float = 32.0

enum Type { METAL, TRASH }

## What the item is. Set it before the item enters the scene; the ports read it.
@export var type: Type = Type.METAL

var _cell: Vector2i
var _direction := Vector2i.ZERO
var _target: Vector2
## True while driving towards the next cell. Then the item holds both _cell and the next cell.
var _moving := false


func _ready() -> void:
	_cell = conveyor_map.local_to_map(conveyor_map.to_local(global_position))
	global_position = _cell_center(_cell)
	conveyor_map.try_reserve(_cell, self)


func _exit_tree() -> void:
	if not is_instance_valid(conveyor_map):
		return # the whole level is being freed
	conveyor_map.release(_cell, self)
	if _moving:
		conveyor_map.release(_cell + _direction, self)


func _physics_process(delta: float) -> void:
	if not _moving:
		_try_start_step()
		return

	global_position = global_position.move_toward(_target, speed * delta)
	if global_position == _target:
		conveyor_map.release(_cell, self)
		_cell += _direction
		_moving = false
		_try_start_step() # go on in the same frame, so the item does not stutter


## Reads the direction of the current tile and starts towards the next cell if it is free.
func _try_start_step() -> void:
	_direction = _read_direction(_cell)
	if _direction == Vector2i.ZERO:
		return # end of belt
	if not conveyor_map.try_reserve(_cell + _direction, self):
		return # next cell is taken: wait here and ask again next frame

	_target = _cell_center(_cell + _direction)
	_moving = true

## True while driving to the next cell, false while standing at a tile center.
func is_moving() -> bool:
	return _moving


func _read_direction(cell: Vector2i) -> Vector2i:
	var data := conveyor_map.get_cell_tile_data(cell)
	if data == null:
		return Vector2i.ZERO
	return data.get_custom_data("direction")


func _cell_center(cell: Vector2i) -> Vector2:
	return conveyor_map.to_global(conveyor_map.map_to_local(cell))
