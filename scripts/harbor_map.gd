class_name HarborMap
extends Node2D
## Draws the harbor from a readable ASCII layout and builds merged collision
## rectangles for every solid tile, so walking routes are easy to edit and audit.

const TILE: int = 16
const WATERFRONT_ROW: int = 18
const PIER_ROW: int = 22
const TILESET: Texture2D = preload("res://art/tiles.png")

enum Tile { COBBLE, WALL, ROOF, STAIRS, BOARDS, WATER_A, WATER_B, CRATE, LANTERN, RAILING, PIER, WINDOW, RADIO }

## Legend:
##   R roof   # wall   W lit window   . cobbles   = stairs   b boardwalk   p pier
##   r railing   ~ water   c crate   L lantern   X Nell's radio
##   S Mira's start   N Nell
## Solid tiles: R # W c L r X ~
const LAYOUT: Array[String] = [
	"RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR",
	"RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR",
	"#W##W##W##W##W##W######W##W##W##W##W##W#",
	"#......................................#",
	"#..L........c...................L......#",
	"#...................S..................#",
	"#..................................cc..#",
	"RRRRRRRRRRRRRRRRR#====#RRRRRRRRRRRRRRRRR",
	"RRRRRRRRRRRRRRRRR#====#RRRRRRRRRRRRRRRRR",
	"RRRRRRRRRRRRRRRRR#====#RRRRRRRRRRRRRRRRR",
	"RRRRRRRRRRRRRRRRR#====#RRRRRRRRRRRRRRRRR",
	"##W##W##W##W##W##L====L##W##W##W##W##W##",
	"#####W#..........................#W#####",
	"#####W#.L......................L.#W#####",
	"RRRRRRRRR#====#RRRRRRRRRRRRRRRRRRRRRRRRR",
	"RRRRRRRRR#====#RRRRRRRRRRRRRRRRRRRRRRRRR",
	"RRRRRRRRR#====#RRRRRRRRRRRRRRRRRRRRRRRRR",
	"##W##W###L====L##W##W##W##W##W##W##W##W#",
	"#bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb#",
	"#bbTbbbbbbbbbbbbbbbbbbbbbbccbbbbbbbbbbb#",
	"#bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbNXbbbbbb#",
	"#bbcbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb#",
	"rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrppprrrrrrr",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ppp~~~~~~~",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ppp~~~~~~~",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ppp~~~~~~~",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~LpL~~~~~~~",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
]

const SOLID_CHARS: String = "R#WcLrX~"

const MOON_CENTER: Vector2 = Vector2(200.0, 408.0)
const MOON_RADIUS: float = 20.0
const MOON_LIGHT: Color = Color(1.0, 0.83, 0.54, 0.55)
const CRACK_COLOR: Color = Color("133a40")
const GLOW_OUTER: Color = Color(0.91, 0.6, 0.23, 0.07)
const GLOW_INNER: Color = Color(1.0, 0.83, 0.54, 0.10)
const RADIO_LIGHT: Color = Color("ffd48a")

var _time: float = 0.0
var _redraw_frame: int = -1
var _lantern_lamps: Array[Vector2] = []
var _radio_lamps: Array[Vector2] = []


func _ready() -> void:
	_validate_layout()
	_index_props()
	_build_collision()


func _process(delta: float) -> void:
	_time += delta
	var frame: int = int(_time * 8.0)
	if frame != _redraw_frame:
		_redraw_frame = frame
		queue_redraw()


func columns() -> int:
	return LAYOUT[0].length()


func rows() -> int:
	return LAYOUT.size()


func size_px() -> Vector2i:
	return Vector2i(columns() * TILE, rows() * TILE)


func cell_at(cell: Vector2i) -> String:
	if cell.y < 0 or cell.y >= rows() or cell.x < 0 or cell.x >= columns():
		return "#"
	return LAYOUT[cell.y][cell.x]


func is_solid(cell: Vector2i) -> bool:
	return SOLID_CHARS.contains(cell_at(cell))


## Returns the foot position (where a character's origin should sit) for a marker.
func find_marker(marker: String) -> Vector2:
	for y in rows():
		var x: int = LAYOUT[y].find(marker)
		if x != -1:
			return Vector2(x * TILE + TILE * 0.5, y * TILE + TILE * 0.75)
	push_error("Marker '%s' is missing from the harbor layout." % marker)
	return Vector2.ZERO


func _validate_layout() -> void:
	var width: int = columns()
	for y in rows():
		if LAYOUT[y].length() != width:
			push_error("Harbor layout row %d is %d wide, expected %d." % [y, LAYOUT[y].length(), width])


func _index_props() -> void:
	for y in rows():
		for x in columns():
			var origin := Vector2(x * TILE, y * TILE)
			match LAYOUT[y][x]:
				"L":
					_lantern_lamps.append(origin + Vector2(8.0, 4.0))
				"X":
					_radio_lamps.append(origin + Vector2(10.0, 3.0))


## Merges horizontal runs of solid tiles into single rectangles.
func _build_collision() -> void:
	var body := StaticBody2D.new()
	body.name = "Collision"
	add_child(body)
	for y in rows():
		var x: int = 0
		while x < columns():
			if not is_solid(Vector2i(x, y)):
				x += 1
				continue
			var start: int = x
			while x < columns() and is_solid(Vector2i(x, y)):
				x += 1
			var shape := RectangleShape2D.new()
			shape.size = Vector2((x - start) * TILE, TILE)
			var collider := CollisionShape2D.new()
			collider.shape = shape
			collider.position = Vector2((start + x) * TILE * 0.5, y * TILE + TILE * 0.5)
			body.add_child(collider)


func _draw() -> void:
	var water_phase: int = int(_time * 2.0) % 2
	for y in rows():
		var line: String = LAYOUT[y]
		for x in line.length():
			var symbol: String = line[x]
			var origin := Vector2(x * TILE, y * TILE)
			_blit(_base_tile(symbol, x, y, water_phase), origin)
			var overlay: int = _overlay_tile(symbol)
			if overlay >= 0:
				_blit(overlay, origin)
	_draw_moon_reflection()
	_draw_lantern_glow()
	_draw_radio_light()


func _blit(tile: int, origin: Vector2) -> void:
	draw_texture_rect_region(TILESET, Rect2(origin, Vector2(TILE, TILE)), Rect2(tile * TILE, 0, TILE, TILE))


func _base_tile(symbol: String, x: int, y: int, water_phase: int) -> int:
	match symbol:
		"R":
			return Tile.ROOF
		"#":
			return Tile.WALL
		"W":
			return Tile.WINDOW
		"=":
			return Tile.STAIRS
		"b", "r":
			return Tile.BOARDS
		"p":
			return Tile.PIER
		"~":
			return Tile.WATER_A if (x + y + water_phase) % 2 == 0 else Tile.WATER_B
	return _floor_for_row(y)


func _floor_for_row(y: int) -> int:
	if y >= PIER_ROW:
		return Tile.PIER
	if y >= WATERFRONT_ROW:
		return Tile.BOARDS
	return Tile.COBBLE


func _overlay_tile(symbol: String) -> int:
	match symbol:
		"c":
			return Tile.CRATE
		"L":
			return Tile.LANTERN
		"r":
			return Tile.RAILING
		"X":
			return Tile.RADIO
	return -1


## The cracked artificial moon, reflected in the harbor in broken bands.
func _draw_moon_reflection() -> void:
	var band: int = -int(MOON_RADIUS)
	while band < int(MOON_RADIUS):
		var half_width: float = sqrt(MOON_RADIUS * MOON_RADIUS - float(band * band))
		var sway: float = round(sin(_time * 1.6 + band * 0.35) * 2.0)
		draw_rect(Rect2(MOON_CENTER.x - half_width + sway, MOON_CENTER.y + band, half_width * 2.0, 2.0), MOON_LIGHT)
		band += 3
	var crack := PackedVector2Array([
		Vector2(-13, -15), Vector2(-4, -5), Vector2(-8, 1), Vector2(3, 6), Vector2(0, 11), Vector2(9, 17),
	])
	for i in crack.size():
		crack[i] += MOON_CENTER
	draw_polyline(crack, CRACK_COLOR, 2.0)
	var drift: float = round(sin(_time * 0.9) * 1.5)
	draw_rect(Rect2(MOON_CENTER + Vector2(19.0 + drift, -22.0), Vector2(4.0, 2.0)), MOON_LIGHT)


func _draw_lantern_glow() -> void:
	var pulse: float = sin(_time * 3.0) * 1.0
	for lamp in _lantern_lamps:
		draw_circle(lamp, 26.0 + pulse, GLOW_OUTER)
		draw_circle(lamp, 13.0 + pulse * 0.5, GLOW_INNER)


func _draw_radio_light() -> void:
	if int(_time * 3.0) % 2 != 0:
		return
	for lamp in _radio_lamps:
		draw_rect(Rect2(lamp, Vector2(2.0, 2.0)), RADIO_LIGHT)
		draw_circle(lamp + Vector2.ONE, 6.0, GLOW_INNER)
