class_name DialogueBox
extends CanvasLayer
## Bottom-of-screen dialogue with a typewriter reveal.
## Interact reveals the whole line, then advances. Cancel closes immediately.

signal finished

const CHARACTERS_PER_SECOND: float = 48.0
const SPEAKER_COLORS: Dictionary = {
	"Radio": Color("5fb3a8"),
}
const DEFAULT_SPEAKER_COLOR: Color = Color("ffd48a")

var is_open: bool = false

var _lines: Array[Dictionary] = []
var _index: int = 0
var _revealed: float = 0.0

@onready var _panel: Control = $Panel
@onready var _speaker: Label = $Panel/VBox/Speaker
@onready var _body: Label = $Panel/VBox/Body
@onready var _hint: Label = $Panel/VBox/Hint


func _ready() -> void:
	_panel.visible = false
	InputHints.device_changed.connect(_on_device_changed)


func open(lines: Array[Dictionary]) -> void:
	if lines.is_empty():
		finished.emit()
		return
	_lines = lines
	_index = 0
	is_open = true
	_panel.visible = true
	_show_line()


func is_typing() -> bool:
	return _body.visible_characters >= 0 and _body.visible_characters < _body.get_total_character_count()


func _process(delta: float) -> void:
	if not is_open or not is_typing():
		return
	_revealed += delta * CHARACTERS_PER_SECOND
	_body.visible_characters = mini(int(_revealed), _body.get_total_character_count())
	if not is_typing():
		_refresh_hint()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_advance()
	elif event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		_close()


func _advance() -> void:
	if is_typing():
		_body.visible_characters = -1
		_refresh_hint()
		return
	_index += 1
	if _index >= _lines.size():
		_close()
	else:
		_show_line()


func _show_line() -> void:
	var line: Dictionary = _lines[_index]
	var speaker: String = String(line.get("speaker", ""))
	_speaker.text = speaker.to_upper()
	_speaker.add_theme_color_override("font_color", SPEAKER_COLORS.get(speaker, DEFAULT_SPEAKER_COLOR))
	_body.text = String(line.get("text", ""))
	_revealed = 0.0
	_body.visible_characters = 0
	_refresh_hint()


func _close() -> void:
	is_open = false
	_panel.visible = false
	_lines = []
	finished.emit()


func _refresh_hint() -> void:
	var is_last: bool = _index >= _lines.size() - 1
	var verb: String = "Skip" if is_typing() else ("Close" if is_last else "Next")
	_hint.text = "%s  %s      %s  Close" % [InputHints.interact_label(), verb, InputHints.cancel_label()]


func _on_device_changed(_uses_gamepad: bool) -> void:
	if is_open:
		_refresh_hint()
