class_name Npc
extends StaticBody2D
## A standing character who asks the scene to start a conversation when activated.

signal talk_requested(npc: Npc)

const IDLE_FRAME_SECONDS: float = 0.6

@export var display_name: String = "Nell"

var _time: float = 0.0

@onready var _sprite: Sprite2D = $Sprite
@onready var _interactable: Interactable = $Interactable


func _ready() -> void:
	_interactable.activated.connect(_on_activated)


func _process(delta: float) -> void:
	_time += delta
	_sprite.frame = int(_time / IDLE_FRAME_SECONDS) % _sprite.hframes


func interactable() -> Interactable:
	return _interactable


func _on_activated(_by: Node) -> void:
	talk_requested.emit(self)
