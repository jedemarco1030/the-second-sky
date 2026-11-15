extends Node
## Autoload: story progress that must survive scene changes, plus scene routing.

const HARBOR_SCENE: String = "res://scenes/harbor.tscn"
const SEAWALL_SCENE: String = "res://scenes/seawall_battle.tscn"

var talked_to_nell: bool = false
var seawall_cleared: bool = false
## True for the harbor load right after the battle, so Mira appears at the seawall.
var returning_from_seawall: bool = false

## Tests set this so scene requests are recorded instead of swapping scenes.
var capture_scene_changes: bool = false
var last_scene_request: String = ""


func enter_seawall() -> void:
	_go_to(SEAWALL_SCENE)


func return_to_harbor(victorious: bool) -> void:
	if victorious:
		seawall_cleared = true
	returning_from_seawall = true
	_go_to(HARBOR_SCENE)


func _go_to(path: String) -> void:
	last_scene_request = path
	if capture_scene_changes:
		return
	get_tree().change_scene_to_file.call_deferred(path)
