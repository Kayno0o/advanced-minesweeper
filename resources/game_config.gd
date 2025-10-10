extends Resource
class_name GameConfig

## Configuration resource for Minesweeper game difficulty settings.
## Defines grid dimensions and bomb density for different difficulty levels.

## Width of the game grid (number of cells horizontally)
@export var grid_width: int = 16

## Height of the game grid (number of cells vertically)
@export var grid_height: int = 16

## Percentage of cells that contain bombs (0-100)
@export_range(0.0, 100.0, 0.1) var bomb_percentage: float = 14.0

## Difficulty name for display purposes
@export var difficulty_name: String = "Normal"

## Calculates the total number of bombs based on grid size and percentage.
##
## @returns: The number of bombs for this configuration
func get_bomb_count() -> int:
	return int((grid_width * grid_height / 100.0) * bomb_percentage)

## Returns the total number of cells in the grid.
##
## @returns: Total cells (width × height)
func get_total_cells() -> int:
	return grid_width * grid_height

## Validates that the configuration is playable.
## A valid configuration must have at least one non-bomb cell.
##
## @returns: true if the configuration is valid
func is_valid() -> bool:
	return grid_width > 0 and grid_height > 0 and get_bomb_count() < get_total_cells()
