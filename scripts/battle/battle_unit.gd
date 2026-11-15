class_name BattleUnit
extends RefCounted
## One combatant. Time-based initiative: a unit acts when the battle clock reaches
## next_time, then waits `delay` ticks before its next turn. Lower delay = more turns.

var id: String = ""
var display_name: String = ""
var max_hp: int = 1
var hp: int = 1
var power: int = 0
var delay: float = 10.0
var next_time: float = 0.0
## Breaks ties when two units are due at the same moment. Lower acts first.
var order: int = 0
var is_enemy: bool = false
## Guarding lasts until this unit's next turn starts.
var guarding: bool = false


static func make(unit_id: String, unit_name: String, hit_points: int, attack: int, turn_delay: float, first_turn: float, tie_order: int, enemy: bool = false) -> BattleUnit:
	var unit := BattleUnit.new()
	unit.id = unit_id
	unit.display_name = unit_name
	unit.max_hp = hit_points
	unit.hp = hit_points
	unit.power = attack
	unit.delay = turn_delay
	unit.next_time = first_turn
	unit.order = tie_order
	unit.is_enemy = enemy
	return unit


func is_down() -> bool:
	return hp <= 0


func copy() -> BattleUnit:
	var unit := BattleUnit.new()
	unit.id = id
	unit.display_name = display_name
	unit.max_hp = max_hp
	unit.hp = hp
	unit.power = power
	unit.delay = delay
	unit.next_time = next_time
	unit.order = order
	unit.is_enemy = is_enemy
	unit.guarding = guarding
	return unit
