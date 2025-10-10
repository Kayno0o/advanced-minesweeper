extends Control
class_name GameBoard

var grid_width: int = 16
var grid_height: int = 16
var bomb_count: int = 24

@onready var fg: TileMapLayer = %Foreground
@onready var bg: TileMapLayer = %Background

var bombs: Dictionary = {}  # Use Dictionary for O(1) lookup instead of O(n) array search
var flags: int

signal win
signal lose

func start_game(new_grid_width: int, new_grid_height: int, new_bomb_count: int):
	grid_width = new_grid_width
	grid_height = new_grid_height
	bomb_count = new_bomb_count
	flags = 0

	bg.position = Vector2(0, 0)
	bg.clear()

	fg.position = Vector2(0, 0)
	fg.clear()
	
	bombs.clear()

	# generate game board
	var cells: Array[Vector2i] = []
	for y in range(grid_height):
		for x in range(grid_width):
			cells.append(Vector2i(x, y))
	bg.set_cells_terrain_connect(cells, 0, Constants.CELL_UNPRESSED, true)

	# add bombs
	for i in range(bomb_count):
		var rid = randi_range(0, cells.size() - 1)
		var cell = cells[rid]

		bombs[cell] = true
		cells.remove_at(rid)

	cells.clear()

	# get the board-container ratio to make the board fit
	var board_size: Vector2 = get_rect().size
	var container_size: Vector2 = Vector2(bg.get_used_rect().size) * Vector2(bg.tile_set.tile_size)
	var ratio = min(board_size.x / container_size.x, board_size.y / container_size.y)

	bg.scale = Vector2(ratio, ratio)
	fg.scale = Vector2(ratio, ratio)

func _input(event: InputEvent):
	if not event is InputEventMouseButton or !event.pressed:
		return

	var local_position = bg.to_local(event.global_position)
	var cell: Vector2i = bg.local_to_map(local_position)

	if event.button_index == MOUSE_BUTTON_MIDDLE:
		middle_click(cell)
		return

	if event.button_index == MOUSE_BUTTON_LEFT:
		left_click(cell)
		return
	
	if event.button_index == MOUSE_BUTTON_RIGHT:
		right_click(cell)
		return

func left_click(cell: Vector2i):
	var fg_data: TileData = fg.get_cell_tile_data(cell)

	var is_flag = fg_data.get_custom_data("is_flag") if fg_data != null else false
	if is_flag:
		return

	var is_bomb: bool = is_bomb(cell)

	if is_bomb:
		bg.set_cells_terrain_connect([cell], 0, Constants.CELL_PRESSED, true)
		fg.set_cell(cell, 0, Constants.TILE_BOMB)
		handle_lose()
	else:
		explore(cell)
		check_and_handle_win()

func middle_click(cell: Vector2i):
	var fg_data: TileData = fg.get_cell_tile_data(cell)

	var number: int = fg_data.get_custom_data("number") if fg_data != null else 0
	if number > 0:
		var bomb_nb = has_bomb_neighbour(get_surrounding_cells(cell))
		var correct_flag_nb = get_surrounding_cells(cell).reduce(
			func(acc: int, neighbour: Vector2i):
				var neighbour_fg_data = fg.get_cell_tile_data(neighbour)
				if neighbour_fg_data != null and neighbour_fg_data.get_custom_data("is_flag") and is_bomb(neighbour):
					acc += 1
				return acc,
			0
		)

		if bomb_nb == correct_flag_nb:
			for neighbour in get_surrounding_cells(cell):
				var neighbour_fg_data = fg.get_cell_tile_data(neighbour)
				if neighbour_fg_data == null:
					explore(neighbour)
			check_and_handle_win()

func right_click(cell: Vector2i):
	var bg_data: TileData = bg.get_cell_tile_data(cell)
	var fg_data: TileData = fg.get_cell_tile_data(cell)

	if bg_data == null:
		return

	if bg_data.get_custom_data("is_pressed"):
		return

	if fg_data != null and fg_data.get_custom_data("is_flag"):
		fg.set_cell(cell)
		check_and_handle_win()
	elif fg_data == null:
		fg.set_cell(cell, 0, Constants.TILE_FLAG)
		check_and_handle_win()

func is_bomb(cell: Vector2i) -> bool:
	return bombs.has(cell)

func explore(cell_to_explore: Vector2i):
	var cells_queue: Array[Vector2i] = [cell_to_explore]

	while cells_queue.size():
		var cell = cells_queue[0]
		cells_queue.remove_at(0)

		var cell_data = bg.get_cell_tile_data(cell)
		if cell_data == null:
			continue
		if cell_data.get_custom_data("is_pressed"):
			continue

		bg.set_cells_terrain_connect([cell], 0, Constants.CELL_PRESSED, true)

		var surrounding_cells = get_surrounding_cells(cell)
		var neighbor_bombs = has_bomb_neighbour(surrounding_cells)
		if neighbor_bombs:
			fg.set_cell(cell, 0, Vector2i(neighbor_bombs - 1, 0))
			continue

		cells_queue.append_array(surrounding_cells)

func get_surrounding_cells(cell: Vector2i) -> Array[Vector2i]:
	return Constants.NEIGHBOR_DIRECTIONS.reduce(
		func(acc: Array[Vector2i], dir: Vector2i):
			var neighbor: Vector2i = cell + dir
			if bg.get_cell_source_id(neighbor) != null:
				acc.append(neighbor)
			return acc,
		[] as Array[Vector2i]
	)

func has_bomb_neighbour(surrounding_cells: Array[Vector2i]) -> int:
	var number: int = 0
	for neighbour in surrounding_cells:
		if is_bomb(neighbour):
			number += 1
	return number

func has_flag_neighbour(surrounding_cells: Array[Vector2i]) -> int:
	var number: int = 0
	for neighbour in surrounding_cells:
		var fg_data = fg.get_cell_tile_data(neighbour)
		if fg_data != null and fg_data.get_custom_data("is_flag"):
			number += 1
	return number

func handle_lose():
	lose.emit()

func check_and_handle_win():
	if is_win():
		win.emit()

func is_win() -> bool:
	for y in range(grid_height):
		for x in range(grid_width):
			var cell = Vector2i(x, y)

			var bg_data = bg.get_cell_tile_data(cell)
			var fg_data = fg.get_cell_tile_data(cell)

			if bg_data == null:
				return false

			var is_bomb_cell = is_bomb(cell)
			var is_pressed = bg_data.get_custom_data("is_pressed")

			if is_bomb_cell:
				if fg_data == null:
					continue

				var is_flag = fg_data.get_custom_data("is_flag") if fg_data != null else false
				if not is_flag:
					return false
				
				continue

			if not is_pressed:
				return false

	return true
