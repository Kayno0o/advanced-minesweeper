extends Menu
class_name Game

enum Difficulty {EASY, NORMAL, HARD, CUSTOM}

# Preload difficulty configuration resources
const CONFIG_EASY := preload("res://resources/difficulty_easy.tres")
const CONFIG_NORMAL := preload("res://resources/difficulty_normal.tres")
const CONFIG_HARD := preload("res://resources/difficulty_hard.tres")

var current_difficulty: Difficulty
var current_config: GameConfig  # GameConfig resource

@onready var board: GameBoard = %Board

@onready var board_wrapper = $BoardWrapper
@onready var difficulty_select = $DifficultySelect
@onready var end_screen = $EndScreen

func _ready():
	board.win.connect(_on_win)
	board.lose.connect(_on_lose)

	difficulty_select.visible = true
	difficulty_select.position = Vector2(0, 0)

func _on_win() -> void:
	print("You win!")

func _on_lose() -> void:
	await MenuSwitcher.transition_to_node(board_wrapper, end_screen, Enum.Direction.LEFT)

func _on_start_difficulty(difficulty: Difficulty) -> void:
	start_game(difficulty)
	await MenuSwitcher.transition_to_node(difficulty_select, board_wrapper, Enum.Direction.TOP)

func _on_restart_game() -> void:
	start_game(current_difficulty)
	await MenuSwitcher.transition_to_node(end_screen, board_wrapper, Enum.Direction.RIGHT)

## Initializes and starts a new game with the given difficulty settings.
## Configures grid size and bomb count based on difficulty level using GameConfig resources.
##
## @param difficulty: The difficulty level (EASY, NORMAL, HARD, or CUSTOM)
func start_game(difficulty: Difficulty) -> void:
	current_difficulty = difficulty

	match difficulty:
		Difficulty.EASY:
			current_config = CONFIG_EASY
		Difficulty.NORMAL:
			current_config = CONFIG_NORMAL
		Difficulty.HARD:
			current_config = CONFIG_HARD
		Difficulty.CUSTOM:
			# show custom difficulty screen
			# For now, use normal difficulty as fallback
			current_config = CONFIG_NORMAL

	# Validate configuration before starting
	if current_config != null and current_config.is_valid():
		board.start_game(
			current_config.grid_width,
			current_config.grid_height,
			current_config.get_bomb_count()
		)
	else:
		push_error("Invalid game configuration for difficulty: %s" % Difficulty.keys()[difficulty])
