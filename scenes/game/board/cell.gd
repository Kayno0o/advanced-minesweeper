extends RefCounted
class_name Cell

## Represents a single cell in the Minesweeper grid.
## Encapsulates all cell-specific state and behavior.

## The grid position of this cell
var position: Vector2i

## Whether this cell contains a bomb
var is_bomb: bool = false

## Whether this cell has been flagged by the player
var is_flagged: bool = false

## Whether this cell has been explored/revealed
var is_explored: bool = false

## The number of bombs in neighboring cells (0-8)
var neighbor_bomb_count: int = 0

## Initializes a new cell at the specified grid position.
##
## @param grid_position: The Vector2i position of this cell in the grid
func _init(grid_position: Vector2i) -> void:
	position = grid_position

## Toggles the flag state of this cell.
## Returns the new flag state.
##
## @returns: true if the cell is now flagged, false otherwise
func toggle_flag() -> bool:
	is_flagged = not is_flagged
	return is_flagged

## Marks this cell as explored/revealed.
func explore() -> void:
	is_explored = true

## Returns whether this cell can be flagged.
## Cells that are already explored cannot be flagged.
##
## @returns: true if the cell can be flagged
func can_be_flagged() -> bool:
	return not is_explored

## Returns whether this cell can be explored.
## Cells that are flagged or already explored cannot be explored.
##
## @returns: true if the cell can be explored
func can_be_explored() -> bool:
	return not is_flagged and not is_explored

## Returns whether this cell is empty (no bomb and no neighboring bombs).
##
## @returns: true if the cell has no bomb and no neighboring bombs
func is_empty() -> bool:
	return not is_bomb and neighbor_bomb_count == 0

## Returns a string representation of the cell for debugging.
##
## @returns: String describing the cell's state
func _to_string() -> String:
	var parts: Array[String] = []
	parts.append("Cell(%s)" % position)
	if is_bomb:
		parts.append("BOMB")
	if is_flagged:
		parts.append("FLAGGED")
	if is_explored:
		parts.append("EXPLORED")
	if neighbor_bomb_count > 0:
		parts.append("neighbors=%d" % neighbor_bomb_count)
	return " ".join(parts)
