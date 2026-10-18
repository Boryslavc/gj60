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

func _ready() -> void:	
	trash_ports_free = trash_port_count
	metal_ports_free = metal_port_count
	
	var node = Node2D.new()
	node.name = "PortsTimers"
	add_child(node)
	
	for x in trash_port_count + metal_port_count:
		var timer = Timer.new()
		node.add_child(timer)
		timers.append(timer)
	
	var spawn_timer := Timer.new()
	spawn_timer.name = "SpawnTimer"
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_timer_timeout)
	spawn_timer.autostart = true
	spawn_timer.set_meta("spawn_timer", true)
	add_child(spawn_timer)


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
	add_child(metal_part)
	
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
	
func _pick_random_output_port():
	return rng.randi_range(0, output_ports.size() - 1)
	
func _on_port_fed(port_type,timeout):
	if port_type == "trash":
		trash_ports_free -= 1
	if port_type == "metal":
		metal_ports_free -= 1
	
	for timer in timers:
		if timer.is_stopped():
			timer.wait_time = timeout
			timer.timeout.connect(_on_port_freed_up.bind(port_type), CONNECT_ONE_SHOT)
			timer.start()
			break
			
	
	
func _on_port_freed_up(port_type):
	if port_type == "metal":
		metal_ports_free += 1
	if port_type == "trash":
		trash_ports_free += 1
