extends Node
## Autoload that owns the game's input bindings and remembers whether the player
## last used a keyboard or a gamepad, so prompts show the button they will press.
##
## Bindings live here (not only in Project Settings) so they are readable in one
## place and guaranteed to exist when the scene starts.

signal device_changed(uses_gamepad: bool)

const STICK_THRESHOLD: float = 0.5
const DEADZONE: float = 0.25

const KEY_BINDINGS: Dictionary = {
	"move_up": [KEY_UP, KEY_W],
	"move_down": [KEY_DOWN, KEY_S],
	"move_left": [KEY_LEFT, KEY_A],
	"move_right": [KEY_RIGHT, KEY_D],
	"interact": [KEY_E, KEY_ENTER, KEY_KP_ENTER],
	"cancel": [KEY_ESCAPE, KEY_BACKSPACE],
}

const BUTTON_BINDINGS: Dictionary = {
	"move_up": [JOY_BUTTON_DPAD_UP],
	"move_down": [JOY_BUTTON_DPAD_DOWN],
	"move_left": [JOY_BUTTON_DPAD_LEFT],
	"move_right": [JOY_BUTTON_DPAD_RIGHT],
	"interact": [JOY_BUTTON_A],
	"cancel": [JOY_BUTTON_B],
}

## Action name -> [axis, direction].
const STICK_BINDINGS: Dictionary = {
	"move_up": [JOY_AXIS_LEFT_Y, -1.0],
	"move_down": [JOY_AXIS_LEFT_Y, 1.0],
	"move_left": [JOY_AXIS_LEFT_X, -1.0],
	"move_right": [JOY_AXIS_LEFT_X, 1.0],
}

var uses_gamepad: bool = false


func _enter_tree() -> void:
	_register_actions()


func _input(event: InputEvent) -> void:
	var from_gamepad: bool = event is InputEventJoypadButton
	if event is InputEventJoypadMotion:
		from_gamepad = absf((event as InputEventJoypadMotion).axis_value) > STICK_THRESHOLD
	var from_keyboard: bool = event is InputEventKey or event is InputEventMouseButton

	if from_gamepad and not uses_gamepad:
		uses_gamepad = true
		device_changed.emit(true)
	elif from_keyboard and uses_gamepad:
		uses_gamepad = false
		device_changed.emit(false)


func interact_label() -> String:
	return "(A)" if uses_gamepad else "E"


func cancel_label() -> String:
	return "(B)" if uses_gamepad else "Esc"


func move_label() -> String:
	return "Stick / D-pad" if uses_gamepad else "WASD / Arrows"


func _register_actions() -> void:
	for action: String in KEY_BINDINGS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action, DEADZONE)
		for keycode: Key in KEY_BINDINGS[action]:
			var key := InputEventKey.new()
			key.physical_keycode = keycode
			InputMap.action_add_event(action, key)
		for button: JoyButton in BUTTON_BINDINGS.get(action, []):
			var pad := InputEventJoypadButton.new()
			pad.button_index = button
			InputMap.action_add_event(action, pad)
		if STICK_BINDINGS.has(action):
			var stick := InputEventJoypadMotion.new()
			stick.axis = STICK_BINDINGS[action][0]
			stick.axis_value = STICK_BINDINGS[action][1]
			InputMap.action_add_event(action, stick)
