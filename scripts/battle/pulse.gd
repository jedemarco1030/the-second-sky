extends Node2D
## Gently pulses a glow sprite's alpha or a light's energy. Purely cosmetic.

@export var speed: float = 2.0
@export var low: float = 0.6
@export var high: float = 1.0
## Adds a fast irregular flicker on top, for lantern flames.
@export var flicker: float = 0.0
@export var phase: float = 0.0

var _time: float = 0.0
var _base_energy: float = 1.0
var _light: PointLight2D


func _ready() -> void:
	_time = phase
	var node: Node = self
	_light = node as PointLight2D
	if _light != null:
		_base_energy = _light.energy


func _process(delta: float) -> void:
	_time += delta
	var amount: float = lerpf(low, high, 0.5 + 0.5 * sin(_time * speed))
	amount += flicker * sin(_time * 17.0) * sin(_time * 7.3)
	if _light != null:
		_light.energy = _base_energy * amount
	else:
		modulate.a = clampf(amount, 0.0, 1.0)
