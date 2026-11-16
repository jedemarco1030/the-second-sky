class_name BattleStage
extends CanvasLayer
## The seawall scenery and combatants (scenes/battle/seawall_stage.tscn). It
## draws below the battle menus on its own canvas layer, so its moonlight
## CanvasModulate and lantern lights never tint the UI. SeawallBattle calls
## sync() after every state change and play_*() after every action; effects are
## short tweens and one-shot particles that never gate input or turn order.

@onready var _field: Node2D = $Field
@onready var _pump: PumpActor = $Field/Pump
@onready var _splash: CPUParticles2D = $Effects/Splash
@onready var _wave: CPUParticles2D = $Effects/Wave
@onready var _sparks: CPUParticles2D = $Effects/Sparks
@onready var _flash: ColorRect = $Flash

var _actors: Dictionary = {}
var _flash_tween: Tween


func _ready() -> void:
	for child in _field.get_children():
		if child is BattleActor:
			_actors[(child as BattleActor).unit_id] = child
	_flash.color.a = 0.0


func actor(unit_id: String) -> BattleActor:
	return _actors.get(unit_id)


func head_position(unit_id: String) -> Vector2:
	var node: BattleActor = actor(unit_id)
	return node.head_position() if node != null else Vector2.ZERO


func reset() -> void:
	for node: BattleActor in _actors.values():
		node.reset_visuals()
	_flash.color.a = 0.0


## Mirrors the model: KO and guard tints, whose turn it is, and the pump's charge.
func sync(model: BattleModel, preview_ids: Array = []) -> void:
	var current: BattleUnit = null if model.is_over() else model.current()
	for unit_id: String in _actors:
		var member: BattleUnit = model.unit(unit_id)
		var node: BattleActor = _actors[unit_id]
		node.set_state(member.guarding, member.is_down())
		node.set_active(current == member)
		node.set_previewed(preview_ids.has(unit_id))
	var pump: BattleUnit = model.boss()
	if pump.is_down():
		_pump.set_charge_state("down")
	elif model.staggered:
		_pump.set_charge_state("staggered")
	elif model.is_charging():
		_pump.set_charge_state("charging")
	else:
		_pump.set_charge_state("idle")


# --- Action feedback -------------------------------------------------------

func play_strike(attacker_id: String) -> void:
	actor(attacker_id).lunge()
	_pump.hit(1.5)
	_burst(_sparks, _pump.global_position + Vector2(-40, -70))


func play_guard(unit_id: String) -> void:
	actor(unit_id).guard_pulse()


func play_support(target_id: String) -> void:
	actor(target_id).hop()


func play_breakwater_set(initiator_id: String) -> void:
	actor(initiator_id).flash(Color(1.8, 1.5, 1.0, 1.0), 0.3)


func play_breakwater(initiator_id: String, partner_id: String) -> void:
	for unit_id in [initiator_id, partner_id]:
		var node: BattleActor = actor(unit_id)
		if node != null:
			node.lunge(16.0)
	_pump.hit(3.0)
	_burst(_splash, _pump.global_position + Vector2(-30, -60))
	_screen_flash(Color(1.0, 0.85, 0.6), 0.18)


func play_jet(target_id: String) -> void:
	_pump.recoil()
	var node: BattleActor = actor(target_id)
	if node == null:
		return
	node.hit()
	_burst(_splash, node.global_position + Vector2(0, -node.head_height * 0.5))


func play_surge(hit_ids: Array) -> void:
	_pump.recoil(6.0)
	_burst(_wave, _wave.position)
	for unit_id: String in hit_ids:
		actor(unit_id).hit(2.0)
	_screen_flash(Color(0.75, 0.95, 1.0), 0.26)


func play_stagger() -> void:
	_pump.wobble()
	_burst(_sparks, _pump.global_position + Vector2(10, -120))


func _burst(particles: CPUParticles2D, at: Vector2) -> void:
	particles.global_position = at
	particles.restart()


func _screen_flash(color: Color, alpha: float) -> void:
	if _flash_tween != null:
		_flash_tween.kill()
	_flash.color = Color(color, alpha)
	_flash_tween = create_tween()
	_flash_tween.tween_property(_flash, "color:a", 0.0, 0.3)
