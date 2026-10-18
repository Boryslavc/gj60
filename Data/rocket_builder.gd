extends Node2D

"""Build the rocket based on score (out of 5)"""
"""Call should set score and rocket_pieces.
Length of rocket pieces should equal score
we need some sort of shared score manager between rocket builder and rocket animation scenes"""

var rocket_pieces: Array[int] = []
var score:int = 1 # out of 5

@onready var fire_animation_3: AnimatedSprite2D = $FireAnimation3
@onready var fire_animation_2: AnimatedSprite2D = $FireAnimation2
@onready var fire_animation_1: AnimatedSprite2D = $FireAnimation1
@onready var trash_piece_2: TextureRect = $TrashPiece2
@onready var trash_piece_5: TextureRect = $TrashPiece5
@onready var rocket_piece_1: TextureRect = $RocketPiece1
@onready var rocket_piece_5: TextureRect = $RocketPiece5
@onready var rocket_piece_2: TextureRect = $RocketPiece2
@onready var rocket_piece_3: TextureRect = $RocketPiece3
@onready var rocket_piece_4: TextureRect = $RocketPiece4
@onready var trash_piece_4: TextureRect = $TrashPiece4
@onready var trash_piece_3: TextureRect = $TrashPiece3
@onready var cpu_particles_2d_2: CPUParticles2D = $CPUParticles2D2
@onready var cpu_particles_2d_3: CPUParticles2D = $CPUParticles2D3
@onready var cpu_particles_2d_1: CPUParticles2D = $CPUParticles2D1


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print(LevelFlow.score, "level score")
	score = LevelFlow.score
	rocket_pieces.clear()
	for piece_number in range(1, score + 1):
		rocket_pieces.append(piece_number)

	rocket_piece_1.visible = 1 in rocket_pieces
	
	rocket_piece_2.visible = 2 in rocket_pieces
	trash_piece_2.visible = not (2 in rocket_pieces)
	
	rocket_piece_3.visible = 3 in rocket_pieces
	trash_piece_3.visible = not (3 in rocket_pieces)
	
	rocket_piece_4.visible = 4 in rocket_pieces
	trash_piece_4.visible = not (4 in rocket_pieces)
	
	rocket_piece_5.visible = 5 in rocket_pieces
	trash_piece_5.visible = not (5 in rocket_pieces)

	# if 5 score, display 3 flames, no smoke
	# if 4 score, display 3 flames, but also smoke on the sides
	# if 2-3 score display 0 flames, smoke
	 # if 0-1 score display 1 smoke in center 
	fire_animation_1.visible = score >=4
	fire_animation_2.visible = score >=4
	fire_animation_3.visible = score >=4
	
	cpu_particles_2d_2.visible = (score <= 3)
	cpu_particles_2d_1.visible = (score <= 4)
	cpu_particles_2d_3.visible = (score <= 4)
