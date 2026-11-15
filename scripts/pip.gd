class_name Pip
extends Node2D
## Pip the lantern moth drifts behind Mira's shoulder and lights her way.

const SHOULDER_OFFSET: Vector2 = Vector2(-12.0, -26.0)
const FOLLOW_SHARPNESS: float = 4.0
const GLOW_OUTER: Color = Color(1.0, 0.83, 0.54, 0.16)
const GLOW_INNER: Color = Color(1.0, 0.83, 0.54, 0.28)

var _target: Node2D = null
var _time: float = 0.0

@onready var _sprite: Sprite2D = $Sprite


func follow(target: Node2D) -> void:
	_target = target
	global_position = target.global_position + SHOULDER_OFFSET


func _process(delta: float) -> void:
	_time += delta
	if _target != null:
		var hover := Vector2(sin(_time * 1.3) * 4.0, sin(_time * 2.6) * 2.0)
		var goal: Vector2 = _target.global_position + SHOULDER_OFFSET + hover
		global_position = global_position.lerp(goal, 1.0 - exp(-FOLLOW_SHARPNESS * delta))
	_sprite.frame = int(_time * 10.0) % 2
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 8.0, GLOW_OUTER)
	draw_circle(Vector2.ZERO, 4.0, GLOW_INNER)
