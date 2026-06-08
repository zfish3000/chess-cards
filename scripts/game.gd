extends Node2D


enum Piece{
	BLANK,
	PAWN,
	KNIGHT,
	BISHOP,
	ROOK,
	KING,
	QUEEN,
	EMPRESS,
	PRINCESS,
}
var piece_atlas_coords: Dictionary = {
	Vector2i(-1, -1) : Piece.BLANK,
	Vector2i(0, 0) : Piece.PAWN,
	Vector2i(1, 0) : Piece.BISHOP,
	Vector2i(2, 0) : Piece.KNIGHT,
	Vector2i(3, 0) : Piece.ROOK,
	Vector2i(0, 1) : Piece.KING,
	Vector2i(1, 1) : Piece.QUEEN,
	Vector2i(2, 1) : Piece.EMPRESS,
	Vector2i(3, 1) : Piece.PRINCESS,
}
var local_mouse_pos
var clicked_tile
var source_id
var atlas_coords: Vector2i
var tile_type
var last_clicked_tile


func find_clicked_tile():
	local_mouse_pos = $Board/Pieces.get_local_mouse_position()
	clicked_tile = $Board/Pieces.local_to_map(local_mouse_pos)
	tile_info(clicked_tile)

func tile_info(tile):
	source_id = $Board/Pieces.get_cell_source_id(tile)
	atlas_coords = $Board/Pieces.get_cell_atlas_coords(tile)
	tile_type = piece_atlas_coords[atlas_coords]
	return tile_type


func _on_board_click_area_input_event(_viewport, event, _shape_idx):
	if event.is_action_released("click"):
		find_clicked_tile()
		if last_clicked_tile == null:
			if tile_type != Piece.BLANK:
				click_tile(clicked_tile)
		else:
			move_piece(last_clicked_tile, clicked_tile)
			last_clicked_tile = null
			$Board/Highlights.clear()


func click_tile(tile):
	last_clicked_tile = tile
	for column in range(1, 8):
		for row in range(1, 8):
			if can_piece_move(tile, Vector2(row, column)):
				$Board/Highlights.set_cell(Vector2(row, column), 0, Vector2(0, 3))

func move_piece(old_tile, new_tile):
	tile_info(old_tile)
	if can_piece_move(last_clicked_tile, clicked_tile):
		$Board/Pieces.set_cell(old_tile, -1, Vector2(-1, -1))
		$Board/Pieces.set_cell(new_tile, source_id, atlas_coords)
	else:
		find_clicked_tile()
		if tile_type != Piece.BLANK:
			click_tile(clicked_tile)

func can_piece_move(old_tile, new_tile) -> bool:
	tile_info(old_tile)
	
	# Pawn
	if tile_type == Piece.PAWN:
		if new_tile.x == old_tile.x:
			if (new_tile.y - old_tile.y) == -1:
				return true
			if (new_tile.y - old_tile.y) == -2 and old_tile.y >= 6:
				return true
	
	return false
