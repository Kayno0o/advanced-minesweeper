extends Node

var transitioning: bool = false

var root: Control
var current_scene: Node

@onready var loading_screen_packed: PackedScene = preload("res://scenes/menu/loading_screen/loading_screen.tscn")

func init(_root: Control) -> void:
	root = _root
	current_scene = root.get_child(0)

func get_scene_position(node: Control, direction: Enum.Direction) -> Vector2:
	# Use static helper method from Enum class (Godot 4.5+ pattern)
	return Vector2(Enum.direction_to_vector2i(direction)) * node.size

func switch_to_scene_from_position(scene: String, new_scene_position: Enum.Direction, with_loading: bool = true) -> void:
	call_deferred("_switch_to_scene_from_position", scene, new_scene_position, with_loading)

func _switch_to_scene_from_position(scene: String, direction: Enum.Direction, with_loading: bool = true) -> void:
	if transitioning:
		return

	transitioning = true

	if not with_loading:
		var previous_scene = current_scene
		await load_scene_async(scene)
		await transition_to_node(previous_scene, current_scene, direction)

		transitioning = false

		return

	# Show loading screen
	var loading_screen: LoadingScreen = loading_screen_packed.instantiate()
	root.add_child(loading_screen)
	var progress_bar = loading_screen.loading_bar
	await transition_to_node(current_scene, loading_screen, direction)

	root.remove_child(current_scene)

	# Load the new scene asynchronously
	await load_scene_async(scene, progress_bar)
	current_scene.position = get_scene_position(current_scene, direction)
	await get_tree().create_timer(0.1).timeout

	await transition_to_node(loading_screen, current_scene, direction)

	transitioning = false


# asynchronously loads the scene and updates the loading bar
func load_scene_async(scene_path: String, progress_bar: ProgressBar = null) -> void:
	# request the scene to be loaded in a separate thread
	ResourceLoader.load_threaded_request(scene_path)

	# array to store the progress percentage
	var progress: Array = []
	if progress_bar != null:
		progress_bar.max_value = 1
		progress_bar.value = 0

	while ResourceLoader.load_threaded_get_status(scene_path, progress) != ResourceLoader.THREAD_LOAD_LOADED:
		if progress_bar != null:
			progress_bar.value = progress[0]
		await get_tree().process_frame

	# finish loading bar
	if progress_bar != null:
		ResourceLoader.load_threaded_get_status(scene_path, progress)
		progress_bar.value = progress[0]

	# once the scene is loaded, retrieve it
	var new_scene: PackedScene = ResourceLoader.load_threaded_get(scene_path)
	if new_scene:
		var instantiated_scene: Node = new_scene.instantiate()
		root.add_child(instantiated_scene)
		current_scene = instantiated_scene
	else:
		push_error("Failed to load scene: %s" % scene_path)

func transition_to_loading(direction: Enum.Direction) -> ProgressBar:
	var loading_screen: LoadingScreen = loading_screen_packed.instantiate()
	root.add_child(loading_screen)
	var progress_bar: ProgressBar = loading_screen.loading_bar

	await transition_to_node(current_scene, loading_screen, direction)

	return progress_bar


func create_transition_tween(from: Node, to: Node, direction: Enum.Direction) -> Tween:
	var tween: Tween = create_tween().set_parallel(true)

	# Position transitions
	var offset: Vector2 = get_scene_position(from, direction)
	tween.tween_property(from, "position", -offset, Constants.TRANSITION_DURATION_OUT)\
		.set_trans(Tween.TRANS_CIRC)

	if to != null:
		tween.tween_property(to, "position", Vector2.ZERO, Constants.TRANSITION_DURATION_IN)\
			.set_trans(Tween.TRANS_BACK)

	# Opacity transitions
	tween.tween_property(from, "modulate:a", 0.0, Constants.FADE_DURATION_OUT)
	if to != null:
		tween.tween_property(to, "modulate:a", 1.0, Constants.FADE_DURATION_IN)

	return tween

func transition_to_node(from: Node, to: Node, direction: Enum.Direction) -> void:
	if to != null:
		to.set_process(true)
		to.visible = true
		to.position = get_scene_position(to, direction)

	var tween: Tween = create_transition_tween(from, to, direction)
	await tween.finished

	if from != null:
		from.set_process(false)
		from.visible = false

		if from is Menu and from.main_button != null:
			from.main_button.grab_focus()
