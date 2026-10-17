class_name Switch
extends Node2D
## Data for one switch. Place it on a switch tile in the level.
## Holds no logic; the conveyor map reads it at start.

## Clockwise, same order as the flags below.
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

## Number key that selects this switch (10 = key 0).
@export_range(1, 10) var key: int = 1
## Directions the player may never set, usually the side the input belt comes from.
@export_flags("Up", "Right", "Down", "Left") var forbidden_directions: int = 0


func is_forbidden(direction: Vector2i) -> bool:
	var index := DIRECTIONS.find(direction)
	if index == -1:
		return true # not one of the four directions
	return (forbidden_directions & (1 << index)) != 0