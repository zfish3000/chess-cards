extends Node


var game_scene
var start_menu


func _on_start_menu_start_game(board_type) -> void:
	game_scene = load("res://scenes/game.tscn")
	$StartMenu.queue_free()
	var game = game_scene.instantiate()
	
	var board
	if board_type == 0:
		board = load("res://scenes/objects/board.tscn")
	elif board_type == 1:
		board = load("res://scenes/objects/normal_board.tscn")
	elif board_type == 2:
		board = load("res://scenes/objects/testing_board.tscn")
	game.board = board.instantiate()
	
	add_child(game)
