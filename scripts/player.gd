class_name Player
extends CharacterBody2D
## Mira: top-down movement, four-way walking animation, and interaction focus.

const ROW_DOWN: int = 0
const ROW_UP: int = 1
const ROW_SIDE: int = 2
const FRAMES_PER_ROW: int = 3
const WALK_FPS: float = 8.0

@export var speed: float = 90.0

## While locked (for example during dialogue) Mira ignores movement and interaction.
var input_locked: bool = false:
	set(value):
		input_locked = value
		if value:
			velocity = Vector2.ZERO
		_refresh_focus()

var _facing_row: int = ROW_DOWN
var _walk_time: float = 0.0
var _nearby: Array[Interactable] = []
var _focused: Interactable = null

@onready var _sprite: Sprite2D = $Sprite


func _physics_process(delta: float) -> void:
	var direction: Vector2 = Vector2.ZERO
	if not input_locked:
		direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()
	_animate(direction, delta)
	_refresh_focus()


func _unhandled_input(event: InputEvent) -> void:
	if input_locked or _focused == null:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_focused.activate(self)


func add_interactable(interactable: Interactable) -> void:
	if not _nearby.has(interactable):
		_nearby.append(interactable)
	_refresh_focus()


func remove_interactable(interactable: Interactable) -> void:
	_nearby.erase(interactable)
	_refresh_focus()


func focused_interactable() -> Interactable:
	return _focused


func face_toward(point: Vector2) -> void:
	var delta: Vector2 = point - global_position
	if absf(delta.x) > absf(delta.y):
		_facing_row = ROW_SIDE
		_sprite.flip_h = delta.x < 0.0
	else:
		_facing_row = ROW_UP if delta.y < 0.0 else ROW_DOWN
		_sprite.flip_h = false
	_sprite.frame = _facing_row * FRAMES_PER_ROW


func _animate(direction: Vector2, delta: float) -> void:
	if direction.length_squared() < 0.01:
		_walk_time = 0.0
		_sprite.frame = _facing_row * FRAMES_PER_ROW
		return
	if absf(direction.x) > absf(direction.y):
		_facing_row = ROW_SIDE
		_sprite.flip_h = direction.x < 0.0
	else:
		_facing_row = ROW_UP if direction.y < 0.0 else ROW_DOWN
		_sprite.flip_h = false
	_walk_time += delta
	var step: int = 1 + int(_walk_time * WALK_FPS) % 2
	_sprite.frame = _facing_row * FRAMES_PER_ROW + step


func _refresh_focus() -> void:
	var best: Interactable = null
	if not input_locked:
		var best_distance: float = INF
		for candidate in _nearby:
			if not is_instance_valid(candidate):
				continue
			var distance: float = global_position.distance_squared_to(candidate.global_position)
			if distance < best_distance:
				best_distance = distance
				best = candidate
	if best == _focused:
		return
	if _focused != null and is_instance_valid(_focused):
		_focused.set_focused(false)
	_focused = best
	if _focused != null:
		_focused.set_focused(true)
