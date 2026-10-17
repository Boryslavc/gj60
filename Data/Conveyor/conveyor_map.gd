extends TileMapLayer
## Conveyor map: the player selects a switch with the number keys and turns it with the arrow keys.
## The active switch makes the belt it points at run away from it.
## Switch nodes (switch.tscn) are children of this layer and sit on switch tiles.

const KEY_COUNT := 10
const TURN_ACTIONS := {
	"switch_up": Vector2i.UP,
	"switch_right": Vector2i.RIGHT,
	"switch_down": Vector2i.DOWN,
	"switch_left": Vector2i.LEFT,
}

## How long a switch shows the blink tile after a forbidden direction.
@export var blink_duration: float = 0.15

## Switch tiles per direction: direction -> [source_id, atlas_coords]
var _normal_tiles: Dictionary[Vector2i, Array] = {}
var _active_tiles: Dictionary[Vector2i, Array] = {}
var _blink_tiles: Dictionary[Vector2i, Array] = {}
## Belt tiles per opening: [entry, direction] -> [source_id, atlas_coords]
var _belt_tiles: Dictionary[Array, Array] = {}
## Number key -> switch node
var _switches: Dictionary[int, Switch] = {}
## Key of the selected switch, 0 = none
var _selected_key := 0


func _ready() -> void:
	_collect_tiles()
	_collect_switches()


func _unhandled_input(event: InputEvent) -> void:
	for key in range(1, KEY_COUNT + 1):
		if event.is_action_pressed("switch_%d" % key):
			_select(key)
			get_viewport().set_input_as_handled()
			return

	for action in TURN_ACTIONS:
		if event.is_action_pressed(action):
			_turn(TURN_ACTIONS[action])
			get_viewport().set_input_as_handled()
			return


## Reads the TileSet once: switch tiles by direction, belt tiles by entry and direction.
func _collect_tiles() -> void:
	for source_index in tile_set.get_source_count():
		var source_id := tile_set.get_source_id(source_index)
		var source := tile_set.get_source(source_id) as TileSetAtlasSource
		if source == null:
			continue

		for tile_index in source.get_tiles_count():
			var atlas_coords := source.get_tile_id(tile_index)
			var data := source.get_tile_data(atlas_coords, 0)
			var tile := [source_id, atlas_coords]
			var direction: Vector2i = data.get_custom_data("direction")
			var entry: Vector2i = data.get_custom_data("entry")

			if entry != Vector2i.ZERO:
				_belt_tiles[[entry, direction]] = tile
			elif not data.get_custom_data("is_switch"):
				continue # neither belt nor switch
			# Blink first: the blink tiles also have "active" set.
			elif data.get_custom_data("blink"):
				_blink_tiles[direction] = tile
			elif data.get_custom_data("active"):
				_active_tiles[direction] = tile
			else:
				_normal_tiles[direction] = tile


## Finds the switch nodes among the children and checks that each sits on a switch tile with its own key.
func _collect_switches() -> void:
	for child in get_children():
		var switch := child as Switch
		if switch == null:
			continue

		if not _is_switch(_cell_of(switch)):
			push_error("%s does not sit on a switch tile (cell %s)." % [switch.name, _cell_of(switch)])
		elif _switches.has(switch.key):
			push_error("Key %d is used by %s and %s." % [switch.key, _switches[switch.key].name, switch.name])
		else:
			_switches[switch.key] = switch


## Makes the switch with this key the active one. The previous one goes back to normal.
func _select(key: int) -> void:
	if not _switches.has(key):
		return # no switch with this number in the level

	if _switches.has(_selected_key):
		var previous := _switches[_selected_key]
		_place_tile(previous, _normal_tiles, _get_direction(_cell_of(previous)))
	_selected_key = key
	var switch := _switches[key]
	_place_tile(switch, _active_tiles, _get_direction(_cell_of(switch)))


## Points the active switch in the given direction and makes the belt there run away from it.
## Blinks instead if the direction is forbidden or another switch holds that belt.
func _turn(direction: Vector2i) -> void:
	if not _switches.has(_selected_key):
		return # no switch selected

	var switch := _switches[_selected_key]
	var belt := _belt_towards(_cell_of(switch), direction)
	if switch.is_forbidden(direction) or _is_held(belt):
		_blink(switch)
		return

	_place_tile(switch, _active_tiles, direction)
	_reverse(belt)


## Cells of the belt that leaves the switch in this direction, as long as they run towards the switch.
## Empty if there is no belt there or it already runs away from the switch.
func _belt_towards(switch_cell: Vector2i, direction: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var cell := switch_cell + direction
	var step := direction # from the previous cell to this one
	while _is_belt(cell) and _get_direction(cell) == -step:
		cells.append(cell)
		step = _get_entry(cell)
		cell += step
	return cells

## True if the switch at the far end of the belt points into it, so the belt is taken.
func _is_held(belt: Array[Vector2i]) -> bool:
	if belt.is_empty():
		return false

	var last: Vector2i = belt.back()
	var end := last + _get_entry(last) # the old entry of the last tile leads to the far end
	return _is_switch(end) and end + _get_direction(end) == last


## Turns every belt tile around: the old exit becomes the entry, the old entry becomes the exit.
func _reverse(belt: Array[Vector2i]) -> void:
	for cell in belt:
		var tile: Array = _belt_tiles[[_get_direction(cell), _get_entry(cell)]]
		set_cell(cell, tile[0], tile[1])

## Shows the blink tile for a moment, then the active tile again.
func _blink(switch: Switch) -> void:
	var cell := _cell_of(switch)
	var direction := _get_direction(cell)
	_place_tile(switch, _blink_tiles, direction)
	await get_tree().create_timer(blink_duration).timeout

	# Meanwhile the player may have turned this switch or selected another one; then leave the tile alone.
	if _is_blink(cell):
		_place_tile(switch, _active_tiles, direction)


## Puts the arrow of this direction from the given tile table on the switch.
func _place_tile(switch: Switch, tiles: Dictionary, direction: Vector2i) -> void:
	var tile: Array = tiles[direction]
	set_cell(_cell_of(switch), tile[0], tile[1])


func _cell_of(switch: Switch) -> Vector2i:
	return local_to_map(switch.position)


func _get_direction(cell: Vector2i) -> Vector2i:
	var data := get_cell_tile_data(cell)
	if data == null:
		return Vector2i.ZERO
	return data.get_custom_data("direction")


func _is_switch(cell: Vector2i) -> bool:
	var data := get_cell_tile_data(cell)
	return data != null and data.get_custom_data("is_switch")


func _is_belt(cell: Vector2i) -> bool:
	var data := get_cell_tile_data(cell)
	return data != null and data.get_custom_data("entry") != Vector2i.ZERO


func _is_blink(cell: Vector2i) -> bool:
	var data := get_cell_tile_data(cell)
	return data != null and data.get_custom_data("blink")

func _get_entry(cell: Vector2i) -> Vector2i:
	var data := get_cell_tile_data(cell)
	if data == null:
		return Vector2i.ZERO
	return data.get_custom_data("entry")