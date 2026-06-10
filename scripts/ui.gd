extends CanvasLayer


@export var game: Node


func _process(_delta: float) -> void:
	$Money.text = "$" + str(game.money)
