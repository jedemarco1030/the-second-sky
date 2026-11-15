extends Node
## Headless check for the harbor walk. Exits 0 when every check passes.
##   godot --headless --path . res://tools/smoke_test.tscn

var _failures: int = 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene: PackedScene = load(ProjectSettings.get_setting("application/run/main_scene"))
	_check(scene != null, "main scene loads")
	var harbor: Node = scene.instantiate()
	get_tree().root.add_child.call_deferred(harbor)
	await _frames(3)

	var map: HarborMap = harbor.get_node("HarborMap")
	var player: Player = harbor.get_node("World/Player")
	var nell: Npc = harbor.get_node("World/Nell")
	var dialogue: DialogueBox = harbor.get_node("DialogueBox")
	var hud: Hud = harbor.get_node("HUD")

	_check_layout(map)
	_check(player.global_position.y < 7 * HarborMap.TILE, "Mira starts at the top of the staircase")
	_check(hud.objective() == harbor.OBJECTIVE_START, "starting objective is shown")
	_check_route(map)

	# Collision: walking south into the waterfront railing must stop at the rail.
	player.global_position = Vector2(8 * HarborMap.TILE, 21 * HarborMap.TILE + 10)
	Input.action_press("move_down")
	await _physics(45)
	Input.action_release("move_down")
	_check(player.global_position.y <= HarborMap.PIER_ROW * HarborMap.TILE + 1, "railing blocks Mira (y=%.1f)" % player.global_position.y)
	_check(harbor.reached_waterfront, "reaching the waterfront updates progress")
	_check(hud.objective() == harbor.OBJECTIVE_FIND_NELL, "objective points Mira to Nell")

	# Collision: walking straight into Nell must not pass through her.
	player.global_position = nell.global_position + Vector2(-40, 0)
	Input.action_press("move_right")
	await _physics(60)
	Input.action_release("move_right")
	_check(player.global_position.x < nell.global_position.x - 6.0, "Nell blocks Mira (dx=%.1f)" % (nell.global_position.x - player.global_position.x))

	# Prompt appears near Nell.
	await _physics(2)
	_check(player.focused_interactable() == nell.interactable(), "Nell is the focused interactable")
	_check(nell.interactable().get_node("Prompt").visible, "talk prompt is visible near Nell")

	# Keyboard interaction opens dialogue and locks movement.
	_press_key(KEY_E)
	await _frames(2)
	_check(dialogue.is_open, "E opens dialogue")
	_check(player.input_locked, "movement is locked during dialogue")
	_check(not nell.interactable().get_node("Prompt").visible, "prompt hides during dialogue")

	var start_x: float = player.global_position.x
	Input.action_press("move_left")
	await _physics(20)
	Input.action_release("move_left")
	_check(is_equal_approx(player.global_position.x, start_x), "Mira cannot walk while dialogue is open")

	# Enter reveals the line, then advances.
	_press_key(KEY_ENTER)
	await _frames(1)
	_check(not dialogue.is_typing(), "Enter reveals the full line")
	_press_key(KEY_ENTER)
	await _frames(1)
	_check(dialogue.is_open and dialogue._index == 1, "Enter advances to the next line")

	# Escape dismisses dialogue and restores movement.
	_press_key(KEY_ESCAPE)
	await _frames(2)
	_check(not dialogue.is_open, "Esc dismisses dialogue")
	_check(not player.input_locked, "movement resumes after dialogue")
	_check(harbor.talked_to_nell, "talking to Nell is recorded")
	_check(hud.objective() == harbor.OBJECTIVE_DONE, "final objective is shown")

	Input.action_press("move_left")
	await _physics(20)
	Input.action_release("move_left")
	_check(player.global_position.x < start_x - 4.0, "Mira walks again after dialogue")

	# Gamepad: A talks, B closes, the stick moves, prompts switch labels.
	player.global_position = nell.global_position + Vector2(-18, 0)
	await _physics(3)
	_press_button(JOY_BUTTON_A)
	await _frames(2)
	_check(_hints().uses_gamepad, "gamepad input switches prompts to gamepad")
	_check(dialogue.is_open, "gamepad A opens dialogue")
	_check(dialogue._hint.text.begins_with("(A)"), "dialogue hint shows gamepad buttons")
	_press_button(JOY_BUTTON_B)
	await _frames(2)
	_check(not dialogue.is_open and not player.input_locked, "gamepad B dismisses dialogue")

	var stick_start: Vector2 = player.global_position
	_move_stick(JOY_AXIS_LEFT_Y, -1.0)
	await _physics(20)
	_move_stick(JOY_AXIS_LEFT_Y, 0.0)
	_check(player.global_position.y < stick_start.y - 4.0, "gamepad stick moves Mira")

	_press_key(KEY_W)
	await _frames(1)
	_check(not _hints().uses_gamepad, "keyboard input switches prompts back")

	print("")
	if _failures == 0:
		print("SMOKE TEST PASSED")
	else:
		print("SMOKE TEST FAILED: %d check(s)" % _failures)
	get_tree().quit(0 if _failures == 0 else 1)


func _check_layout(map: HarborMap) -> void:
	var width: int = map.columns()
	var uniform: bool = true
	for row in HarborMap.LAYOUT:
		uniform = uniform and row.length() == width
	_check(uniform, "every layout row is %d tiles wide" % width)
	_check(map.size_px().x >= 640 and map.size_px().y >= 360, "map fills the 640x360 view")


## Breadth-first search over walkable tiles from Mira's start to a tile next to Nell.
func _check_route(map: HarborMap) -> void:
	var start := Vector2i(map.find_marker("S") / HarborMap.TILE)
	var nell := Vector2i(map.find_marker("N") / HarborMap.TILE)
	var frontier: Array[Vector2i] = [start]
	var seen: Dictionary = {start: true}
	var reached: bool = false
	while not frontier.is_empty():
		var cell: Vector2i = frontier.pop_front()
		if cell.distance_to(nell) == 1.0:
			reached = true
			break
		for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + step
			if seen.has(next) or map.is_solid(next) or next == nell:
				continue
			seen[next] = true
			frontier.append(next)
	_check(reached, "a walkable route connects the stairs to Nell (%d tiles explored)" % seen.size())


func _press_key(keycode: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		event.keycode = keycode
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()


func _press_button(button: JoyButton) -> void:
	for pressed in [true, false]:
		var event := InputEventJoypadButton.new()
		event.button_index = button
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()


func _move_stick(axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _physics(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _check(condition: bool, description: String) -> void:
	if condition:
		print("  ok    ", description)
	else:
		_failures += 1
		print("  FAIL  ", description)


## Looked up by path so the test reads the same node the game uses.
func _hints() -> Node:
	return get_tree().root.get_node("InputHints")
