class_name Board
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
	ENEMY,
}
enum Tile{
	EMPTY,
	BLANK,
	CRACKED,
	RANKUP,
	MONEY,
	GOLD,
	MUD,
	LAVA,
	WALL,
}

const piece_atlas_coords := {
	Vector2(-1, -1) : Piece.BLANK,
	Vector2(0, 0) : Piece.PAWN,
	Vector2(1, 0) : Piece.KNIGHT,
	Vector2(2, 0) : Piece.BISHOP,
	Vector2(3, 0) : Piece.ROOK,
	Vector2(0, 1) : Piece.KING,
	Vector2(1, 1) : Piece.QUEEN,
	Vector2(2, 1) : Piece.EMPRESS,
	Vector2(3, 1) : Piece.PRINCESS,
}
const tile_atlas_coords := {
	Vector2(-1, -1) : Tile.EMPTY,
	Vector2(0, 0) : Tile.BLANK,
	Vector2(1, 0) : Tile.CRACKED,
	Vector2(2, 0) : Tile.RANKUP,
	Vector2(3, 0) : Tile.MONEY,
	Vector2(0, 1) : Tile.BLANK,
	Vector2(1, 1) : Tile.CRACKED,
	Vector2(2, 1) : Tile.RANKUP,
	Vector2(3, 1) : Tile.MONEY,
	Vector2(0, 2) : Tile.GOLD,
	Vector2(1, 2) : Tile.MUD,
	Vector2(2, 2) : Tile.LAVA,
	Vector2(3, 2) : Tile.WALL,
}

@export var tile_board: TileMapLayer
@export var piece_board: TileMapLayer
@export var highlight_board: TileMapLayer
@export var game: Node

var board_size := [-1.0, 9.0, -1.0, 9.0] # (left, right, up, down)
var last_clicked_tile
var _local_mouse_pos
var _clicked_tile
var _source_id
var _atlas_coords: Vector2
var _tile_type
var _move: Vector2


func _tile_info(tile):
	_source_id = piece_board.get_cell_source_id(tile)
	_atlas_coords = piece_board.get_cell_atlas_coords(tile)
	if _atlas_coords.y <= 1:
		_tile_type = piece_atlas_coords[_atlas_coords]
	else:
		_tile_type = Piece.ENEMY


func tile_at(tile) -> Tile:
	var tile_atlas_coords_var: Vector2 = tile_board.get_cell_atlas_coords(tile)
	return tile_atlas_coords[tile_atlas_coords_var]


func _on_board_click_area_input_event(_viewport, event, _shape_idx):
	if event.is_action_released("click"):
		_find_clicked_tile()
		if last_clicked_tile == null:
			if _tile_type != Piece.BLANK:
				click_tile(_clicked_tile)
		else:
			move_piece(last_clicked_tile, _clicked_tile)


func _find_clicked_tile():
	_local_mouse_pos = piece_board.get_local_mouse_position()
	_clicked_tile = piece_board.local_to_map(_local_mouse_pos)
	_tile_info(_clicked_tile)


func click_tile(tile):
	last_clicked_tile = tile
	for column in range(board_size[0], board_size[1]):
		for row in range(board_size[2], board_size[3]):
			if can_piece_move(tile, Vector2(row, column)):
				highlight_tile(tile, Vector2(row, column))


func highlight_tile(piece_tile, tile):
	var attack := false
	var special := false
	
	_tile_info(tile)
	if _tile_type == Piece.ENEMY:
		attack = true
	if tile_at(tile) == Tile.MONEY or tile_at(tile) == Tile.RANKUP:
		special = true
	
	_tile_info(piece_tile)
	if _tile_type == Piece.PAWN and tile.y <= 0:
		special = true
	
	highlight_board.set_cell(tile, 0, Vector2((
		(1 if attack else 0) + (2 if special else 0)
	), 3))


func move_piece(old_tile, new_tile):
	last_clicked_tile = null
	highlight_board.clear()
	
	if can_piece_move(old_tile, new_tile):
		_tile_info(old_tile)
		piece_board.set_cell(old_tile, -1, Vector2(-1, -1))
		if _tile_type == Piece.PAWN and new_tile.y <= 0:
			piece_board.set_cell(new_tile, _source_id, Vector2(1, 1))
		else:
			piece_board.set_cell(new_tile, _source_id, _atlas_coords)
		
		if tile_at(old_tile) == Tile.CRACKED:
			tile_board.set_cell(old_tile, -1, Vector2(-1, -1))
		if tile_at(new_tile) == Tile.MONEY:
			game.money += 5
			tile_board.set_cell(new_tile, 0, Vector2(0, 
					1 if (new_tile.x + new_tile.y) % 2 == 0 else 0)
			)
		if tile_at(new_tile) == Tile.RANKUP:
			rankup(new_tile)
			tile_board.set_cell(new_tile, 0, Vector2(0, 
					1 if (new_tile.x + new_tile.y) % 2 == 0 else 0)
			)
	
	else:
		_find_clicked_tile()
		if _tile_type != Piece.BLANK:
			if not _clicked_tile == old_tile:
				click_tile(_clicked_tile)


func can_piece_move(old_tile: Vector2, new_tile: Vector2) -> bool:
	_tile_info(new_tile)
	if _atlas_coords.y == 0 or _atlas_coords.y == 1\
			or tile_at(new_tile) == Tile.WALL\
			or tile_at(new_tile) == Tile.LAVA\
			or tile_board.get_cell_source_id(new_tile) == -1:
		return false
	
	
	_tile_info(old_tile)
	_move = new_tile - old_tile
	
	# Pawns and king
	if _tile_type == Piece.PAWN:
		return can_pawn_move(old_tile, new_tile)
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

func can_pawn_move(old_tile: Vector2, new_tile: Vector2) -> bool:
	
	if new_tile.x == old_tile.x:
		if piece_board.get_cell_source_id(new_tile) != -1:
			return false
		
		if (new_tile.y - old_tile.y) == -1:
			return true
		if (new_tile.y - old_tile.y) == -2 and old_tile.y >= 6\
				and piece_board.get_cell_source_id(new_tile + Vector2(0, 1)) == -1\
				and tile_at(new_tile + Vector2(0, 1)) != Tile.WALL:
			return true
	
	if abs(_move.x) == 1 and _move.y == -1\
			and piece_board.get_cell_atlas_coords(new_tile).y > 1:
		return true
	
	return false
func can_knight_move(_old_tile: Vector2, _new_tile: Vector2) -> bool:
	if abs(_move.x) + abs(_move.y) == 3\
			and _move.x != 0 and _move.y != 0:
		return true
	
	return false
func can_bishop_move(old_tile: Vector2, _new_tile: Vector2) -> bool:
	if abs(_move.x) == abs(_move.y):
		var _test_tile
		for dist in range(1, abs(_move.x)):
			_test_tile = old_tile + dist * round(_move.normalized())
			_tile_info(_test_tile)
			if _tile_type != Piece.BLANK\
					or tile_at(_test_tile) == Tile.WALL\
					or tile_at(_test_tile) == Tile.MUD:
				return false
		return true
	return false
func can_rook_move(old_tile: Vector2, new_tile: Vector2) -> bool:
	if old_tile.x == new_tile.x or old_tile.y == new_tile.y:
		var _test_tile
		for dist in range(1, abs(_move.x + _move.y)):
			_test_tile = old_tile + dist * round(_move.normalized())
			_tile_info(_test_tile)
			if _tile_type != Piece.BLANK\
					or tile_at(_test_tile) == Tile.WALL\
					or tile_at(_test_tile) == Tile.MUD:
				return false
		return true
	return false


func rankup(tile):
	_tile_info(tile)
	if _tile_type == Piece.ROOK:
		piece_board.set_cell(tile, _source_id, Vector2(1, 1))
	elif _atlas_coords.y == 0:
		piece_board.set_cell(tile, _source_id, _atlas_coords + Vector2(1, 0))
