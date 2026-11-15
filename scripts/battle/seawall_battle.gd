class_name SeawallBattle
extends Control
## The seawall encounter: Mira, Tovan, Nell, and Pip against the harbor pump.
## Rules live in BattleModel; this script draws the turn order, field, and menus,
## and turns keyboard / gamepad presses into commands. Nothing is timed: the
## game waits on every menu, and enemy turns only play out between choices.

const INK := Color("0b1a1e")
const TEAL_DEEP := Color("133a40")
const TEAL := Color("1f6b68")
const TEAL_LIGHT := Color("5fb3a8")
const AMBER := Color("e8983a")
const AMBER_LIGHT := Color("ffd48a")
const CREAM := Color("f3e4c2")
const MUTED := Color("66787a")

## The pump's next Surge is at most 10 slots ahead (measured by tools/battle_sim.gd),
## so 12 slots always keep it on screen.
const TIMELINE_LENGTH: int = 12

const SPRITES: Dictionary = {
	"mira": {"texture": preload("res://art/mira.png"), "region": Rect2(0, 0, 16, 24), "scale": 2.0, "pos": Vector2(440, 74)},
	"tovan": {"texture": preload("res://art/tovan.png"), "region": Rect2(0, 0, 16, 24), "scale": 2.0, "pos": Vector2(478, 104)},
	"nell": {"texture": preload("res://art/nell.png"), "region": Rect2(0, 0, 16, 24), "scale": 2.0, "pos": Vector2(516, 134)},
	"pip": {"texture": preload("res://art/pip.png"), "region": Rect2(0, 0, 8, 8), "scale": 3.0, "pos": Vector2(564, 178)},
}
const PUMP_TEXTURE: Texture2D = preload("res://art/pump.png")
const PUMP_POS: Vector2 = Vector2(96, 78)

const ATTACK_NAMES: Dictionary = {"mira": "Strike", "tovan": "Hook", "nell": "Wrench", "pip": "Peck"}

## Seconds each enemy turn / result message stays up. Tests set this to 0.
var pace: float = 0.7

var model: BattleModel
## "busy" | "command" | "target" | "confirm" | "result"
var menu_state: String = "busy"
var result_kind: String = ""
var timeline_entries: Array[Dictionary] = []
## Timeline index -> tag shown on that slot ("SPEND", "RESOLVE").
var highlights: Dictionary = {}
var breakwater_plan: Dictionary = {}

var _items: Array[Dictionary] = []
var _cursor: int = 0
var _pending_action: String = ""
var _generation: int = 0

var _timeline_row: HBoxContainer
var _message: Label
var _info: Label
var _menu_title: Label
var _menu_list: VBoxContainer
var _menu_hint: Label
var _status_rows: Dictionary = {}
var _sprite_nodes: Dictionary = {}
var _tags: Dictionary = {}
var _pump_sprite: TextureRect
var _pump_atlas: AtlasTexture
var _pump_bar: ColorRect
var _pump_hp: Label
var _pump_state: Label
var _result_panel: PanelContainer
var _result_title: Label
var _result_body: Label
var _result_list: VBoxContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	InputHints.device_changed.connect(func(_pad: bool) -> void: _refresh_menu())
	start_encounter()


## Resets everything to the opening state. This is the whole retry.
func start_encounter() -> void:
	_generation += 1
	model = BattleModel.create()
	result_kind = ""
	_result_panel.visible = false
	highlights = {}
	_message.text = "The harbor pump roars over the seawall! Watch the turn order for SURGE."
	_refresh_all()
	_proceed()


func retry() -> void:
	start_encounter()


# --- Turn flow -------------------------------------------------------------

func _proceed() -> void:
	var generation: int = _generation
	menu_state = "busy"
	_refresh_menu()
	while not model.is_over():
		var actor: BattleUnit = model.start_turn()
		_refresh_all()
		if not model.is_auto_turn(actor):
			_open_commands(actor)
			return
		await _pause()
		if generation != _generation:
			return
		_message.text = String(model.run_auto_turn()["text"])
		_refresh_all()
		await _pause()
		if generation != _generation:
			return
	_show_result()


func _perform(action: String, target_id: String = "") -> void:
	var generation: int = _generation
	menu_state = "busy"
	highlights = {}
	_message.text = String(model.act(action, target_id)["text"])
	_refresh_all()
	await _pause()
	if generation == _generation:
		_proceed()


func _pause() -> void:
	if pace > 0.0:
		await get_tree().create_timer(pace).timeout
	else:
		await get_tree().process_frame


# --- Menus -----------------------------------------------------------------

func _open_commands(actor: BattleUnit) -> void:
	menu_state = "command"
	_cursor = 0
	var forecast: Array[Dictionary] = model.forecast(TIMELINE_LENGTH)
	_items = [
		{"label": ATTACK_NAMES[actor.id], "action": "attack", "enabled": true,
			"desc": "Hit the pump for %d damage." % actor.power},
	]
	match actor.id:
		"mira":
			var allies: bool = model.living_party().size() > 1
			_items.append({"label": "Rally", "action": "rally", "enabled": allies,
				"desc": "Signal an ally: their next turn moves to right after Mira's." if allies else "No ally left to signal."})
		"tovan", "nell":
			var partner: BattleUnit = model.unit(model.breakwater_partner(actor.id))
			var reason: String = ""
			if not model.pending_breakwater.is_empty():
				reason = "A Breakwater is already set."
			elif partner.is_down():
				reason = "%s is down." % partner.display_name
			_items.append({"label": "Breakwater", "action": "breakwater", "enabled": reason == "",
				"desc": reason if reason != "" else "Combo with %s: spends this turn and %s's next. Select to preview timing." % [partner.display_name, partner.display_name]})
		"pip":
			_items.append({"label": "Mend", "action": "mend", "enabled": true,
				"desc": "Restore %d HP to one ally." % BattleModel.MEND_AMOUNT})
	_items.append({"label": "Guard", "action": "guard", "enabled": true, "desc": _guard_description(actor, forecast)})
	_refresh_menu()


func _open_targets(action: String) -> void:
	menu_state = "target"
	_pending_action = action
	_cursor = 0
	_items = []
	var actor: BattleUnit = model.current()
	for member in model.living_party():
		if action == "rally" and member.id == actor.id:
			continue
		var desc: String = "%s: %d / %d HP." % [member.display_name, member.hp, member.max_hp]
		if action == "rally":
			desc = "%s acts next, right after Mira." % member.display_name
			if not model.pending_breakwater.is_empty() and model.pending_breakwater["partner"] == member.id:
				desc += " That resolves the Breakwater now."
		_items.append({"label": member.display_name, "action": action, "target": member.id, "enabled": true, "desc": desc})
	_refresh_menu()


func _open_breakwater_confirm() -> void:
	menu_state = "confirm"
	_cursor = 0
	breakwater_plan = model.breakwater_plan(TIMELINE_LENGTH)
	_items = [
		{"label": "Confirm Breakwater", "action": "breakwater", "enabled": true, "desc": _breakwater_description(breakwater_plan)},
		{"label": "Back", "action": "back", "enabled": true, "desc": _breakwater_description(breakwater_plan)},
	]
	_refresh_menu()


func _guard_description(actor: BattleUnit, forecast: Array[Dictionary]) -> String:
	var next_turn: int = -1
	var surge: int = -1
	for entry in forecast:
		if entry["index"] == 0:
			continue
		if next_turn == -1 and entry["id"] == actor.id:
			next_turn = entry["index"]
		if surge == -1 and entry["kind"] == "surge":
			surge = entry["index"]
	var text: String = "Take 1/%d damage until %s's next turn" % [BattleModel.GUARD_DIVISOR, actor.display_name]
	text += (" (turn %d)." % (next_turn + 1)) if next_turn != -1 else "."
	if surge != -1 and (next_turn == -1 or surge < next_turn):
		text += " Covers the Surge on turn %d." % (surge + 1)
	return text


func _breakwater_description(plan: Dictionary) -> String:
	var resolve: int = plan["resolve_index"]
	var surge: int = plan["surge_index"]
	var text: String = "Spends %s's turn now (turn 1)" % plan["initiator"]
	if resolve == -1:
		return text + " and %s's next turn, beyond the shown order." % plan["partner"]
	text += " and %s's turn %d. Resolves on turn %d" % [plan["partner"], resolve + 1, resolve + 1]
	if plan["breaks_surge"]:
		return text + " while the pump charges: BREAKS the Surge%s." % ((" on turn %d" % (surge + 1)) if surge != -1 else "")
	if surge != -1 and resolve > surge:
		return text + ", AFTER the Surge on turn %d. Rally can move %s up." % [surge + 1, plan["partner"]]
	return text + ", before the pump charges. %d damage, but no Surge break." % BattleModel.BREAKWATER_DAMAGE


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("retry"):
		get_viewport().set_input_as_handled()
		retry()
		return
	if menu_state == "busy":
		return
	if event.is_action_pressed("move_up"):
		get_viewport().set_input_as_handled()
		_move_cursor(-1)
	elif event.is_action_pressed("move_down"):
		get_viewport().set_input_as_handled()
		_move_cursor(1)
	elif event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_select()
	elif event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		_back()


func _move_cursor(step: int) -> void:
	var items: Array[Dictionary] = _result_items() if menu_state == "result" else _items
	if items.is_empty():
		return
	_cursor = wrapi(_cursor + step, 0, items.size())
	_refresh_menu()


func _select() -> void:
	if menu_state == "result":
		var choice: String = _result_items()[_cursor]["action"]
		if choice == "retry":
			retry()
		else:
			GameState.return_to_harbor(result_kind == "victory")
		return
	var item: Dictionary = _items[_cursor]
	if not item["enabled"]:
		return
	var action: String = item["action"]
	match menu_state:
		"command":
			if action == "rally" or action == "mend":
				_open_targets(action)
			elif action == "breakwater":
				_open_breakwater_confirm()
			else:
				_perform(action)
		"target":
			_perform(action, String(item["target"]))
		"confirm":
			if action == "back":
				_back()
			else:
				_perform("breakwater")


func _back() -> void:
	if menu_state == "target" or menu_state == "confirm":
		var reopen: String = _pending_action if menu_state == "target" else "breakwater"
		highlights = {}
		_open_commands(model.current())
		for i in _items.size():
			if _items[i]["action"] == reopen:
				_cursor = i
		_refresh_menu()


func highlighted_action() -> String:
	if menu_state == "result":
		return String(_result_items()[_cursor]["action"])
	return String(_items[_cursor]["action"]) if _cursor < _items.size() else ""


func menu_actions() -> Array[String]:
	var actions: Array[String] = []
	for item in (_result_items() if menu_state == "result" else _items):
		actions.append(String(item.get("target", item["action"])) if menu_state == "target" else String(item["action"]))
	return actions


func info_text() -> String:
	return _info.text


func _result_items() -> Array[Dictionary]:
	if result_kind == "victory":
		return [{"label": "Return to Harbor", "action": "return"}, {"label": "Fight Again", "action": "retry"}]
	return [{"label": "Retry", "action": "retry"}, {"label": "Return to Harbor", "action": "return"}]


func _show_result() -> void:
	menu_state = "result"
	result_kind = "victory" if model.is_won() else "defeat"
	_cursor = 0
	highlights = {}
	_refresh_all()
	_result_panel.visible = true
	if result_kind == "victory":
		_result_title.text = "VICTORY"
		_result_title.add_theme_color_override("font_color", AMBER_LIGHT)
		_result_body.text = "The pump grinds to a halt and the seawall holds.\nSurges broken: %d    Surges weathered: %d    Turns: %d" % [
			model.surges_broken, model.surges_taken, model.turn_count]
	else:
		_result_title.text = "THE SEAWALL FLOODS"
		_result_title.add_theme_color_override("font_color", AMBER)
		_result_body.text = "Guard before the Surge, or set up Breakwater while the pump charges.\nRetry resets the whole encounter."
	_refresh_result_menu()


# --- Drawing ---------------------------------------------------------------

func _refresh_all() -> void:
	_refresh_timeline()
	_refresh_field()
	_refresh_status()
	_refresh_menu()


func _refresh_timeline() -> void:
	if model.is_over():
		timeline_entries = []
	elif menu_state == "confirm" and not breakwater_plan.is_empty():
		timeline_entries = breakwater_plan["timeline"]
	else:
		timeline_entries = model.forecast(TIMELINE_LENGTH)
	for child in _timeline_row.get_children():
		child.queue_free()
	for entry in timeline_entries:
		_timeline_row.add_child(_timeline_slot(entry))


func _timeline_slot(entry: Dictionary) -> PanelContainer:
	var kind: String = entry["kind"]
	var index: int = entry["index"]
	var bg: Color = TEAL_DEEP
	var border: Color = TEAL
	var text_color: Color = CREAM
	var detail: String = ""
	match kind:
		"jet":
			bg = INK
			border = AMBER
			detail = "Jet>%s" % entry.get("target", "")
		"surge":
			bg = AMBER
			border = AMBER_LIGHT
			text_color = INK
			detail = "SURGE"
		"staggered":
			bg = INK
			border = MUTED
			text_color = MUTED
			detail = "Staggered"
		"breakwater":
			border = AMBER_LIGHT
			detail = "Breakwater"
		"breakwater_start":
			border = AMBER_LIGHT
			detail = "Sets BW"
	if entry["id"] != "pump" and kind == "turn" and model.unit(entry["id"]).guarding and index > 0:
		detail = "guarding"
	var tag: String = String(highlights.get(index, ""))
	if tag != "":
		border = CREAM
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(49, 40)
	slot.add_theme_stylebox_override("panel", _box(bg, border, 2 if tag != "" or index == 0 else 1))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	slot.add_child(column)
	var top: String = tag if tag != "" else ("NOW" if index == 0 else str(index + 1))
	column.add_child(_label(top, 8, AMBER_LIGHT if (tag != "" or index == 0) and kind != "surge" else (INK if kind == "surge" else TEAL_LIGHT)))
	column.add_child(_label("PUMP" if entry["id"] == "pump" else String(entry["name"]), 10, text_color))
	column.add_child(_label(detail, 8, text_color))
	return slot


func _refresh_field() -> void:
	var current: BattleUnit = null if model.is_over() else model.current()
	for unit_id: String in _sprite_nodes:
		var member: BattleUnit = model.unit(unit_id)
		var sprite: TextureRect = _sprite_nodes[unit_id]
		sprite.modulate = Color(1, 1, 1, 0.3) if member.is_down() else Color.WHITE
		var tag: Label = _tags[unit_id]
		var parts: Array[String] = []
		if current == member:
			parts.append("TURN")
		if member.is_down():
			parts.append("KO")
		elif member.guarding:
			parts.append("GUARD")
		if not model.pending_breakwater.is_empty() and model.pending_breakwater.values().has(unit_id):
			parts.append("BW")
		tag.text = " ".join(parts)
	var pump: BattleUnit = model.boss()
	_pump_atlas.region = Rect2(56 if model.is_charging() and not pump.is_down() else 0, 0, 56, 64)
	_pump_sprite.modulate = Color(1, 1, 1, 0.35) if pump.is_down() else Color.WHITE
	_pump_bar.size.x = 120.0 * float(pump.hp) / pump.max_hp
	_pump_hp.text = "HARBOR PUMP  %d / %d" % [pump.hp, pump.max_hp]
	if pump.is_down():
		_pump_state.text = "Silent"
	elif model.staggered:
		_pump_state.text = "STAGGERED - loses its next turn"
	elif model.is_charging():
		_pump_state.text = "CHARGING SURGE"
	else:
		_pump_state.text = "Next: Pressure Jet"
	_pump_state.add_theme_color_override("font_color", AMBER if model.is_charging() else TEAL_LIGHT)


func _refresh_status() -> void:
	var current: BattleUnit = null if model.is_over() else model.current()
	for member in model.party():
		var row: Dictionary = _status_rows[member.id]
		(row["name"] as Label).text = ("> " if current == member else "  ") + member.display_name
		(row["name"] as Label).add_theme_color_override("font_color", AMBER_LIGHT if current == member else CREAM)
		(row["bar"] as ColorRect).size.x = 90.0 * float(member.hp) / member.max_hp
		(row["bar"] as ColorRect).color = AMBER if float(member.hp) / member.max_hp < 0.35 else TEAL_LIGHT
		(row["hp"] as Label).text = "%d/%d" % [member.hp, member.max_hp]
		var state: String = ""
		if member.is_down():
			state = "KO"
		elif not model.pending_breakwater.is_empty() and model.pending_breakwater["partner"] == member.id:
			state = "Breakwater next turn"
		elif member.guarding:
			state = "Guarding"
		(row["state"] as Label).text = state


func _refresh_menu() -> void:
	if _menu_list == null:
		return
	if menu_state == "result":
		_refresh_result_menu()
		return
	for child in _menu_list.get_children():
		child.queue_free()
	var actor: BattleUnit = null if model.is_over() else model.current()
	if menu_state == "busy" or actor == null:
		_menu_title.text = "..."
		_info.text = ""
		_menu_hint.text = "%s  Retry" % InputHints.retry_label()
		return
	_menu_title.text = {"command": "%s's turn", "target": "%s: choose ally", "confirm": "%s: Breakwater?"}[menu_state] % actor.display_name.to_upper()
	for i in _items.size():
		var item: Dictionary = _items[i]
		var color: Color = CREAM if item["enabled"] else MUTED
		if i == _cursor:
			color = AMBER_LIGHT if item["enabled"] else MUTED
		_menu_list.add_child(_label(("> " if i == _cursor else "  ") + String(item["label"]), 11, color))
	_info.text = String(_items[_cursor]["desc"]) if _cursor < _items.size() else ""
	_update_highlights()
	_menu_hint.text = "%s  Select   %s  Back   %s  Retry" % [InputHints.interact_label(), InputHints.cancel_label(), InputHints.retry_label()]


func _update_highlights() -> void:
	var previous: Dictionary = highlights
	highlights = {}
	if menu_state == "confirm" and not breakwater_plan.is_empty():
		for index: int in breakwater_plan["spend"]:
			highlights[index] = "SPEND"
		if int(breakwater_plan["resolve_index"]) != -1:
			highlights[breakwater_plan["resolve_index"]] = "RESOLVE"
	if previous != highlights:
		_refresh_timeline()


func _refresh_result_menu() -> void:
	for child in _result_list.get_children():
		child.queue_free()
	var items: Array[Dictionary] = _result_items()
	for i in items.size():
		_result_list.add_child(_label(("> " if i == _cursor else "  ") + String(items[i]["label"]), 12, AMBER_LIGHT if i == _cursor else CREAM))
	_menu_hint.text = "%s  Select   %s  Retry" % [InputHints.interact_label(), InputHints.retry_label()]


func _draw() -> void:
	var view: Vector2 = size
	draw_rect(Rect2(Vector2.ZERO, view), INK)
	draw_rect(Rect2(0, 60, view.x, 110), TEAL_DEEP)
	for y in range(64, 170, 10):
		draw_rect(Rect2(0, y, view.x, 1), Color(TEAL, 0.35))
	# Seawall top and stones.
	draw_rect(Rect2(0, 170, view.x, 52), Color("3c4b50"))
	draw_rect(Rect2(0, 170, view.x, 3), Color("66787a"))
	for row in 3:
		for col in range(-1, 22):
			var x: float = col * 32 + (16 if row % 2 == 1 else 0)
			draw_rect(Rect2(x, 176 + row * 16, 31, 15), Color("2a3539"), false, 1.0)
	draw_rect(Rect2(0, 222, view.x, 6), TEAL)


# --- Building --------------------------------------------------------------

func _build_ui() -> void:
	var timeline_panel := _panel(Rect2(6, 4, 628, 54), TEAL)
	var timeline_box := VBoxContainer.new()
	timeline_box.add_theme_constant_override("separation", 1)
	timeline_panel.add_child(timeline_box)
	_timeline_row = HBoxContainer.new()
	_timeline_row.add_theme_constant_override("separation", 2)
	timeline_box.add_child(_timeline_row)

	_pump_atlas = AtlasTexture.new()
	_pump_atlas.atlas = PUMP_TEXTURE
	_pump_atlas.region = Rect2(0, 0, 56, 64)
	_pump_sprite = _sprite(_pump_atlas, PUMP_POS, Vector2(112, 128))
	var pump_label_y: float = 62.0
	_pump_hp = _label("", 10, CREAM)
	_pump_hp.position = Vector2(PUMP_POS.x + 130, pump_label_y + 20)
	add_child(_pump_hp)
	var bar_back := ColorRect.new()
	bar_back.color = INK
	bar_back.position = Vector2(PUMP_POS.x + 130, pump_label_y + 36)
	bar_back.size = Vector2(120, 6)
	add_child(bar_back)
	_pump_bar = ColorRect.new()
	_pump_bar.color = AMBER
	_pump_bar.size = Vector2(120, 6)
	bar_back.add_child(_pump_bar)
	_pump_state = _label("", 9, TEAL_LIGHT)
	_pump_state.position = Vector2(PUMP_POS.x + 130, pump_label_y + 44)
	add_child(_pump_state)

	for unit_id: String in SPRITES:
		var spec: Dictionary = SPRITES[unit_id]
		var atlas := AtlasTexture.new()
		atlas.atlas = spec["texture"]
		atlas.region = spec["region"]
		var region: Rect2 = spec["region"]
		var sprite_size: Vector2 = region.size * float(spec["scale"])
		_sprite_nodes[unit_id] = _sprite(atlas, spec["pos"], sprite_size)
		var tag := _label("", 8, AMBER_LIGHT)
		tag.position = Vector2(spec["pos"]) + Vector2(sprite_size.x + 3, sprite_size.y * 0.5 - 6)
		add_child(tag)
		_tags[unit_id] = tag

	var message_panel := _panel(Rect2(6, 228, 628, 26), TEAL_DEEP)
	_message = _label("", 10, CREAM)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_panel.add_child(_message)

	var command_panel := _panel(Rect2(6, 258, 180, 98), AMBER)
	var command_box := VBoxContainer.new()
	command_box.add_theme_constant_override("separation", 1)
	command_panel.add_child(command_box)
	_menu_title = _label("", 9, TEAL_LIGHT)
	command_box.add_child(_menu_title)
	_menu_list = VBoxContainer.new()
	_menu_list.add_theme_constant_override("separation", 0)
	_menu_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	command_box.add_child(_menu_list)
	_menu_hint = _label("", 8, TEAL_LIGHT)
	command_box.add_child(_menu_hint)

	var side := _panel(Rect2(192, 258, 442, 98), TEAL)
	var side_box := VBoxContainer.new()
	side_box.add_theme_constant_override("separation", 2)
	side.add_child(side_box)
	for member_id in BattleModel.PARTY_IDS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		side_box.add_child(row)
		var name_label := _label("", 10, CREAM)
		name_label.custom_minimum_size = Vector2(56, 0)
		row.add_child(name_label)
		var back := ColorRect.new()
		back.color = INK
		back.custom_minimum_size = Vector2(90, 6)
		back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(back)
		var bar := ColorRect.new()
		bar.size = Vector2(90, 6)
		back.add_child(bar)
		var hp_label := _label("", 10, CREAM)
		hp_label.custom_minimum_size = Vector2(44, 0)
		row.add_child(hp_label)
		var state_label := _label("", 9, AMBER_LIGHT)
		row.add_child(state_label)
		_status_rows[member_id] = {"name": name_label, "bar": bar, "hp": hp_label, "state": state_label}
	_info = _label("", 9, TEAL_LIGHT)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.custom_minimum_size = Vector2(420, 0)
	side_box.add_child(_info)

	_result_panel = _panel(Rect2(150, 90, 340, 130), AMBER_LIGHT)
	var result_box := VBoxContainer.new()
	result_box.add_theme_constant_override("separation", 6)
	_result_panel.add_child(result_box)
	_result_title = _label("", 20, AMBER_LIGHT)
	_result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_box.add_child(_result_title)
	_result_body = _label("", 10, CREAM)
	_result_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_box.add_child(_result_body)
	_result_list = VBoxContainer.new()
	_result_list.alignment = BoxContainer.ALIGNMENT_CENTER
	result_box.add_child(_result_list)
	_result_panel.visible = false


func _panel(rect: Rect2, border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.custom_minimum_size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _box(Color(INK, 0.94), border, 1))
	add_child(panel)
	return panel


func _box(bg: Color, border: Color, width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(width)
	box.set_content_margin_all(4)
	return box


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _sprite(texture: Texture2D, pos: Vector2, sprite_size: Vector2) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.position = pos
	rect.size = sprite_size
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)
	return rect
