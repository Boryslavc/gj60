extends Node2D
## Moves along the conveyor belt from tile center to tile center. Reads the tile direction.

@export var conveyor_map: TileMapLayer
#64.0 Pixel per second. (one tile per second)
@export var speed: float = 32.0 

var _cell: Vector2i
var _direction := Vector2i.ZERO
var _target: Vector2


func _ready() -> void:
	_cell = conveyor_map.local_to_map(conveyor_map.to_local(global_position))
	global_position = _cell_center(_cell)
	_read_direction()

func _physics_process(delta: float) -> void:
	if _direction == Vector2i.ZERO:
		return # ens of belt

	global_position = global_position.move_toward(_target, speed * delta)
	if global_position == _target:
		_cell += _direction
		_read_direction()

func _read_direction() -> void:
	var data := conveyor_map.get_cell_tile_data(_cell)
	if data == null:
		_direction = Vector2i.ZERO
	else:
		_direction = data.get_custom_data("direction")
	_target = _cell_center(_cell + _direction)

func _cell_center(cell: Vector2i) -> Vector2:
	return conveyor_map.to_global(conveyor_map.map_to_local(cell))
