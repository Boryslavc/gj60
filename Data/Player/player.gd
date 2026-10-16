extends CharacterBody2D

@export_group("Stats")
@export var max_speed : float = 400.0
@export var rot_speed : float = 2.5
@export_subgroup("Rotation")
@export var rotation_speed : float = 2.5
@export_subgroup("Damping")
@export var is_damping : bool = false
@export var damp_speed : float = 2.5
@export_subgroup("Throttle")
@export var throttle_accel : float = 60.0
@export var throttle_decel : float = 40.0
@export var throttle : float = 0.0
var target_throttle : float = 0.0
@export_subgroup("Fuel")
@export var fuel_max : float = 100.0
@export var current_fuel : float = 100.0
@export var fuel_depletion_rate : float = 1.0

func _ready() -> void:
	throttle = 0.0
	_set_labels()
	_set_stats()

func _physics_process(delta: float) -> void:
	_handle_forces(delta)
	_handle_movement(delta)
	move_and_slide()

func _handle_forces(delta) -> void:
	var rotation_dir = Input.get_axis("left", "right")
	rotation += rotation_dir * rotation_speed * delta

	# Held inputs to ease movement
	if Input.is_action_pressed("forward"):
		target_throttle = 100.0
	elif Input.is_action_pressed("backward"):
		target_throttle = 0.0

	# NEARLY instant presets
	if Input.is_action_just_pressed("full_throttle"):
		target_throttle = 100.0
	elif Input.is_action_just_pressed("cut_throttle"):
		target_throttle = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if current_fuel == 0.0:
		SignalBus.emit_signal("fuel_depleted")

func _handle_movement(delta : float) -> void:
	# TODO add refueling
	if current_fuel <= 0.0:
		target_throttle = 0.0

	var rate := throttle_accel if target_throttle > throttle else throttle_decel
	throttle = move_toward(throttle, target_throttle, rate * delta)

	# Burn proportional fuel
	#if throttle > 0.0:


	# Apply velocity to ship facing direction
	var forward := Vector2.UP.rotated(rotation) # Assuming the sprite faces up
	velocity = forward * max_speed * (throttle / 100.0)

func _set_labels() -> void:
	pass

func _set_stats() -> void:
	current_fuel = fuel_max
	SignalBus.emit_signal("update_fuel", current_fuel)