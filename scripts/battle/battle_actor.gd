class_name BattleActor
extends Node2D
## One combatant on the seawall stage. The node's origin is where the feet touch
## the deck; Body holds the sprite so effects can move it without moving the
## contact shadow. Every effect is a short fire-and-forget tween: nothing here
## blocks input or changes when turns happen.

const ACTIVE_SHADOW := Color(1.0, 0.72, 0.36, 1.0)
const PREVIEW_SHADOW := Color(1.0, 0.86, 0.55, 1.0)
const GUARD_TINT := Color(0.78, 0.9, 1.0)

@export var unit_id: String = ""
## +1 when the sprite faces right (party), -1 when it faces left (pump).
@export var facing: float = 1.0
## Pixels of idle bobbing for flyers such as Pip.
@export var hover: float = 0.0
## How far above the feet the name tag sits.
@export var head_height: float = 80.0

@onready var body: Node2D = $Body
@onready var sprite: Sprite2D = $Body/Sprite
@onready var shadow: Sprite2D = $Shadow
@onready var guard_glow: Sprite2D = get_node_or_null("GuardGlow")

var active: bool = false
var previewed: bool = false
var guarding: bool = false
var down: bool = false

var _base_body: Vector2
var _shadow_color: Color
var _time: float = 0.0
var _move_tween: Tween
var _flash_tween: Tween


func _ready() -> void:
	_base_body = body.position
	_shadow_color = shadow.modulate
	if guard_glow != null:
		guard_glow.visible = false


func _process(delta: float) -> void:
	_time += delta
	if hover > 0.0 and not down:
		body.position.y = _base_body.y + roundf(sin(_time * 2.6) * hover)


func head_position() -> Vector2:
	return global_position + Vector2(0, -head_height)


func reset_visuals() -> void:
	_kill_tweens()
	body.position = _base_body
	body.rotation = 0.0
	sprite.modulate = Color.WHITE
	active = false
	previewed = false
	set_state(false, false)


func set_state(is_guarding: bool, is_down: bool) -> void:
	guarding = is_guarding
	down = is_down
	if guard_glow != null:
		guard_glow.visible = guarding and not down
	if down:
		body.position.y = _base_body.y + (hover if hover > 0.0 else 0.0)
	_apply_tint()
	_apply_shadow()


func set_active(value: bool) -> void:
	active = value
	_apply_shadow()


func set_previewed(value: bool) -> void:
	previewed = value
	_apply_shadow()


func _apply_tint() -> void:
	if _flash_tween != null and _flash_tween.is_running():
		return
	sprite.modulate = _rest_tint()


func _rest_tint() -> Color:
	if down:
		return Color(0.45, 0.5, 0.62, 0.55)
	if guarding:
		return GUARD_TINT
	return Color.WHITE


func _apply_shadow() -> void:
	var color: Color = _shadow_color
	if previewed:
		color = Color(PREVIEW_SHADOW, 0.95)
	elif active and not down:
		color = Color(ACTIVE_SHADOW, 0.85)
	shadow.modulate = color


# --- Effects ---------------------------------------------------------------

## Step toward the enemy and back.
func lunge(distance: float = 10.0) -> void:
	_restart_move()
	_move_tween.tween_property(body, "position:x", _base_body.x + facing * distance, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_move_tween.tween_property(body, "position:x", _base_body.x, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)


## Push back from the enemy, used by the pump when it fires.
func recoil(distance: float = 4.0) -> void:
	_restart_move()
	_move_tween.tween_property(body, "position:x", _base_body.x - facing * distance, 0.06)
	_move_tween.tween_property(body, "position:x", _base_body.x, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Short hop for Rally / Mend recipients.
func hop() -> void:
	_restart_move()
	var base_y: float = body.position.y
	_move_tween.tween_property(body, "position:y", base_y - 5.0, 0.08).set_ease(Tween.EASE_OUT)
	_move_tween.tween_property(body, "position:y", base_y, 0.12).set_ease(Tween.EASE_IN)


## Horizontal shake plus a bright flash: the actor was hit.
func hit(strength: float = 2.0) -> void:
	_restart_move()
	for i in 4:
		var side: float = strength if i % 2 == 0 else -strength
		_move_tween.tween_property(body, "position:x", _base_body.x + side, 0.04)
	_move_tween.tween_property(body, "position:x", _base_body.x, 0.04)
	flash(Color(2.2, 2.2, 2.2, 1.0), 0.22)


## Slow side-to-side wobble: the pump venting a broken Surge.
func wobble() -> void:
	_restart_move()
	_move_tween.tween_property(body, "rotation", deg_to_rad(2.5), 0.1)
	_move_tween.tween_property(body, "rotation", deg_to_rad(-2.0), 0.14)
	_move_tween.tween_property(body, "rotation", 0.0, 0.12)


func flash(color: Color, duration: float) -> void:
	if _flash_tween != null:
		_flash_tween.kill()
	sprite.modulate = color
	_flash_tween = create_tween()
	_flash_tween.tween_property(sprite, "modulate", _rest_tint(), duration)


## A quick cool pulse on the guard glow when the guard goes up.
func guard_pulse() -> void:
	flash(Color(1.5, 1.8, 2.2, 1.0), 0.3)
	if guard_glow == null:
		return
	guard_glow.visible = true
	var base_scale: Vector2 = guard_glow.scale
	guard_glow.scale = base_scale * 0.6
	var tween := create_tween()
	tween.tween_property(guard_glow, "scale", base_scale, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _restart_move() -> void:
	if _move_tween != null:
		_move_tween.kill()
	body.position.x = _base_body.x
	body.rotation = 0.0
	_move_tween = create_tween()


func _kill_tweens() -> void:
	if _move_tween != null:
		_move_tween.kill()
	if _flash_tween != null:
		_flash_tween.kill()
