extends Node
## Headless check for the harbor walk and the seawall battle. Exits 0 when every
## check passes.
##   godot --headless --path . res://tools/smoke_test.tscn

const Sim = preload("res://tools/battle_sim.gd")
const BATTLE_FRAME_BUDGET: int = 6000

var _failures: int = 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_state().capture_scene_changes = true
	_state().talked_to_nell = false
	_state().seawall_cleared = false
	_state().returning_from_seawall = false
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
	_check(hud.objective() == harbor.OBJECTIVE_SEAWALL, "objective points Mira to Tovan at the seawall")
	_check(_state().talked_to_nell, "talking to Nell survives scene changes (GameState)")

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

	await _check_tovan_entry(harbor, player)
	harbor.queue_free()
	await _frames(2)
	await _check_battle()
	await _check_return_to_harbor(scene)

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


# --- Seawall ---------------------------------------------------------------

func _check_tovan_entry(harbor: Node, player: Player) -> void:
	var tovan: Npc = harbor.get_node("World/Tovan")
	var dialogue: DialogueBox = harbor.get_node("DialogueBox")
	player.global_position = tovan.global_position + Vector2(18, 0)
	await _physics(3)
	_check(player.focused_interactable() == tovan.interactable(), "Tovan is the focused interactable at the seawall")
	_state().last_scene_request = ""
	_press_key(KEY_E)
	await _frames(2)
	_check(dialogue.is_open, "E starts Tovan's seawall dialogue")
	for i in 12:
		if not dialogue.is_open:
			break
		_press_key(KEY_ENTER)
		await _frames(1)
	_check(not dialogue.is_open, "Tovan's dialogue can be read through with Enter")
	_check(_state().last_scene_request == _state().SEAWALL_SCENE, "finishing Tovan's dialogue after Nell enters the seawall encounter")


func _new_battle() -> Node:
	var battle: Node = load(_state().SEAWALL_SCENE).instantiate()
	battle.pace = 0.0
	get_tree().root.add_child(battle)
	await _frames(3)
	return battle


func _check_battle() -> void:
	var battle: Node = await _new_battle()
	var model: BattleModel = battle.model
	_check(battle.menu_state == "command" and model.current().id == "mira", "battle opens on Mira's command menu")
	_check(battle.timeline_entries.size() == battle.TIMELINE_LENGTH, "timeline shows %d upcoming turns" % battle.TIMELINE_LENGTH)
	_check(_index_of(battle.timeline_entries, "surge") != -1, "the pump's Surge is placed on the opening timeline")
	_check(battle.menu_actions() == ["attack", "rally", "guard"], "Mira's commands: Strike, Rally, Guard (%s)" % [battle.menu_actions()])

	# Menu navigation by keyboard and gamepad.
	_press_key(KEY_DOWN)
	await _frames(1)
	_check(battle.highlighted_action() == "rally", "keyboard Down moves the command cursor")
	_press_button(JOY_BUTTON_DPAD_DOWN)
	await _frames(1)
	_check(battle.highlighted_action() == "guard", "gamepad D-pad moves the command cursor")
	_move_stick(JOY_AXIS_LEFT_Y, -1.0)
	await _frames(1)
	_move_stick(JOY_AXIS_LEFT_Y, 0.0)
	await _frames(1)
	_check(battle.highlighted_action() == "rally", "gamepad stick moves the command cursor")
	_check(battle.info_text().contains("right after Mira"), "Rally explains how it changes turn order")
	_press_key(KEY_UP)
	await _frames(1)

	# No timed inputs: waiting on a menu changes nothing.
	var turn_before: int = model.turn_count
	await _frames(120)
	_check(battle.menu_state == "command" and model.turn_count == turn_before, "the battle waits indefinitely for a command (no timed input)")

	# Strategy 1: Guard through every Surge, keyboard only.
	var guard: Dictionary = await _play(battle, "guard", false)
	_check(battle.result_kind == "victory", "Guard strategy wins (%d turns, %d Surges weathered)" % [guard["turns"], guard["taken"]])
	_check(guard["taken"] >= 1 and guard["guarded_surges"] == guard["taken"], "every Surge in the Guard run hit a guarding party (%d/%d)" % [guard["guarded_surges"], guard["taken"]])
	_check(battle._result_panel.visible and battle.menu_actions() == ["return", "retry"], "victory screen offers Return to Harbor first")

	# Fight Again from victory resets the encounter.
	_press_key(KEY_DOWN)
	await _frames(1)
	_press_key(KEY_ENTER)
	await _frames(3)
	model = battle.model
	_check(_is_fresh(battle), "Fight Again resets the encounter")

	# Strategy 2: Rally Nell + Breakwater with Tovan, gamepad only.
	var bw: Dictionary = await _play(battle, "breakwater", true)
	_check(battle.result_kind == "victory", "Breakwater strategy wins (%d turns)" % bw["turns"])
	_check(bw["broken"] >= 1, "Breakwater broke at least one Surge (%d)" % bw["broken"])
	_check(bw["rallied_nell"], "the winning Breakwater run used Mira's Rally on Nell")
	_check(bw["previewed"], "Breakwater preview named two spent turns and the resolve turn before confirm")
	_check(bw["preview_matched"], "every Breakwater resolved on its previewed turn (%d checked)" % bw["resolve_matches"])
	_check(bw["back_worked"], "Back/B leaves the Breakwater preview without spending a turn")
	_check(bw["turns"] < guard["turns"], "Breakwater finishes faster than Guard (%d vs %d turns)" % [bw["turns"], guard["turns"]])

	# Losing, then the one-action retry from the defeat screen.
	_press_button(JOY_BUTTON_DPAD_DOWN)
	await _frames(1)
	_press_button(JOY_BUTTON_A)
	await _frames(3)
	var reckless: Dictionary = await _play(battle, "attack", false)
	_check(battle.result_kind == "defeat", "attacking blindly into Surges loses (%d turns)" % reckless["turns"])
	_check(battle.menu_actions()[0] == "retry", "defeat screen highlights Retry")
	_press_key(KEY_ENTER)
	await _frames(3)
	_check(_is_fresh(battle), "one press of Retry on the defeat screen resets the encounter")

	# Mid-fight retry with R / Back.
	_press_key(KEY_ENTER)
	await _frames(6)
	_check(battle.model.turn_count > 0, "a turn was taken before mid-fight retry")
	_press_button(JOY_BUTTON_BACK)
	await _frames(3)
	_check(_is_fresh(battle), "gamepad Back retries mid-fight in one press")
	_press_key(KEY_ENTER)
	await _frames(6)
	_press_key(KEY_R)
	await _frames(3)
	_check(_is_fresh(battle), "R retries mid-fight in one press")

	# Win once more and return to the harbor.
	await _play(battle, "breakwater", false)
	_state().last_scene_request = ""
	_check(battle.highlighted_action() == "return", "Return to Harbor is highlighted on victory")
	_press_key(KEY_ENTER)
	await _frames(1)
	_check(_state().last_scene_request == _state().HARBOR_SCENE, "victory screen returns to the harbor")
	_check(_state().seawall_cleared and _state().returning_from_seawall, "victory is recorded for the harbor")
	battle.queue_free()
	await _frames(2)


func _check_return_to_harbor(scene: PackedScene) -> void:
	var harbor: Node = scene.instantiate()
	get_tree().root.add_child(harbor)
	await _frames(3)
	var player: Player = harbor.get_node("World/Player")
	var tovan: Npc = harbor.get_node("World/Tovan")
	var hud: Hud = harbor.get_node("HUD")
	_check(player.global_position.distance_to(tovan.global_position) < 3 * HarborMap.TILE, "Mira reappears beside Tovan at the seawall")
	_check(hud.objective() == harbor.OBJECTIVE_DONE, "harbor objective shows the pump is quiet")
	_check(not _state().returning_from_seawall, "return flag is consumed once")
	_state().last_scene_request = ""
	var dialogue: DialogueBox = harbor.get_node("DialogueBox")
	await _physics(3)
	_press_key(KEY_E)
	await _frames(2)
	_check(dialogue.is_open, "Tovan has an after-battle line")
	for i in 8:
		if not dialogue.is_open:
			break
		_press_key(KEY_ENTER)
		await _frames(1)
	await _frames(2)
	_check(_state().last_scene_request == "", "talking to Tovan after victory does not restart the battle")
	var start: Vector2 = player.global_position
	Input.action_press("move_right")
	await _physics(20)
	Input.action_release("move_right")
	_check(player.global_position.x > start.x + 4.0, "Mira can walk the harbor again after the battle")
	harbor.queue_free()


## Plays to a result screen with menu input only. Policies come from the balance sim.
func _play(battle: Node, policy: String, gamepad: bool) -> Dictionary:
	var stats: Dictionary = {"turns": 0, "taken": 0, "broken": 0, "guarded_surges": 0,
		"rallied_nell": false, "previewed": false, "preview_matched": false, "back_worked": false}
	## -1: nothing pending. -2: pending, but a later Rally changed the order.
	var expected_resolve_turn: int = -1
	var matches: int = 0
	var mismatches: int = 0
	var frames: int = 0
	while battle.menu_state != "result" and frames < BATTLE_FRAME_BUDGET:
		var model: BattleModel = battle.model
		if expected_resolve_turn != -1 and model.pending_breakwater.is_empty():
			if expected_resolve_turn >= 0:
				if model.turn_count == expected_resolve_turn:
					matches += 1
				else:
					mismatches += 1
					print("        Breakwater resolved after turn %d, preview said %d" % [model.turn_count, expected_resolve_turn])
			expected_resolve_turn = -1
		if battle.menu_state != "command":
			await _frames(1)
			frames += 1
			continue
		var actor: BattleUnit = model.current()
		var choice: Array = Sim.choose(model, actor, policy)
		var action: String = choice[0]
		await _choose(battle, action, gamepad)
		if action == "breakwater":
			var plan: Dictionary = battle.breakwater_plan
			var spend: Array = plan["spend"]
			var info: String = battle.info_text()
			if spend.size() == 2 and int(plan["resolve_index"]) > 0 and info.contains("turn 1") and info.contains("Resolves on turn %d" % (int(plan["resolve_index"]) + 1)):
				stats["previewed"] = true
			if not stats["back_worked"]:
				var turn_before: int = model.turn_count
				await _cancel(gamepad)
				stats["back_worked"] = battle.menu_state == "command" and battle.highlighted_action() == "breakwater" and model.turn_count == turn_before
				await _confirm(gamepad)
			expected_resolve_turn = model.turn_count + int(plan["resolve_index"]) + 1
			await _confirm(gamepad)
		elif action == "rally" or action == "mend":
			var target: String = choice[1]
			if action == "rally" and target == "nell":
				stats["rallied_nell"] = true
			if action == "rally" and expected_resolve_turn >= 0:
				expected_resolve_turn = -2
			await _seek(battle, target, gamepad)
			await _confirm(gamepad)
		await _frames(1)
		frames += 1
	stats["turns"] = battle.model.turn_count
	stats["taken"] = battle.model.surges_taken
	stats["broken"] = battle.model.surges_broken
	stats["guarded_surges"] = battle.model.surges_guarded
	stats["preview_matched"] = matches >= 1 and mismatches == 0
	stats["resolve_matches"] = matches
	return stats


## From a command menu, moves to `action` and selects it.
func _choose(battle: Node, action: String, gamepad: bool) -> void:
	await _seek(battle, action, gamepad)
	await _confirm(gamepad)


func _seek(battle: Node, value: String, gamepad: bool) -> void:
	for i in 8:
		if battle.menu_actions()[battle._cursor] == value:
			return
		if gamepad:
			_press_button(JOY_BUTTON_DPAD_DOWN)
		else:
			_press_key(KEY_DOWN)
		await _frames(1)


func _confirm(gamepad: bool) -> void:
	if gamepad:
		_press_button(JOY_BUTTON_A)
	else:
		_press_key(KEY_ENTER)
	await _frames(1)


func _cancel(gamepad: bool) -> void:
	if gamepad:
		_press_button(JOY_BUTTON_B)
	else:
		_press_key(KEY_ESCAPE)
	await _frames(1)


func _is_fresh(battle: Node) -> bool:
	var model: BattleModel = battle.model
	if model.turn_count != 0 or battle.menu_state != "command" or battle._result_panel.visible:
		return false
	for unit in model.units:
		if unit.hp != unit.max_hp:
			return false
	return model.pending_breakwater.is_empty() and model.current().id == "mira"


func _index_of(entries: Array[Dictionary], kind: String) -> int:
	for entry in entries:
		if entry["kind"] == kind:
			return entry["index"]
	return -1


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


func _state() -> Node:
	return get_tree().root.get_node("GameState")
