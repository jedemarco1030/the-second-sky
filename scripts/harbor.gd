extends Node2D
## Harbor walk: Mira starts at the top of the harbor stairs, walks down to the
## waterfront, and finds Nell picking up a distress call from Gull Point Light.

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

const OBJECTIVE_START: String = "Take the stairs down to the waterfront."
const OBJECTIVE_FIND_NELL: String = "Find Nell by the pier. Her radio is crackling."
const OBJECTIVE_DONE: String = "Gull Point Light is calling. Harbor walk complete."

var talked_to_nell: bool = false
var reached_waterfront: bool = false

@onready var _map: HarborMap = $HarborMap
@onready var _player: Player = $World/Player
@onready var _camera: Camera2D = $World/Player/Camera
@onready var _nell: Npc = $World/Nell
@onready var _pip: Pip = $World/Pip
@onready var _dialogue: DialogueBox = $DialogueBox
@onready var _hud: Hud = $HUD


func _ready() -> void:
	_player.global_position = _map.find_marker("S")
	_nell.global_position = _map.find_marker("N")
	_pip.follow(_player)

	var bounds: Vector2i = _map.size_px()
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = bounds.x
	_camera.limit_bottom = bounds.y
	_camera.reset_smoothing.call_deferred()

	_nell.talk_requested.connect(_on_nell_talk_requested)
	_dialogue.finished.connect(_on_dialogue_finished)
	_hud.set_objective(OBJECTIVE_START)


func _process(_delta: float) -> void:
	if reached_waterfront:
		return
	if _player.global_position.y > HarborMap.WATERFRONT_ROW * HarborMap.TILE:
		reached_waterfront = true
		if not talked_to_nell:
			_hud.set_objective(OBJECTIVE_FIND_NELL)


func _on_nell_talk_requested(_npc: Npc) -> void:
	_player.input_locked = true
	_player.face_toward(_nell.global_position)
	_dialogue.open(REPEAT_TALK if talked_to_nell else FIRST_TALK)


func _on_dialogue_finished() -> void:
	_player.input_locked = false
	if not talked_to_nell:
		talked_to_nell = true
		_hud.set_objective(OBJECTIVE_DONE)
