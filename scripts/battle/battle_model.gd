class_name BattleModel
extends RefCounted
## Rules for the seawall encounter, with no UI. Everything is deterministic (no
## random rolls), so the turn-order forecast is exact and tests can replay it.
##
## The harbor pump alternates Jet, Surge. After each Jet it is "charging": the
## Surge is next, so it is always on the visible turn order. Two ways through:
##   Guard  - a guarding unit takes a quarter damage until its next turn starts.
##   Breakwater - Tovan + Nell. Spends the user's turn now and the partner's next
##                turn, and resolves on that partner turn. If it resolves while the
##                pump is charging, the Surge is broken and the pump loses that turn.
## Mira's Rally moves one ally's next turn to directly after hers.

const BOSS_PATTERN: Array[String] = ["jet", "surge"]
const JET_DAMAGE: int = 9
const SURGE_DAMAGE: int = 24
const BREAKWATER_DAMAGE: int = 36
const MEND_AMOUNT: int = 16
const GUARD_DIVISOR: int = 4
const PARTNERS: Dictionary = {"tovan": "nell", "nell": "tovan"}
const PARTY_IDS: Array[String] = ["mira", "tovan", "nell", "pip"]

const MOVE_NAMES: Dictionary = {
	"jet": "Pressure Jet",
	"surge": "Surge",
	"staggered": "Staggered",
}

var units: Array[BattleUnit] = []
var now: float = 0.0
var turn_count: int = 0
## Index into BOSS_PATTERN for the pump's next action.
var boss_step: int = 0
## Set when Breakwater breaks a Surge: the pump's next turn is lost.
var staggered: bool = false
## {"initiator": id, "partner": id} while a Breakwater waits to resolve.
var pending_breakwater: Dictionary = {}
var surges_broken: int = 0
var surges_taken: int = 0
## Surges that landed while every standing party member was guarding.
var surges_guarded: int = 0

var _turn_open: bool = false


static func create() -> BattleModel:
	var model := BattleModel.new()
	model.units = [
		BattleUnit.make("mira", "Mira", 40, 8, 10.0, 0.0, 0),
		BattleUnit.make("tovan", "Tovan", 52, 10, 12.0, 2.0, 1),
		BattleUnit.make("pip", "Pip", 28, 5, 9.0, 4.0, 3),
		BattleUnit.make("pump", "Harbor Pump", 140, 0, 11.0, 6.0, 4, true),
		BattleUnit.make("nell", "Nell", 34, 6, 15.0, 9.0, 2),
	]
	return model


func clone() -> BattleModel:
	var copy := BattleModel.new()
	for unit in units:
		copy.units.append(unit.copy())
	copy.now = now
	copy.turn_count = turn_count
	copy.boss_step = boss_step
	copy.staggered = staggered
	copy.pending_breakwater = pending_breakwater.duplicate()
	copy.surges_broken = surges_broken
	copy.surges_taken = surges_taken
	copy.surges_guarded = surges_guarded
	copy._turn_open = _turn_open
	return copy


# --- Queries ---------------------------------------------------------------

func unit(unit_id: String) -> BattleUnit:
	for candidate in units:
		if candidate.id == unit_id:
			return candidate
	return null


func boss() -> BattleUnit:
	return unit("pump")


func party() -> Array[BattleUnit]:
	var members: Array[BattleUnit] = []
	for unit_id in PARTY_IDS:
		members.append(unit(unit_id))
	return members


func living_party() -> Array[BattleUnit]:
	var members: Array[BattleUnit] = []
	for member in party():
		if not member.is_down():
			members.append(member)
	return members


func is_won() -> bool:
	return boss().is_down()


func is_lost() -> bool:
	return living_party().is_empty()


func is_over() -> bool:
	return is_won() or is_lost()


## The unit whose turn it is (or is about to be).
func current() -> BattleUnit:
	var best: BattleUnit = null
	for candidate in units:
		if candidate.is_down():
			continue
		if best == null or candidate.next_time < best.next_time or (is_equal_approx(candidate.next_time, best.next_time) and candidate.order < best.order):
			best = candidate
	return best


func next_boss_move() -> String:
	if staggered:
		return "staggered"
	return BOSS_PATTERN[boss_step % BOSS_PATTERN.size()]


func is_charging() -> bool:
	return next_boss_move() == "surge"


## Turns that resolve without a menu: the pump, and the partner finishing Breakwater.
func is_auto_turn(actor: BattleUnit) -> bool:
	return actor.is_enemy or (not pending_breakwater.is_empty() and pending_breakwater["partner"] == actor.id)


func breakwater_partner(actor_id: String) -> String:
	return String(PARTNERS.get(actor_id, ""))


func can_breakwater(actor_id: String) -> bool:
	var partner_id: String = breakwater_partner(actor_id)
	return partner_id != "" and pending_breakwater.is_empty() and not unit(partner_id).is_down()


## Highest current HP takes the Jet; ties go to the earlier party slot.
func jet_target() -> BattleUnit:
	var target: BattleUnit = null
	for member in living_party():
		if target == null or member.hp > target.hp:
			target = member
	return target


## Upcoming turns starting with the current one. Each entry:
##   index, id, name, kind ("turn" | "jet" | "surge" | "staggered" | "breakwater"),
##   target (Jet only), breaks_surge (Breakwater only), charging (pump only).
func forecast(count: int) -> Array[Dictionary]:
	var times: Dictionary = {}
	for candidate in units:
		if not candidate.is_down():
			times[candidate.id] = candidate.next_time
	var sim_step: int = boss_step
	var sim_staggered: bool = staggered
	var sim_partner: String = String(pending_breakwater.get("partner", ""))
	var entries: Array[Dictionary] = []
	while entries.size() < count and not times.is_empty():
		var actor: BattleUnit = null
		for unit_id: String in times:
			var candidate: BattleUnit = unit(unit_id)
			if actor == null or times[unit_id] < times[actor.id] or (is_equal_approx(times[unit_id], times[actor.id]) and candidate.order < actor.order):
				actor = candidate
		var entry: Dictionary = {"index": entries.size(), "id": actor.id, "name": actor.display_name, "kind": "turn"}
		if actor.is_enemy:
			if sim_staggered:
				entry["kind"] = "staggered"
				sim_staggered = false
			else:
				entry["kind"] = BOSS_PATTERN[sim_step % BOSS_PATTERN.size()]
				sim_step += 1
				if entry["kind"] == "jet":
					var target: BattleUnit = jet_target()
					entry["target"] = target.display_name if target else ""
		elif actor.id == sim_partner:
			entry["kind"] = "breakwater"
			var breaks: bool = not sim_staggered and BOSS_PATTERN[sim_step % BOSS_PATTERN.size()] == "surge"
			entry["breaks_surge"] = breaks
			if breaks:
				sim_staggered = true
				sim_step += 1
			sim_partner = ""
		if actor.is_enemy:
			entry["charging"] = not sim_staggered and BOSS_PATTERN[sim_step % BOSS_PATTERN.size()] == "surge"
		entries.append(entry)
		times[actor.id] += actor.delay
	return entries


## What the timeline would look like if the current actor took `action` now.
## The current turn stays at index 0 so indices line up with forecast().
func preview(action: String, target_id: String = "", count: int = 10) -> Array[Dictionary]:
	var actor: BattleUnit = current()
	var head: Dictionary = {"index": 0, "id": actor.id, "name": actor.display_name, "kind": "turn"}
	if action == "breakwater":
		head["kind"] = "breakwater_start"
	var trial: BattleModel = clone()
	trial.start_turn()
	trial.act(action, target_id)
	var result: Array[Dictionary] = [head]
	for entry in trial.forecast(count - 1):
		entry["index"] = result.size()
		result.append(entry)
	return result


## Which two turns Breakwater spends, when it resolves, and whether it breaks a Surge.
func breakwater_plan(count: int = 10) -> Dictionary:
	var actor: BattleUnit = current()
	var plan: Dictionary = {
		"initiator": actor.display_name,
		"partner": unit(breakwater_partner(actor.id)).display_name,
		"spend": [0],
		"resolve_index": -1,
		"breaks_surge": false,
		"surge_index": -1,
	}
	for entry in forecast(count):
		if entry["kind"] == "surge" and int(plan["surge_index"]) == -1:
			plan["surge_index"] = entry["index"]
	var timeline: Array[Dictionary] = preview("breakwater", "", count)
	for entry in timeline:
		if entry["kind"] == "breakwater":
			plan["resolve_index"] = entry["index"]
			plan["breaks_surge"] = entry["breaks_surge"]
			(plan["spend"] as Array).append(entry["index"])
			break
	plan["timeline"] = timeline
	return plan


# --- Turn flow -------------------------------------------------------------

## Advances the clock to the current actor and ends its guard. Safe to call twice.
func start_turn() -> BattleUnit:
	var actor: BattleUnit = current()
	if actor == null:
		return null
	if not _turn_open:
		_turn_open = true
		now = actor.next_time
		actor.guarding = false
	return actor


## Runs a pump turn or a Breakwater resolution. Returns {"text": String}.
func run_auto_turn() -> Dictionary:
	var actor: BattleUnit = start_turn()
	var text: String = ""
	if actor.is_enemy:
		text = _boss_act()
	else:
		text = _resolve_breakwater(actor)
	_end_turn(actor)
	return {"text": text}


## Party commands: "attack", "guard", "mend" (target), "rally" (target), "breakwater".
func act(action: String, target_id: String = "") -> Dictionary:
	var actor: BattleUnit = start_turn()
	var text: String = ""
	match action:
		"attack":
			var hit: int = _hurt(boss(), actor.power)
			text = "%s strikes the pump for %d." % [actor.display_name, hit]
		"guard":
			actor.guarding = true
			text = "%s braces and guards." % actor.display_name
		"mend":
			var target: BattleUnit = unit(target_id)
			var healed: int = mini(MEND_AMOUNT, target.max_hp - target.hp)
			target.hp += healed
			text = "Pip mends %s for %d." % [target.display_name, healed]
		"rally":
			var target: BattleUnit = unit(target_id)
			_end_turn(actor)
			target.next_time = now + 0.001
			return {"text": "Mira signals %s to move now!" % target.display_name}
		"breakwater":
			var partner_id: String = breakwater_partner(actor.id)
			pending_breakwater = {"initiator": actor.id, "partner": partner_id}
			text = "%s sets the Breakwater. %s will finish it." % [actor.display_name, unit(partner_id).display_name]
		_:
			push_error("Unknown battle action '%s'" % action)
	_end_turn(actor)
	return {"text": text}


func _end_turn(actor: BattleUnit) -> void:
	actor.next_time = now + actor.delay
	turn_count += 1
	_turn_open = false


func _boss_act() -> String:
	if staggered:
		staggered = false
		return "The pump shudders, venting its broken Surge. It loses the turn."
	var move: String = BOSS_PATTERN[boss_step % BOSS_PATTERN.size()]
	boss_step += 1
	if move == "jet":
		var target: BattleUnit = jet_target()
		var hit: int = _hurt(target, JET_DAMAGE)
		var text: String = "Pressure Jet hits %s for %d." % [target.display_name, hit]
		if is_charging():
			text += " The pump starts charging a Surge!"
		return text
	surges_taken += 1
	var all_guarding: bool = true
	for member in living_party():
		all_guarding = all_guarding and member.guarding
	if all_guarding:
		surges_guarded += 1
	var parts: Array[String] = []
	for member in living_party():
		parts.append("%s %d" % [member.display_name, _hurt(member, SURGE_DAMAGE)])
	return "SURGE! Seawater floods the wall: %s." % ", ".join(parts)


func _resolve_breakwater(actor: BattleUnit) -> String:
	var initiator: BattleUnit = unit(String(pending_breakwater["initiator"]))
	pending_breakwater = {}
	var hit: int = _hurt(boss(), BREAKWATER_DAMAGE)
	var text: String = "BREAKWATER! %s and %s slam the gate shut: %d damage." % [initiator.display_name, actor.display_name, hit]
	if not boss().is_down() and is_charging():
		staggered = true
		boss_step += 1
		surges_broken += 1
		text += " The Surge is broken!"
	return text


func _hurt(target: BattleUnit, amount: int) -> int:
	var dealt: int = amount
	if target.guarding:
		dealt = ceili(float(amount) / GUARD_DIVISOR)
	dealt = mini(dealt, target.hp)
	target.hp -= dealt
	if target.is_down():
		target.guarding = false
		if not pending_breakwater.is_empty() and pending_breakwater["partner"] == target.id:
			pending_breakwater = {}
	return dealt
