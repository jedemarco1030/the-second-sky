class_name Hud
extends CanvasLayer
## Objective tracker, control reminder, and the opening title card.

const FLASH_COLOR: Color = Color("ffd48a")

@onready var _objective_panel: Control = $Objective
@onready var _objective_text: Label = $Objective/VBox/Text
@onready var _controls: Label = $Controls
@onready var _title: Control = $Title
@onready var _fade: ColorRect = $Fade


func _ready() -> void:
	InputHints.device_changed.connect(_on_device_changed)
	_refresh_controls()
	_play_intro()


func set_objective(text: String) -> void:
	if _objective_text.text == text:
		return
	_objective_text.text = text
	_objective_panel.modulate = FLASH_COLOR
	var tween := create_tween()
	tween.tween_property(_objective_panel, "modulate", Color.WHITE, 0.6)


func objective() -> String:
	return _objective_text.text


func _play_intro() -> void:
	_fade.visible = true
	_fade.modulate.a = 1.0
	var fade := create_tween()
	fade.tween_property(_fade, "modulate:a", 0.0, 0.9)
	fade.tween_callback(_fade.hide)

	_title.modulate.a = 0.0
	var title := create_tween()
	title.tween_interval(0.3)
	title.tween_property(_title, "modulate:a", 1.0, 0.6)
	title.tween_interval(1.6)
	title.tween_property(_title, "modulate:a", 0.0, 0.8)
	title.tween_callback(_title.hide)


func _refresh_controls() -> void:
	_controls.text = "%s  Move     %s  Talk     %s  Close" % [
		InputHints.move_label(), "(A)" if InputHints.uses_gamepad else "E / Enter", InputHints.cancel_label(),
	]


func _on_device_changed(_uses_gamepad: bool) -> void:
	_refresh_controls()
