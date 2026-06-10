extends Control


signal start_game(board)


func _on_start_pressed(button = 0) -> void:
	start_game.emit(button)
