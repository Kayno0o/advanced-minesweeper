extends Node
class_name Constants

# Animation timings
const TRANSITION_DURATION_OUT := 0.5
const TRANSITION_DURATION_IN := 0.7
const TRANSITION_DURATION_BACK := 0.4
const FADE_DURATION_OUT := 0.6
const FADE_DURATION_IN := 0.4

# Cell states for TileMap terrain
const CELL_PRESSED := 0
const CELL_UNPRESSED := 1

# Tile atlas coordinates
const TILE_FLAG := Vector2i(0, 1)
const TILE_BOMB := Vector2i(1, 1)

# Neighbor directions for minesweeper grid
const NEIGHBOR_DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, -1),   # Top-right
	Vector2i(1, 0),    # Right
	Vector2i(1, 1),    # Bottom-right
	Vector2i(0, 1),    # Bottom
	Vector2i(-1, 1),   # Bottom-left
	Vector2i(-1, 0),   # Left
	Vector2i(-1, -1),  # Top-left
	Vector2i(0, -1)    # Top
]
