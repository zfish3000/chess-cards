extends Node


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

const piece_atlas_coords := {
	Vector2(-1, -1) : Piece.BLANK,
	Vector2(0, 0) : Piece.PAWN,
	Vector2(1, 0) : Piece.BISHOP,
	Vector2(2, 0) : Piece.KNIGHT,
	Vector2(3, 0) : Piece.ROOK,
	Vector2(0, 1) : Piece.KING,
	Vector2(1, 1) : Piece.QUEEN,
	Vector2(2, 1) : Piece.EMPRESS,
	Vector2(3, 1) : Piece.PRINCESS,
}
var board_size := [-1.0, 8.0, -1.0, 8.0] # (left, right, up, down)
var last_clicked_tile
var _local_mouse_pos
var _clicked_tile
var _source_id
var _atlas_coords: Vector2
var _tile_type
var _move: Vector2


func _tile_info(tile):
	_source_id = $Board/Pieces.get_cell_source_id(tile)
	_atlas_coords = $Board/Pieces.get_cell_atlas_coords(tile)
	_tile_type = piece_atlas_coords[_atlas_coords]


func _on_board_click_area_input_event(_viewport, event, _shape_idx):
	if event.is_action_released("click"):
		_find_clicked_tile()
		if last_clicked_tile == null:
			if _tile_type != Piece.BLANK:
				click_tile(_clicked_tile)
		else:
			move_piece(last_clicked_tile, _clicked_tile)


func _find_clicked_tile():
	_local_mouse_pos = $Board/Pieces.get_local_mouse_position()
	_clicked_tile = $Board/Pieces.local_to_map(_local_mouse_pos)
	_tile_info(_clicked_tile)


func click_tile(tile):
	last_clicked_tile = tile
	for column in range(board_size[0], board_size[1]):
		for row in range(board_size[2], board_size[3]):
			if can_piece_move(tile, Vector2(row, column)):
				$Board/Highlights.set_cell(Vector2(row, column), 0, Vector2(0, 3))


func move_piece(old_tile, new_tile):
	last_clicked_tile = null
	$Board/Highlights.clear()
	if can_piece_move(old_tile, new_tile):
		_tile_info(old_tile)
		$Board/Pieces.set_cell(old_tile, -1, Vector2(-1, -1))
		$Board/Pieces.set_cell(new_tile, _source_id, _atlas_coords)
	else:
		_find_clicked_tile()
		if _tile_type != Piece.BLANK:
			click_tile(_clicked_tile)
			print(_clicked_tile)


func can_piece_move(old_tile: Vector2, new_tile: Vector2) -> bool:
	_tile_info(new_tile)
	if _atlas_coords.y == 0 or _atlas_coords.y == 1:
		return false
	if $Board/BoardTiles.get_cell_source_id(new_tile) == -1:
		return false
	
	_tile_info(old_tile)
	_move = new_tile - old_tile
	
	# Pawns and king
	if _tile_type == Piece.PAWN:
		if new_tile.x == old_tile.x:
			if (new_tile.y - old_tile.y) == -1:
				return true
			if (new_tile.y - old_tile.y) == -2 and old_tile.y >= 6:
				if $Board/Pieces.get_cell_source_id(new_tile + Vector2(0, 1)) == -1:
					return true
	if _tile_type == Piece.KING:
		if abs(_move.x) <= 1 and abs(_move.y) <= 1:
			return true
	
	# Basic pieces
	if _tile_type == Piece.KNIGHT:
		return can_knight_move(old_tile, new_tile)
	if _tile_type == Piece.BISHOP:
		return can_bishop_move(old_tile, new_tile)
	if _tile_type == Piece.ROOK:
		return can_rook_move(old_tile, new_tile)
	
	# Combined pieces
	if _tile_type == Piece.QUEEN:
		return can_bishop_move(old_tile, new_tile)\
				or can_rook_move(old_tile, new_tile)
	if _tile_type == Piece.EMPRESS:
		return can_knight_move(old_tile, new_tile)\
				or can_rook_move(old_tile, new_tile)
	if _tile_type == Piece.PRINCESS:
		return can_knight_move(old_tile, new_tile)\
				or can_bishop_move(old_tile, new_tile)
	
	return false

func can_knight_move(_old_tile: Vector2, _new_tile: Vector2) -> bool:
	if abs(_move.x) + abs(_move.y) == 3\
			and _move.x != 0 and _move.y != 0:
		return true
	return false
func can_bishop_move(old_tile: Vector2, _new_tile: Vector2) -> bool:
	if abs(_move.x) == abs(_move.y):
		for dist in range(1, abs(_move.x)):
			_tile_info(old_tile + dist * round(_move.normalized()))
			if _tile_type != Piece.BLANK:
				return false
		return true
	return false
func can_rook_move(old_tile: Vector2, new_tile: Vector2) -> bool:
	if old_tile.x == new_tile.x or old_tile.y == new_tile.y:
		for dist in range(1, abs(_move.x + _move.y)):
			_tile_info(old_tile + dist * _move.normalized())
			if _tile_type != Piece.BLANK:
				return false
		return true
	return false
