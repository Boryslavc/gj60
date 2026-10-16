extends Camera2D

@export var follow_target : Node2D
@export var follow_speed : float = 5.0
@export var max_history : int = 2
@export var padding : Vector2 = Vector2.ZERO

var _holding_position : bool = false
var _hold_position : Vector2 = Vector2.ZERO
var _history : Array[Node2D] = []

func _ready() -> void:
	if follow_target:
		global_position = follow_target.global_position

func _physics_process(delta: float) -> void:
	var goal := _get_goal()
	# Smooth movement
	global_position = global_position.lerp(goal, 1.0 - exp(-follow_speed * delta))

func _get_goal() -> Vector2:
	if _holding_position:
		return _hold_position
	if is_instance_valid(follow_target):
		return follow_target.global_position + padding
	return global_position

func set_target(new_target : Node2D) -> void:
	_push_current_focus()
	follow_target = new_target
	_holding_position = false

func go_to_position(pos : Vector2) -> void:
	_push_current_focus()
	_hold_position = pos
	_holding_position = true

func go_to_previous() -> void:
	while not _history.is_empty():
		var previous = _history.pop_back()

		if previous is Vector2:
			_hold_position = previous
			_holding_position = true
			return
		
		if is_instance_valid(previous):
			follow_target = previous
			_holding_position = false
			return

func _push_current_focus() -> void:
	if _holding_position:
		_history.append(_hold_position)
	elif is_instance_valid(follow_target):
		_history.append(follow_target)
	
	if _history.size() > max_history:
		_history.pop_front()