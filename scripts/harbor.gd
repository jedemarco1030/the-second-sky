extends Node2D
## Harbor walk: Mira starts at the top of the harbor stairs, walks down to the
## waterfront, and finds Nell picking up a distress call from Gull Point Light.
## After that, Tovan at the west seawall leads the party into the pump encounter.

const FIRST_TALK: Array[Dictionary] = [
	{"speaker": "Nell", "text": "Mira! Mind the cable. I finally got the harbor band to stop hissing."},
	{"speaker": "Radio", "text": "...this is Gull Point Light... lamp is failing... the water is rising where it shouldn't..."},
	{"speaker": "Mira", "text": "Gull Point? That lighthouse has been dark since the moon cracked."},
	{"speaker": "Nell", "text": "That's what I thought. But the signal isn't coming from the point. It's coming from under the tide line."},
	{"speaker": "Nell", "text": "Something out there just came back up. Get Tovan. At first light, we go and look."},
]

const REPEAT_TALK: Array[Dictionary] = [
	{"speaker": "Nell", "text": "Still repeating. Same three words, over and over: lamp, failing, rising."},
	{"speaker": "Nell", "text": "Tovan knows the old seawall better than anyone. Tell him the light is calling."},
]

const TOVAN_EARLY: Array[Dictionary] = [
	{"speaker": "Tovan", "text": "Evening, Mira. Seawall's shut after dark. Pump's been coughing all week."},
	{"speaker": "Tovan", "text": "Nell was waving at me from the pier. Go see what's got her ears buzzing."},
]

const TOVAN_ENCOUNTER: Array[Dictionary] = [
	{"speaker": "Tovan", "text": "Gull Point, calling again? Then that pump picked a bad night to run wild."},
	{"speaker": "Tovan", "text": "It's flooding the seawall walk. Nobody reaches the point until it's stopped."},
	{"speaker": "Tovan", "text": "Watch its gauge. When it charges a Surge, we brace together or slam the gate on it first."},
]

const TOVAN_AFTER: Array[Dictionary] = [
	{"speaker": "Tovan", "text": "Quiet as a church now. Rest up. At first light, we walk the wall to Gull Point."},
]

const OBJECTIVE_START: String = "Take the stairs down to the waterfront."
const OBJECTIVE_FIND_NELL: String = "Find Nell by the pier. Her radio is crackling."
const OBJECTIVE_SEAWALL: String = "Find Tovan at the west seawall."
const OBJECTIVE_DONE: String = "The seawall pump is quiet. Gull Point awaits at first light."

var talked_to_nell: bool = false
var reached_waterfront: bool = false

var _after_dialogue: Callable = Callable()

@onready var _map: HarborMap = $HarborMap
@onready var _player: Player = $World/Player
@onready var _camera: Camera2D = $World/Player/Camera
@onready var _nell: Npc = $World/Nell
@onready var _tovan: Npc = $World/Tovan
@onready var _pip: Pip = $World/Pip
@onready var _dialogue: DialogueBox = $DialogueBox
@onready var _hud: Hud = $HUD


func _ready() -> void:
	talked_to_nell = GameState.talked_to_nell
	_nell.global_position = _map.find_marker("N")
	_tovan.global_position = _map.find_marker("T")
	if GameState.returning_from_seawall:
		GameState.returning_from_seawall = false
		reached_waterfront = true
		_player.global_position = _tovan.global_position + Vector2(HarborMap.TILE * 1.5, 0)
		_player.face_toward(_tovan.global_position)
	else:
		_player.global_position = _map.find_marker("S")
	_pip.follow(_player)

	var bounds: Vector2i = _map.size_px()
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = bounds.x
	_camera.limit_bottom = bounds.y
	_camera.reset_smoothing.call_deferred()

	_nell.talk_requested.connect(_on_nell_talk_requested)
	_tovan.talk_requested.connect(_on_tovan_talk_requested)
	_dialogue.finished.connect(_on_dialogue_finished)
	_hud.set_objective(_current_objective())


func _current_objective() -> String:
	if GameState.seawall_cleared:
		return OBJECTIVE_DONE
	if talked_to_nell:
		return OBJECTIVE_SEAWALL
	return OBJECTIVE_FIND_NELL if reached_waterfront else OBJECTIVE_START


func _process(_delta: float) -> void:
	if reached_waterfront:
		return
	if _player.global_position.y > HarborMap.WATERFRONT_ROW * HarborMap.TILE:
		reached_waterfront = true
		_hud.set_objective(_current_objective())


func _on_nell_talk_requested(_npc: Npc) -> void:
	_talk(_nell, REPEAT_TALK if talked_to_nell else FIRST_TALK, _on_nell_finished)


func _on_tovan_talk_requested(_npc: Npc) -> void:
	if GameState.seawall_cleared:
		_talk(_tovan, TOVAN_AFTER)
	elif talked_to_nell:
		_talk(_tovan, TOVAN_ENCOUNTER, GameState.enter_seawall)
	else:
		_talk(_tovan, TOVAN_EARLY)


func _talk(npc: Npc, lines: Array[Dictionary], then: Callable = Callable()) -> void:
	_player.input_locked = true
	_player.face_toward(npc.global_position)
	_after_dialogue = then
	_dialogue.open(lines)


func _on_nell_finished() -> void:
	if not talked_to_nell:
		talked_to_nell = true
		GameState.talked_to_nell = true
		_hud.set_objective(_current_objective())


func _on_dialogue_finished() -> void:
	_player.input_locked = false
	var then: Callable = _after_dialogue
	_after_dialogue = Callable()
	if then.is_valid():
		then.call()
