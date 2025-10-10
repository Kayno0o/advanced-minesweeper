class_name Enum
extends RefCounted # Use RefCounted instead of Node for utility class (Godot 4.4+ best practice)

enum Direction {
	LEFT,
	TOP,
	RIGHT,
	BOTTOM,
}

## Converts a Direction enum to a Vector2i offset (Godot 4.5+)
static func direction_to_vector2i(direction: Direction) -> Vector2i:
	match direction:
		Direction.TOP:
			return Vector2i(0, -1)
		Direction.RIGHT:
			return Vector2i(1, 0)
		Direction.BOTTOM:
			return Vector2i(0, 1)
		Direction.LEFT:
			return Vector2i(-1, 0)
		_:
			push_warning("Unknown direction: %d" % direction)
			return Vector2i.ZERO
