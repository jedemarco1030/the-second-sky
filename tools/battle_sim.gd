extends SceneTree
## Plays the seawall battle with scripted policies against the real rules and
## prints the outcome. Used to balance numbers; no UI or autoloads involved.
##   godot --headless --path . --script res://tools/battle_sim.gd

const MAX_TURNS: int = 200


func _initialize() -> void:
	var model := BattleModel.create()
	print("Opening timeline:")
	for entry in model.forecast(12):
		print("  #%d %s %s" % [entry["index"], entry["name"], entry["kind"]])
	for policy in ["attack", "guard", "breakwater"]:
		var result: Dictionary = play(policy, true)
		print("%-10s -> %s in %d turns  (party HP %s, surges taken %d, broken %d, farthest surge slot %d)" % [
			policy, result["outcome"], result["turns"], result["hp"], result["taken"], result["broken"], result["farthest_surge"]])
	quit()


static func play(policy: String, verbose: bool = false) -> Dictionary:
	var model := BattleModel.create()
	var farthest_surge: int = 0
	while not model.is_over() and model.turn_count < MAX_TURNS:
		var actor: BattleUnit = model.start_turn()
		var ahead: Array[Dictionary] = model.forecast(20)
		var surge_at: int = _first(ahead, "surge")
		if not model.staggered and _first(ahead, "staggered") == -1:
			farthest_surge = maxi(farthest_surge, surge_at)
		var event: Dictionary
		if model.is_auto_turn(actor):
			event = model.run_auto_turn()
		else:
			var choice: Array = choose(model, actor, policy)
			event = model.act(choice[0], choice[1])
		if verbose and policy != "attack":
			print("    [%s] %s" % [policy, event["text"]])
	var hp: Array[String] = []
	for member in model.party():
		hp.append("%s %d" % [member.display_name, member.hp])
	return {
		"outcome": "WIN" if model.is_won() else ("LOSS" if model.is_lost() else "TIMEOUT"),
		"turns": model.turn_count,
		"hp": ", ".join(hp),
		"taken": model.surges_taken,
		"broken": model.surges_broken,
		"farthest_surge": farthest_surge,
	}


## Returns [action, target_id].
static func choose(model: BattleModel, actor: BattleUnit, policy: String) -> Array:
	if policy == "attack":
		return ["attack", ""]
	var timeline: Array[Dictionary] = model.forecast(12)
	var surge_index: int = _first(timeline, "surge")
	var my_next: int = _next_turn_of(timeline, actor.id)
	var surge_before_my_next: bool = surge_index != -1 and (my_next == -1 or surge_index < my_next)

	if policy == "breakwater":
		var pending: Dictionary = model.pending_breakwater
		if not pending.is_empty() and actor.id == "mira" and model.is_charging():
			var resolve: int = _first(timeline, "breakwater")
			if resolve == -1 or resolve > surge_index:
				return ["rally", pending["partner"]]
		if model.can_breakwater(actor.id):
			var plan: Dictionary = model.breakwater_plan()
			var mira_window: bool = _mira_acts_while_charging(timeline)
			if plan["breaks_surge"] or (surge_index != -1 and mira_window and int(plan["resolve_index"]) > surge_index):
				return ["breakwater", ""]
		var resolve_ahead: int = _first(timeline, "breakwater")
		var will_break: bool = resolve_ahead != -1 and resolve_ahead < surge_index
		if surge_before_my_next and not will_break and not (actor.id == "mira" and not pending.is_empty()):
			return ["guard", ""]
	elif surge_before_my_next:
		return ["guard", ""]

	if actor.id == "pip":
		var hurt: BattleUnit = _most_hurt(model)
		if hurt and float(hurt.hp) / hurt.max_hp < 0.5:
			return ["mend", hurt.id]
	return ["attack", ""]


static func _first(timeline: Array[Dictionary], kind: String) -> int:
	for entry in timeline:
		if entry["kind"] == kind:
			return entry["index"]
	return -1


static func _next_turn_of(timeline: Array[Dictionary], unit_id: String) -> int:
	for entry in timeline:
		if entry["index"] > 0 and entry["id"] == unit_id:
			return entry["index"]
	return -1


static func _mira_acts_while_charging(timeline: Array[Dictionary]) -> bool:
	var charging: bool = false
	for entry in timeline:
		if entry["kind"] == "jet" and entry.get("charging", false):
			charging = true
		elif entry["kind"] == "surge":
			return false
		elif charging and entry["id"] == "mira":
			return true
	return false


static func _most_hurt(model: BattleModel) -> BattleUnit:
	var worst: BattleUnit = null
	for member in model.living_party():
		if worst == null or float(member.hp) / member.max_hp < float(worst.hp) / worst.max_hp:
			worst = member
	return worst
