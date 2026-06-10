extends Node


var money: int = 0
var board: Board


func _ready() -> void:
	add_child(board)
	board.game = self
