extends Node2D

"""DISPLAY AN ANIMATION based on how the player did out of 5
the instantiating scene should set score"""
var score: int = 5 # out of 5

@onready var rocket_builder: Node2D = $RocketBuilder
@onready var center_star_1: TextureRect = $CenterStar1
@onready var left_star: TextureRect = $LeftStar
@onready var right_star: TextureRect = $RightStar
@onready var grand_star: TextureRect = $GrandStar
@onready var color_rect: ColorRect = $ColorRect
@onready var label: Label = $ColorRect/Label

var initial_rocket_position: Vector2
var initial_rocket_rotation: float

@export var rocket_tip_offset: float = 40.0 


func _ready() -> void:
	score = LevelFlow.score
	initial_rocket_position = rocket_builder.global_position
	initial_rocket_position = rocket_builder.global_position
	initial_rocket_rotation = rocket_builder.rotation
	
	color_rect.modulate.a = 0.0
	color_rect.visible = false
	
	start_launch(score)


func start_launch(current_score: int, go_left: bool = true) -> void:
	rocket_builder.global_position = initial_rocket_position
	rocket_builder.rotation = initial_rocket_rotation

	color_rect.modulate.a = 0.0
	color_rect.visible = false
	for star in [center_star_1, left_star, right_star, grand_star]:
		star.modulate.a = 1.0
		star.visible = true

	if current_score <= 1:
		launch_fail(current_score)
	elif current_score <= 3:
		launch_to_side(current_score, go_left)
	elif current_score == 4:
		launch_center(current_score)
	else:
		launch_perfect(current_score)


func launch_fail(final_score: int) -> void:
	var peak_pos = initial_rocket_position.lerp(center_star_1.global_position, 0.12)
	
	var tw = create_tween()
	tw.tween_property(rocket_builder, "global_position", peak_pos, 0.5).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(rocket_builder, "rotation", deg_to_rad(15), 0.5)
	
	tw.tween_property(rocket_builder, "global_position", initial_rocket_position, 0.7).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(rocket_builder, "rotation", 0.0, 0.7)
	
	tw.tween_callback(func(): display_label(final_score))


func launch_to_side(final_score: int, go_left: bool) -> void:
	var target_star = left_star if go_left else right_star
	var adjusted_target_pos = target_star.global_position + Vector2(0, rocket_tip_offset)
	var mid_pos = initial_rocket_position.lerp(adjusted_target_pos, 0.45)
	var tilt_angle = deg_to_rad(-43) if go_left else deg_to_rad(43)
	
	var tw = create_tween()
	tw.tween_property(rocket_builder, "global_position", mid_pos, 1.1).set_ease(Tween.EASE_OUT)
	# rotate to tilt angle
	tw.parallel().tween_property(rocket_builder, "rotation", tilt_angle, 0.5)
	
	tw.tween_property(rocket_builder, "global_position", adjusted_target_pos, 0.6).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(rocket_builder, "rotation", tilt_angle * 0.5, 0.4)
	tw.parallel().tween_property(target_star, "modulate:a", 0.0, 0.2).set_delay(0.4)
	
	tw.tween_callback(func(): display_label(final_score))


func launch_center(final_score: int) -> void:
	# hit jut the center star when you get four out of 5
	var target_pos = Vector2(initial_rocket_position.x, center_star_1.global_position.y + rocket_tip_offset)
	
	var tw = create_tween()
	# stright rotation
	tw.tween_property(rocket_builder, "rotation", 0.0, 0.2)
	tw.parallel().tween_property(rocket_builder, "global_position", target_pos, 0.8)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# fade starts also fade the side stars
	tw.parallel().tween_property(center_star_1, "modulate:a", 0.0, 0.2).set_delay(0.6)
	tw.parallel().tween_property(left_star, "modulate:a", 0.0, 0.2).set_delay(0.8)
	tw.parallel().tween_property(right_star, "modulate:a", 0.0, 0.2).set_delay(0.8)
	
	tw.tween_callback(func(): display_label(final_score))


func launch_perfect(final_score: int) -> void:
	# got stright up hitting center target then grand star
	var center_target = Vector2(initial_rocket_position.x, center_star_1.global_position.y + rocket_tip_offset)
	var grand_target = Vector2(initial_rocket_position.x, grand_star.global_position.y + rocket_tip_offset)
	
	var tw = create_tween()
	# stright rotation
	tw.tween_property(rocket_builder, "rotation", 0.0, 0.2)
	tw.parallel().tween_property(rocket_builder, "global_position", center_target, 0.6)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(center_star_1, "modulate:a", 0.0, 0.2).set_delay(0.4)
	
	tw.tween_property(rocket_builder, "global_position", grand_target, 0.5)\
		.set_trans(Tween.TRANS_LINEAR)
	# fade the stars
	tw.parallel().tween_property(grand_star, "modulate:a", 0.0, 0.2).set_delay(0.3)
	tw.parallel().tween_property(left_star, "modulate:a", 0.0, 0.2).set_delay(0.8)
	tw.parallel().tween_property(right_star, "modulate:a", 0.0, 0.2).set_delay(0.8)
	# fly out the top of screen 
	var off_screen = Vector2(initial_rocket_position.x, grand_star.global_position.y - 1200)
	tw.tween_property(rocket_builder, "global_position", off_screen, 1.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	tw.tween_callback(func(): display_label(final_score))


func display_label(final_score: int) -> void:
	color_rect.visible = true
	label.text = "Score: %d/5" % final_score

	var tw = create_tween()
	tw.tween_property(color_rect, "modulate:a", 1.0, 0.4)
	tw.tween_interval(2.0)
	tw.tween_callback(LevelFlow.next_level)
