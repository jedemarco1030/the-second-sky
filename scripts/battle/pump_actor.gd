class_name PumpActor
extends BattleActor
## The harbor pump. Its pressure chamber glow and steam follow the battle state
## the stage passes in: "idle", "charging", "staggered", or "down".

const CHAMBER_IDLE := Color(0.45, 1.0, 0.92)
const CHAMBER_CHARGING := Color(1.0, 0.78, 0.4)
const CHAMBER_STAGGERED := Color(0.55, 0.62, 0.7)

@onready var chamber_glow: Sprite2D = $Body/ChamberGlow
@onready var steam: CPUParticles2D = $Body/Steam
@onready var charge_steam: CPUParticles2D = $Body/ChargeSteam
@onready var chamber_light: PointLight2D = $Body/ChamberLight

var charge_state: String = "idle"


func _process(delta: float) -> void:
	super._process(delta)
	var glow: float = 0.0
	var color: Color = CHAMBER_IDLE
	match charge_state:
		"idle":
			glow = 0.35 + 0.1 * sin(_time * 1.6)
		"charging":
			glow = 0.8 + 0.2 * sin(_time * 7.0)
			color = CHAMBER_CHARGING
			# Rattles in whole pixels while it builds pressure.
			if not _is_moving():
				body.position.x = _base_body.x + (1.0 if fmod(_time, 0.24) < 0.12 else 0.0)
		"staggered":
			glow = 0.2 if fmod(_time, 0.5) < 0.38 else 0.45
			color = CHAMBER_STAGGERED
		"down":
			glow = 0.0
	chamber_glow.modulate = Color(color, glow)
	chamber_light.color = color
	chamber_light.energy = glow * 1.2


func set_charge_state(state: String) -> void:
	if state == charge_state:
		return
	charge_state = state
	steam.emitting = state == "idle" or state == "charging"
	charge_steam.emitting = state == "charging"
	if state != "charging" and not _is_moving():
		body.position.x = _base_body.x


func reset_visuals() -> void:
	super.reset_visuals()
	charge_state = ""
	set_charge_state("idle")


func _is_moving() -> bool:
	return _move_tween != null and _move_tween.is_running()
