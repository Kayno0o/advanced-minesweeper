extends Control
class_name GameBoard

var grid_width: int = 16
var grid_height: int = 16
var bomb_count: int = 24

@onready var fg: TileMapLayer = %Foreground
@onready var bg: TileMapLayer = %Background

var bombs: Dictionary[Vector2i, bool] = {}  # Use typed Dictionary for O(1) lookup (Godot 4.4+)
var flags: int = 0

signal win
signal lose

## Starts a new game with the specified grid dimensions and bomb count.
## Validates inputs and initializes the game board.
##
## @param new_grid_width: Width of the grid (must be positive)
## @param new_grid_height: Height of the grid (must be positive)
## @param new_bomb_count: Number of bombs to place (must be less than total cells)
func start_game(new_grid_width: int, new_grid_height: int, new_bomb_count: int) -> void:
	# Validate input parameters
	assert(new_grid_width > 0, "Grid width must be positive, got: %d" % new_grid_width)
	assert(new_grid_height > 0, "Grid height must be positive, got: %d" % new_grid_height)
	assert(new_bomb_count >= 0, "Bomb count cannot be negative, got: %d" % new_bomb_count)
	assert(new_bomb_count < new_grid_width * new_grid_height,
		"Bomb count (%d) must be less than total cells (%d)" % [new_bomb_count, new_grid_width * new_grid_height])

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

	# add bombs (optimized: shuffle and take first N elements)
	cells.shuffle()
	for i in range(bomb_count):
		bombs[cells[i]] = true

	cells.clear()

	# get the board-container ratio to make the board fit
	var board_size: Vector2 = get_rect().size
	var container_size: Vector2 = Vector2(bg.get_used_rect().size) * Vector2(bg.tile_set.tile_size)
	var ratio = min(board_size.x / container_size.x, board_size.y / container_size.y)

	bg.scale = Vector2(ratio, ratio)
	fg.scale = Vector2(ratio, ratio)

func _unhandled_input(event: InputEvent) -> void: # Use _unhandled_input for better UI interaction (Godot 4.4+ best practice)
	var mouse_event := event as InputEventMouseButton
	if mouse_event == null or not mouse_event.pressed:
		return

	var local_position: Vector2 = bg.to_local(mouse_event.global_position)
	var cell: Vector2i = bg.local_to_map(local_position)

	match mouse_event.button_index:
		MOUSE_BUTTON_LEFT:
			left_click(cell)
		MOUSE_BUTTON_RIGHT:
			right_click(cell)
		MOUSE_BUTTON_MIDDLE:
			middle_click(cell)

func is_valid_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < grid_width and cell.y >= 0 and cell.y < grid_height

func left_click(cell: Vector2i) -> void:
	if not is_valid_cell(cell):
		return

	var fg_data: TileData = fg.get_cell_tile_data(cell)

	var is_flag: bool = fg_data.get_custom_data("is_flag") if fg_data != null else false
	if is_flag:
		return

	var is_bomb_cell: bool = is_bomb(cell)

	if is_bomb_cell:
		bg.set_cells_terrain_connect([cell], 0, Constants.CELL_PRESSED, true)
		fg.set_cell(cell, 0, Constants.TILE_BOMB)
		handle_lose()
	else:
		explore(cell)
		check_and_handle_win()

func middle_click(cell: Vector2i) -> void:
	if not is_valid_cell(cell):
		return

	var fg_data: TileData = fg.get_cell_tile_data(cell)

	var number: int = fg_data.get_custom_data("number") if fg_data != null else 0
	if number > 0:
		var bomb_nb: int = has_bomb_neighbour(get_surrounding_cells(cell))
		var correct_flag_nb: int = get_surrounding_cells(cell).reduce(
			func(acc: int, neighbour: Vector2i) -> int:
				var neighbour_fg_data: TileData = fg.get_cell_tile_data(neighbour)
				if neighbour_fg_data != null and neighbour_fg_data.get_custom_data("is_flag") and is_bomb(neighbour):
					acc += 1
				return acc,
			0
		)

		if bomb_nb == correct_flag_nb:
			for neighbour in get_surrounding_cells(cell):
				var neighbour_fg_data: TileData = fg.get_cell_tile_data(neighbour)
				if neighbour_fg_data == null:
					explore(neighbour)
			check_and_handle_win()

func right_click(cell: Vector2i) -> void:
	if not is_valid_cell(cell):
		return

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

## Explores a cell and recursively reveals adjacent empty cells.
## If the cell contains a number, only that cell is revealed.
## Uses BFS algorithm for efficient exploration.
##
## @param cell_to_explore: The grid position to start exploring from
func explore(cell_to_explore: Vector2i) -> void:
	var cells_queue: Array[Vector2i] = [cell_to_explore]

	while cells_queue.size():
		var cell := cells_queue[0]
		cells_queue.remove_at(0)

		var cell_data := bg.get_cell_tile_data(cell)
		if cell_data == null:
			continue
		if cell_data.get_custom_data("is_pressed"):
			continue

		bg.set_cells_terrain_connect([cell], 0, Constants.CELL_PRESSED, true)

		var surrounding_cells := get_surrounding_cells(cell)
		var neighbor_bombs := has_bomb_neighbour(surrounding_cells)
		if neighbor_bombs:
			fg.set_cell(cell, 0, Vector2i(neighbor_bombs - 1, 0))
			continue

		cells_queue.append_array(surrounding_cells)

## Returns all valid neighboring cells around the given cell.
## Uses the 8-direction neighbor pattern defined in Constants.
##
## @param cell: The cell to get neighbors for
## @returns: Array of valid neighboring cell positions
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
		var fg_data: TileData = fg.get_cell_tile_data(neighbour)
		if fg_data != null and fg_data.get_custom_data("is_flag"):
			number += 1
	return number

func handle_lose() -> void:
	lose.emit()

func check_and_handle_win() -> void:
	if is_win():
		win.emit()

func is_win() -> bool:
	for y in range(grid_height):
		for x in range(grid_width):
			var cell: Vector2i = Vector2i(x, y)

			var bg_data: TileData = bg.get_cell_tile_data(cell)
			var fg_data: TileData = fg.get_cell_tile_data(cell)

			if bg_data == null:
				return false

			var is_bomb_cell: bool = is_bomb(cell)
			var is_pressed: bool = bg_data.get_custom_data("is_pressed")

			if is_bomb_cell:
				if fg_data == null:
					continue

				var is_flag: bool = fg_data.get_custom_data("is_flag") if fg_data != null else false
				if not is_flag:
					return false
				
				continue

			if not is_pressed:
				return false

	return true
