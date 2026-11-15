class_name Interactable
extends Area2D
## A zone Mira can interact with. Shows a floating button prompt while focused.

signal activated(by: Node)

@export var action_text: String = "Talk"

var _focused: bool = false
var _time: float = 0.0
var _prompt_base_y: float = 0.0

@onready var _prompt: Control = $Prompt
@onready var _prompt_label: Label = $Prompt/Label


func _ready() -> void:
	_prompt.visible = false
	_prompt_base_y = _prompt.position.y
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	InputHints.device_changed.connect(_on_device_changed)
	_refresh_label()


func _process(delta: float) -> void:
	if not _focused:
		return
	_time += delta
	_prompt.position.y = _prompt_base_y + round(sin(_time * 4.0) * 1.5)


func set_focused(focused: bool) -> void:
	_focused = focused
	_prompt.visible = focused
	_time = 0.0
	_prompt.position.y = _prompt_base_y


func is_focused() -> bool:
	return _focused


func activate(by: Node) -> void:
	activated.emit(by)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		(body as Player).add_interactable(self)


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		(body as Player).remove_interactable(self)


func _on_device_changed(_uses_gamepad: bool) -> void:
	_refresh_label()


func _refresh_label() -> void:
	_prompt_label.text = "%s  %s" % [InputHints.interact_label(), action_text]
