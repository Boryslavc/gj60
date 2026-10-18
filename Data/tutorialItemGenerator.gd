extends Node2D

@export var output_ports: Array[Node2D] = []
@export var trash_port_count: int
@export var metal_port_count: int
@export var spawn_interval = 2

@export var item: PackedScene
@export var conveyor_map: ConveyorMap

@export var trash_sprite: Texture2D
@export var metal_sprite: Texture2D

var timers: Array[Timer] = []

var trash_ports_free
var metal_ports_free

var rng := RandomNumberGenerator.new()
@onready var hint_label: Label = $"../ColorRect/HintLabel"
@onready var pause_here_color_rect: ColorRect = $"../PauseHereColorRect"
@onready var reached_trash_color_rect: ColorRect = $"../ReachedTrashColorRect"

var pause_rect: Rect2
var pause_trash: Rect2

# tutorial state
var pressed_one = false
var s_is_last_pressed = false
var w_is_last_pressed = false
var active_items: Array[Node2D] = []
var reached_trash = false
var spawned_second_item = false
var asked_for_switch_2 = false

## Waits after the rocket part arrived before pointing out the second switch.
var _switch_hint_timer := Timer.new()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.is_action_pressed("switch_1") and not spawned_second_item:
			pressed_one = true
			hint_label.text = "Press [S] or [Down] to point down."
		elif event.is_action_pressed("switch_down") and pressed_one:
			s_is_last_pressed = true
			w_is_last_pressed = false
			print("s last true")
		elif event.is_action_pressed("switch_up") and spawned_second_item:
			w_is_last_pressed = true
			s_is_last_pressed = false
			print("w last true")
		elif event.is_action_pressed("switch_2") and asked_for_switch_2:
			hint_label.text = "That's how you play the game.\nPress [Enter] to begin."
		else:
			s_is_last_pressed = false
			w_is_last_pressed = false

func _ready() -> void:	
	trash_ports_free = trash_port_count
	metal_ports_free = metal_port_count
	_spawn_trash_part()
	pause_rect = pause_here_color_rect.get_global_rect()
	pause_trash = reached_trash_color_rect.get_global_rect()
	_switch_hint_timer.one_shot = true
	_switch_hint_timer.wait_time = 2.0
	_switch_hint_timer.timeout.connect(_ask_for_switch_2)
	add_child(_switch_hint_timer)
	
func _process(delta: float) -> void:
	for item_node in active_items:
		if not is_instance_valid(item_node):
			continue
		# first item pause
		if (pause_rect.has_point(item_node.global_position)
			and not (pressed_one and s_is_last_pressed)
			and not spawned_second_item):
			print("pausing")
			item_node.speed=0
		elif (spawned_second_item
			and not w_is_last_pressed
			and pause_rect.has_point(item_node.global_position)):
			print("pausing second item")
			item_node.speed=0
		else:
			item_node.speed = 75
		if not spawned_second_item and pause_trash.has_point(item_node.global_position):
			reached_trash = true
			active_items.erase(active_items[0])
			hint_label.text = "Next item is a rocket part.\nPress [W] or [Up] to point up.\nThis switch can't point left or right."
			_spawn_metal_part()
			spawned_second_item = true

func _on_timer_timeout() -> void:
	var can_spawn_trash = trash_ports_free > 0
	var can_spawn_metal = metal_ports_free > 0

	if not can_spawn_trash and not can_spawn_metal:
		return

	if can_spawn_trash and can_spawn_metal:
		if rng.randi_range(0, 1) == 0:
			_spawn_trash_part()
		else:
			_spawn_metal_part()
	elif can_spawn_trash:
		_spawn_trash_part()
	else:
		_spawn_metal_part()
	
func _spawn_metal_part():
	var output_port_number = _pick_random_output_port()
	var metal_part = item.instantiate()
	metal_part.type = Item.Type.METAL
	var texture_m = metal_part.get_child(0) as Sprite2D
	texture_m.texture = metal_sprite
	
	var port = output_ports[output_port_number]
	metal_part.conveyor_map = conveyor_map
	metal_part.position = to_local(port.global_position)
	metal_part.speed = 75
	add_child(metal_part)
	active_items.append(metal_part)
	
func _spawn_trash_part():
	var output_port_number = _pick_random_output_port()
	var trash_past = item.instantiate()
	trash_past.type = Item.Type.TRASH
	var texture_t = trash_past.get_child(0) as Sprite2D
	texture_t.texture = trash_sprite
	
	var port = output_ports[output_port_number]
	trash_past.conveyor_map = conveyor_map
	trash_past.position = to_local(port.global_position)
	add_child(trash_past)
	trash_past.speed = 75
	active_items.append(trash_past)
	
func _pick_random_output_port():
	return rng.randi_range(0, output_ports.size() - 1)
	
func _on_port_fed(port_type,timeout):
	if port_type == "trash":
		trash_ports_free -= 1
	if port_type == "metal":
		metal_ports_free -= 1
		if spawned_second_item:
			_switch_hint_timer.start()

	for timer in timers:
		if timer.is_stopped():
			timer.wait_time = timeout
			timer.timeout.connect(_on_port_freed_up.bind(port_type), CONNECT_ONE_SHOT)
			timer.start()
			break
			
	
	
func _ask_for_switch_2() -> void:
	asked_for_switch_2 = true
	hint_label.text = "You can also select other switches.\nPress [2]."


func _on_port_freed_up(port_type):
	if port_type == "metal":
		metal_ports_free += 1
	if port_type == "trash":
		trash_ports_free += 1
