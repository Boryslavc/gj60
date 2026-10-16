extends ProgressBar

func _ready() -> void:
	SignalBus.connect("update_fuel", update_value)

func update_value(new_value : float) -> void:
	self.value = new_value