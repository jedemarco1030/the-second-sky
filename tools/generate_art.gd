extends SceneTree
## Regenerates every placeholder sprite in res://art/ plus res://icon.png.
## The PNGs are committed, so this only needs to run after you change it:
##   godot --headless --path . --script res://tools/generate_art.gd

const INK := Color("0b1a1e")
const TEAL_DEEP := Color("133a40")
const TEAL := Color("1f6b68")
const TEAL_LIGHT := Color("5fb3a8")
const AMBER := Color("e8983a")
const AMBER_DARK := Color("b06a22")
const AMBER_LIGHT := Color("ffd48a")
const STONE := Color("3c4b50")
const STONE_DARK := Color("2a3539")
const STONE_LIGHT := Color("66787a")
const WOOD := Color("8a5a32")
const WOOD_DARK := Color("5a3820")
const CREAM := Color("f3e4c2")
const SKIN := Color("e6b48a")
const CLEAR := Color(0, 0, 0, 0)

const TILE := 16
const TILE_COUNT := 13
const FRAME := Vector2i(16, 24)


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://art"))
	_save(_make_tiles(), "res://art/tiles.png")
	_save(_make_mira(), "res://art/mira.png")
	_save(_make_nell(), "res://art/nell.png")
	_save(_make_pip(), "res://art/pip.png")
	_save(_make_tovan(), "res://art/tovan.png")
	_save(_make_pump(), "res://art/pump.png")
	_save(_make_icon(), "res://icon.png")
	quit()


func _save(image: Image, path: String) -> void:
	var error: Error = image.save_png(path)
	if error != OK:
		push_error("Could not save %s (%s)" % [path, error_string(error)])
	else:
		print("wrote ", path)


func _blank(width: int, height: int) -> Image:
	var image: Image = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	image.fill(CLEAR)
	return image


func _rect(image: Image, origin: Vector2i, x: int, y: int, w: int, h: int, color: Color) -> void:
	image.fill_rect(Rect2i(origin.x + x, origin.y + y, w, h), color)


func _px(image: Image, origin: Vector2i, x: int, y: int, color: Color) -> void:
	image.set_pixel(origin.x + x, origin.y + y, color)


# --- Tiles -----------------------------------------------------------------

func _make_tiles() -> Image:
	var image: Image = _blank(TILE * TILE_COUNT, TILE)
	_bricks(image, _tile(0), STONE, STONE_DARK, STONE_LIGHT)
	_bricks(image, _tile(1), TEAL_DEEP, INK, TEAL)
	_roof(image, _tile(2))
	_stairs(image, _tile(3))
	_boards(image, _tile(4))
	_water(image, _tile(5), 0)
	_water(image, _tile(6), 2)
	_crate(image, _tile(7), 3)
	_lantern(image, _tile(8))
	_railing(image, _tile(9))
	_pier(image, _tile(10))
	_window(image, _tile(11))
	_radio(image, _tile(12))
	return image


func _tile(index: int) -> Vector2i:
	return Vector2i(index * TILE, 0)


func _bricks(image: Image, o: Vector2i, base: Color, mortar: Color, highlight: Color) -> void:
	_rect(image, o, 0, 0, TILE, TILE, base)
	for band in 4:
		var top: int = band * 4
		_rect(image, o, 0, top + 3, TILE, 1, mortar)
		var joints: Array = [5, 11] if band % 2 == 0 else [2, 8, 14]
		for joint: int in joints:
			_rect(image, o, joint, top, 1, 3, mortar)
			_px(image, o, (joint + 1) % TILE, top, highlight)


func _roof(image: Image, o: Vector2i) -> void:
	_rect(image, o, 0, 0, TILE, TILE, TEAL)
	for band in 4:
		var top: int = band * 4
		_rect(image, o, 0, top + 3, TILE, 1, TEAL_DEEP)
		var shift: int = 0 if band % 2 == 0 else 2
		for x in range(shift, TILE, 4):
			_px(image, o, x, top + 2, TEAL_DEEP)
			_px(image, o, (x + 1) % TILE, top, TEAL_LIGHT)


func _stairs(image: Image, o: Vector2i) -> void:
	for step in 4:
		var top: int = step * 4
		_rect(image, o, 0, top, TILE, 2, STONE_LIGHT)
		_rect(image, o, 0, top + 2, TILE, 1, STONE)
		_rect(image, o, 0, top + 3, TILE, 1, STONE_DARK)
	_rect(image, o, 0, 0, 1, TILE, STONE_DARK)
	_rect(image, o, TILE - 1, 0, 1, TILE, STONE_DARK)


func _boards(image: Image, o: Vector2i) -> void:
	_rect(image, o, 0, 0, TILE, TILE, WOOD)
	var joints: Array[int] = [6, 12, 3, 10]
	for band in 4:
		var top: int = band * 4
		_rect(image, o, 0, top + 3, TILE, 1, WOOD_DARK)
		_rect(image, o, joints[band], top, 1, 3, WOOD_DARK)
		_px(image, o, (joints[band] + 2) % TILE, top + 1, STONE_LIGHT)


func _pier(image: Image, o: Vector2i) -> void:
	_rect(image, o, 0, 0, TILE, TILE, WOOD)
	var joints: Array[int] = [5, 11, 2, 8]
	for band in 4:
		var left: int = band * 4
		_rect(image, o, left + 3, 0, 1, TILE, WOOD_DARK)
		_rect(image, o, left, joints[band], 3, 1, WOOD_DARK)


func _water(image: Image, o: Vector2i, shift: int) -> void:
	_rect(image, o, 0, 0, TILE, TILE, TEAL_DEEP)
	var dashes: Array[Vector3i] = [Vector3i(2, 3, 4), Vector3i(9, 7, 4), Vector3i(4, 11, 3), Vector3i(11, 14, 4)]
	for dash in dashes:
		for i in dash.z:
			_px(image, o, (dash.x + shift + i) % TILE, dash.y, TEAL)
	_px(image, o, (7 + shift * 2) % TILE, 1, TEAL_LIGHT)
	_px(image, o, (13 + shift) % TILE, 10, TEAL_LIGHT)


func _crate(image: Image, o: Vector2i, top: int) -> void:
	_rect(image, o, 3, 15, 11, 1, Color(INK, 0.5))
	_rect(image, o, 2, top, 12, 15 - top, WOOD_DARK)
	_rect(image, o, 3, top + 1, 10, 13 - top, WOOD)
	for i in range(0, 13 - top):
		var t: float = float(i) / float(maxi(1, 12 - top))
		_px(image, o, 3 + int(round(t * 9.0)), top + 1 + i, WOOD_DARK)
		_px(image, o, 12 - int(round(t * 9.0)), top + 1 + i, WOOD_DARK)
	_rect(image, o, 3, top + 1, 10, 1, AMBER_DARK)


func _lantern(image: Image, o: Vector2i) -> void:
	_rect(image, o, 5, 14, 6, 2, STONE_DARK)
	_rect(image, o, 7, 6, 2, 9, INK)
	_rect(image, o, 6, 0, 4, 1, INK)
	_rect(image, o, 5, 1, 6, 6, INK)
	_rect(image, o, 6, 2, 4, 3, AMBER_LIGHT)
	_rect(image, o, 6, 5, 4, 1, AMBER)


func _railing(image: Image, o: Vector2i) -> void:
	for post in [1, 7, 13]:
		_rect(image, o, post, 5, 2, 8, WOOD_DARK)
	_rect(image, o, 0, 4, TILE, 2, WOOD)
	_rect(image, o, 0, 4, TILE, 1, AMBER_DARK)
	_rect(image, o, 0, 10, TILE, 1, WOOD)
	_rect(image, o, 0, 13, TILE, 1, Color(INK, 0.4))


func _window(image: Image, o: Vector2i) -> void:
	_bricks(image, o, TEAL_DEEP, INK, TEAL)
	_rect(image, o, 4, 3, 8, 10, INK)
	_rect(image, o, 5, 4, 6, 4, AMBER_LIGHT)
	_rect(image, o, 5, 8, 6, 4, AMBER)
	_rect(image, o, 7, 4, 2, 8, INK)
	_rect(image, o, 3, 13, 10, 1, STONE_LIGHT)


func _radio(image: Image, o: Vector2i) -> void:
	_crate(image, o, 8)
	_rect(image, o, 11, 0, 1, 3, INK)
	_rect(image, o, 3, 2, 10, 7, INK)
	_rect(image, o, 4, 3, 8, 5, TEAL)
	_rect(image, o, 5, 4, 3, 3, AMBER_LIGHT)
	_px(image, o, 6, 5, AMBER_DARK)
	_rect(image, o, 9, 6, 3, 1, TEAL_DEEP)
	_rect(image, o, 10, 3, 2, 2, TEAL_DEEP)


# --- Characters --------------------------------------------------------------

const VIEW_DOWN := 0
const VIEW_UP := 1
const VIEW_SIDE := 2


func _make_mira() -> Image:
	var look: Dictionary = {
		"hair": Color("3a2216"),
		"coat": AMBER,
		"coat_dark": AMBER_DARK,
		"scarf": TEAL_LIGHT,
		"pants": TEAL_DEEP,
		"boots": WOOD_DARK,
		"strap": WOOD_DARK,
		"bag": TEAL,
		"headphones": false,
	}
	var image: Image = _blank(FRAME.x * 3, FRAME.y * 3)
	for view in 3:
		for step in 3:
			var origin := Vector2i(step * FRAME.x, view * FRAME.y)
			_person(image, origin, view, step, look)
			_outline(image, Rect2i(origin, FRAME))
	return image


func _make_nell() -> Image:
	var look: Dictionary = {
		"hair": WOOD,
		"coat": TEAL,
		"coat_dark": TEAL_DEEP,
		"scarf": CREAM,
		"pants": TEAL_DEEP,
		"boots": STONE_DARK,
		"strap": AMBER_DARK,
		"bag": STONE_LIGHT,
		"headphones": true,
	}
	var image: Image = _blank(FRAME.x * 2, FRAME.y)
	for frame in 2:
		var origin := Vector2i(frame * FRAME.x, 0)
		_person(image, origin, VIEW_DOWN, 0, look)
		if frame == 1:
			# Hand pressed to the headphone cup: listening hard.
			_rect(image, origin, 12, 10, 1, 7, CLEAR)
			_rect(image, origin, 12, 6, 2, 3, SKIN)
			_rect(image, origin, 12, 9, 1, 2, look["coat_dark"])
		_outline(image, Rect2i(origin, FRAME))
	return image


func _person(image: Image, o: Vector2i, view: int, step: int, look: Dictionary) -> void:
	var hair: Color = look["hair"]
	var coat: Color = look["coat"]
	var coat_dark: Color = look["coat_dark"]

	# Legs and boots, with a lifted foot on walking frames.
	var lift_left: int = 1 if step == 1 else 0
	var lift_right: int = 1 if step == 2 else 0
	if view == VIEW_SIDE:
		var front_x: int = 8 if step == 0 else (9 if step == 1 else 6)
		var back_x: int = 6 if step == 0 else (5 if step == 1 else 8)
		_rect(image, o, back_x, 17, 2, 3, look["pants"])
		_rect(image, o, back_x, 20, 3, 2, look["boots"])
		_rect(image, o, front_x, 17, 2, 3, look["pants"])
		_rect(image, o, front_x, 20, 3, 2, look["boots"])
	else:
		_rect(image, o, 5, 17, 2, 3 - lift_left, look["pants"])
		_rect(image, o, 4, 20 - lift_left, 3, 2, look["boots"])
		_rect(image, o, 9, 17, 2, 3 - lift_right, look["pants"])
		_rect(image, o, 9, 20 - lift_right, 3, 2, look["boots"])

	# Torso and arms.
	_rect(image, o, 4, 10, 8, 7, coat)
	_rect(image, o, 4, 16, 8, 1, coat_dark)
	if view == VIEW_SIDE:
		var swing: int = 0 if step == 0 else (1 if step == 1 else -1)
		_rect(image, o, 7 + swing, 11, 2, 5, coat_dark)
		_rect(image, o, 7 + swing, 16, 2, 1, SKIN)
		_rect(image, o, 4, 12, 2, 4, look["bag"])
	else:
		_rect(image, o, 3, 10, 1, 6, coat_dark)
		_rect(image, o, 12, 10, 1, 6, coat_dark)
		_px(image, o, 3, 16, SKIN)
		_px(image, o, 12, 16, SKIN)
		if view == VIEW_DOWN:
			for i in 6:
				_px(image, o, 5 + i, 10 + i, look["strap"])
			_rect(image, o, 10, 14, 3, 3, look["bag"])
		else:
			_rect(image, o, 5, 11, 4, 4, look["bag"])
			_rect(image, o, 5, 11, 4, 1, look["strap"])

	# Scarf / collar.
	_rect(image, o, 5, 9, 6, 1, look["scarf"])
	if view == VIEW_SIDE:
		_rect(image, o, 4, 10, 2, 2, look["scarf"])

	# Head and hair.
	match view:
		VIEW_DOWN:
			_rect(image, o, 5, 3, 6, 6, SKIN)
			_rect(image, o, 4, 1, 8, 3, hair)
			_rect(image, o, 4, 4, 1, 3, hair)
			_rect(image, o, 11, 4, 1, 3, hair)
			_px(image, o, 6, 5, INK)
			_px(image, o, 9, 5, INK)
			_px(image, o, 7, 7, Color(SKIN.darkened(0.2)))
			_px(image, o, 8, 7, Color(SKIN.darkened(0.2)))
		VIEW_UP:
			_rect(image, o, 4, 1, 8, 8, hair)
			_rect(image, o, 5, 8, 6, 1, SKIN.darkened(0.15))
		VIEW_SIDE:
			_rect(image, o, 5, 3, 6, 6, SKIN)
			_rect(image, o, 4, 1, 7, 3, hair)
			_rect(image, o, 4, 4, 3, 4, hair)
			_px(image, o, 9, 5, INK)
			_px(image, o, 11, 6, SKIN)

	if look["headphones"]:
		_rect(image, o, 4, 0, 8, 1, AMBER)
		_rect(image, o, 3, 3, 2, 4, AMBER)
		_rect(image, o, 11, 3, 2, 4, AMBER)
		_px(image, o, 3, 4, AMBER_LIGHT)
		_px(image, o, 12, 4, AMBER_LIGHT)


func _outline(image: Image, frame: Rect2i) -> void:
	var outline_pixels: Array[Vector2i] = []
	for y in range(frame.position.y, frame.end.y):
		for x in range(frame.position.x, frame.end.x):
			if image.get_pixel(x, y).a > 0.0:
				continue
			for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var n: Vector2i = Vector2i(x, y) + offset
				if frame.has_point(n) and image.get_pixelv(n).a > 0.9:
					outline_pixels.append(Vector2i(x, y))
					break
	for p in outline_pixels:
		image.set_pixelv(p, INK)


func _make_pip() -> Image:
	var image: Image = _blank(16, 8)
	for frame in 2:
		var o := Vector2i(frame * 8, 0)
		if frame == 0:
			_rect(image, o, 0, 1, 3, 4, CREAM)
			_rect(image, o, 5, 1, 3, 4, CREAM)
			_px(image, o, 1, 2, AMBER)
			_px(image, o, 6, 2, AMBER)
		else:
			_rect(image, o, 1, 2, 2, 3, CREAM)
			_rect(image, o, 5, 2, 2, 3, CREAM)
		_rect(image, o, 3, 1, 2, 5, AMBER_LIGHT)
		_px(image, o, 3, 6, AMBER)
		_px(image, o, 2, 0, TEAL_LIGHT)
		_px(image, o, 5, 0, TEAL_LIGHT)
	return image


## Tovan: the old seawall keeper. Two idle frames, the second leaning on his pole.
func _make_tovan() -> Image:
	var look: Dictionary = {
		"hair": STONE_LIGHT,
		"coat": WOOD,
		"coat_dark": WOOD_DARK,
		"scarf": TEAL_LIGHT,
		"pants": STONE_DARK,
		"boots": INK,
		"strap": STONE_DARK,
		"bag": STONE,
		"headphones": false,
	}
	var image: Image = _blank(FRAME.x * 2, FRAME.y)
	for frame in 2:
		var origin := Vector2i(frame * FRAME.x, 0)
		_person(image, origin, VIEW_DOWN, 0, look)
		# Beard and a boat-hook pole.
		_rect(image, origin, 6, 7, 4, 2, CREAM)
		var lean: int = frame
		_rect(image, origin, 13 + lean, 2, 1, 20, AMBER_DARK)
		_rect(image, origin, 12 + lean, 2, 2, 1, STONE_LIGHT)
		_outline(image, Rect2i(origin, FRAME))
	return image


## The harbor pump: a riveted iron tank on a stone plinth. Frame 1 is charging a Surge.
func _make_pump() -> Image:
	var w := 56
	var h := 64
	var image: Image = _blank(w * 2, h)
	for frame in 2:
		var o := Vector2i(frame * w, 0)
		var charging: bool = frame == 1
		# Plinth.
		_rect(image, o, 4, 54, 48, 10, STONE)
		_rect(image, o, 4, 54, 48, 2, STONE_LIGHT)
		_rect(image, o, 4, 62, 48, 2, STONE_DARK)
		# Tank body.
		_rect(image, o, 10, 14, 36, 40, TEAL_DEEP)
		_rect(image, o, 10, 14, 4, 40, TEAL)
		_rect(image, o, 42, 14, 4, 40, INK)
		for band_y in [20, 36, 50]:
			_rect(image, o, 10, band_y, 36, 2, STONE_DARK)
			for rivet_x in range(12, 46, 6):
				_px(image, o, rivet_x, band_y, STONE_LIGHT)
		# Dome and stack.
		_rect(image, o, 14, 8, 28, 6, TEAL)
		_rect(image, o, 18, 4, 20, 4, TEAL_DEEP)
		_rect(image, o, 24, 0, 8, 4, STONE_DARK)
		# Outlet pipes on both sides.
		_rect(image, o, 0, 40, 10, 6, STONE)
		_rect(image, o, 0, 40, 10, 1, STONE_LIGHT)
		_rect(image, o, 46, 28, 10, 6, STONE)
		_rect(image, o, 46, 28, 10, 1, STONE_LIGHT)
		# Pressure gauge.
		var gauge := Vector2(28, 28)
		for y in range(20, 37):
			for x in range(20, 37):
				var d: float = Vector2(x, y).distance_to(gauge)
				if d <= 7.5:
					image.set_pixel(o.x + x, o.y + y, CREAM if d < 6.5 else INK)
		var needle_end: Vector2i = Vector2i(33, 24) if charging else Vector2i(24, 25)
		_line(image, o + Vector2i(28, 28), o + needle_end, AMBER_DARK, 1)
		_px(image, o, 28, 28, INK)
		# Leaking seams; they glow while charging.
		var seam: Color = AMBER_LIGHT if charging else TEAL_LIGHT
		_line(image, o + Vector2i(16, 40), o + Vector2i(20, 46), seam, 1)
		_line(image, o + Vector2i(36, 42), o + Vector2i(40, 48), seam, 1)
		if charging:
			_rect(image, o, 2, 36, 3, 3, AMBER_LIGHT)
			_rect(image, o, 51, 24, 3, 3, AMBER_LIGHT)
			_rect(image, o, 26, 0, 4, 2, AMBER_LIGHT)
		_outline(image, Rect2i(o, Vector2i(w, h)))
	return image


# --- Icon ------------------------------------------------------------------

func _make_icon() -> Image:
	var size := 128
	var image: Image = _blank(size, size)
	image.fill(TEAL_DEEP)
	var center := Vector2(64, 54)
	for y in size:
		for x in size:
			var d: float = Vector2(x, y).distance_to(center)
			if d < 34.0:
				image.set_pixel(x, y, AMBER_LIGHT if d < 31.0 else AMBER)
	var crack: Array[Vector2i] = [Vector2i(44, 28), Vector2i(58, 44), Vector2i(52, 54), Vector2i(70, 62), Vector2i(66, 72), Vector2i(82, 84)]
	for i in crack.size() - 1:
		_line(image, crack[i], crack[i + 1], TEAL_DEEP, 3)
	for row in [98, 106, 114]:
		for x in range(8, 120, 12):
			image.fill_rect(Rect2i(x + (row % 8), row, 7, 2), TEAL_LIGHT if row != 106 else AMBER)
	return image


func _line(image: Image, a: Vector2i, b: Vector2i, color: Color, thickness: int) -> void:
	var steps: int = maxi(absi(b.x - a.x), absi(b.y - a.y))
	for i in steps + 1:
		var t: float = float(i) / float(maxi(1, steps))
		var p: Vector2 = Vector2(a).lerp(Vector2(b), t)
		image.fill_rect(Rect2i(int(p.x) - thickness / 2, int(p.y) - thickness / 2, thickness, thickness), color)
