extends Node
## Renders the seawall battle in a real window and saves 1280x720 screenshots.
## Needs a display (use Xvfb on a server). Run the scene with user args:
##   godot --path . res://tools/capture_battle.tscn -- --shot=opening --out=/tmp/shots
## Shots: "opening" (first command menu) and "surge" (pump charging, Breakwater
## preview open). Animations run at normal speed; the capture waits for them.

const BATTLE_SCENE: PackedScene = preload("res://scenes/seawall_battle.tscn")
const MAX_STEPS: int = 200

var _shot: String = "opening"
var _out_dir: String = "/tmp/shots"


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			_shot = arg.trim_prefix("--shot=")
		elif arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	_run.call_deferred()


func _run() -> void:
	var battle: Node = BATTLE_SCENE.instantiate()
	battle.pace = 0.05
	add_child(battle)
	await _wait(0.6)
	if _shot == "surge":
		var reached: bool = await _drive_to_breakwater_preview(battle)
		if not reached:
			push_error("capture: could not reach a charging Breakwater preview")
			get_tree().quit(1)
			return
	await _wait(1.2)
	var path: String = "%s/battle_%s.png" % [_out_dir, _shot]
	var image: Image = get_viewport().get_texture().get_image()
	if image.get_size() != Vector2i(1280, 720):
		image.resize(1280, 720, Image.INTERPOLATE_NEAREST)
	image.save_png(path)
	print("capture: saved %s (%s)" % [path, image.get_size()])
	get_tree().quit(0)


func _drive_to_breakwater_preview(battle: Node) -> bool:
	for step in MAX_STEPS:
		while battle.menu_state == "busy":
			await get_tree().process_frame
		if battle.menu_state == "result":
			return false
		var model: BattleModel = battle.model
		var actor: BattleUnit = model.current()
		if battle.menu_state != "command":
			_pick(battle, battle.menu_actions()[0])
			continue
		if (actor.id == "tovan" or actor.id == "nell") and model.is_charging() and model.can_breakwater(actor.id):
			_pick(battle, "breakwater")
			return battle.menu_state == "confirm"
		if actor.id == "mira" and not model.unit("nell").is_down():
			_pick(battle, "rally")
			if battle.menu_state == "target":
				_pick(battle, "nell")
			continue
		_pick(battle, "guard")
	return false


func _pick(battle: Node, value: String) -> void:
	var actions: Array[String] = battle.menu_actions()
	var index: int = actions.find(value)
	if index == -1:
		index = 0
	battle._cursor = index
	battle._select()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
