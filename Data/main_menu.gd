extends Control


func _on_start_button_pressed() -> void:
	LevelFlow.start_game()


func _on_credits_button_pressed() -> void:
	LevelFlow.to_credits()
