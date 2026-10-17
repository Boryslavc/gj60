extends TileMapLayer
## Turns switches on click.

const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

## Switch cell
var _switch_exits: Dictionary[Vector2i, Array] = {}
## Direction
var _arrow_tiles: Dictionary[Vector2i, Array] = {}


func _ready() -> void:
	_collect_arrow_tiles()
	_detect_switches()


func _unhandled_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return

	var cell := local_to_map(get_local_mouse_position())
	if not _switch_exits.has(cell) or _is_disturbed(cell):
		return

	_turn_switch(cell)
	get_viewport().set_input_as_handled()


## Reads atlas tile
func _collect_arrow_tiles() -> void:
	for source_index in tile_set.get_source_count():
		var source_id := tile_set.get_source_id(source_index)
		var source := tile_set.get_source(source_id) as TileSetAtlasSource
		if source == null:
			continue

		for tile_index in source.get_tiles_count():
			var atlas_coords := source.get_tile_id(tile_index)
			var data := source.get_tile_data(atlas_coords, 0)
			# The disturbed arrows also have is_switch, but only the normal ones are used here.
			if data.get_custom_data("is_switch") and not data.get_custom_data("disturbed"):
				_arrow_tiles[data.get_custom_data("direction")] = [source_id, atlas_coords]


## Finds each switch's exits: neighbors with a direction that does not point back into the switch (that one is the entry).
func _detect_switches() -> void:
	for cell in get_used_cells():
		if not _is_switch(cell):
			continue

		var exits: Array[Vector2i] = []
		for direction in DIRECTIONS:
			var neighbor_direction := _get_direction(cell + direction)
			if neighbor_direction != Vector2i.ZERO and neighbor_direction != -direction:
				exits.append(direction)
		_switch_exits[cell] = exits


## Turns the switch to its next exit, clockwise.
func _turn_switch(cell: Vector2i) -> void:
	var exits: Array = _switch_exits[cell]
	if exits.is_empty():
		return

	# find() returns -1 if the arrow points to a side without a belt, so the first click then jumps to the first valid exit.
	var index := exits.find(_get_direction(cell))
	var next_direction: Vector2i = exits[(index + 1) % exits.size()]
	var tile: Array = _arrow_tiles[next_direction]
	set_cell(cell, tile[0], tile[1])


func _get_direction(cell: Vector2i) -> Vector2i:
	var data := get_cell_tile_data(cell)
	if data == null:
		return Vector2i.ZERO
	return data.get_custom_data("direction")


func _is_switch(cell: Vector2i) -> bool:
	var data := get_cell_tile_data(cell)
	return data != null and data.get_custom_data("is_switch")


func _is_disturbed(cell: Vector2i) -> bool:
	var data := get_cell_tile_data(cell)
	return data != null and data.get_custom_data("disturbed")