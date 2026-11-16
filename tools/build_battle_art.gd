extends SceneTree
## Turns the painted sources in art_src/battle/ into the native-resolution layers
## the seawall battle uses (art/battle/). Keys out the magenta backdrop, crops,
## downsamples with premultiplied alpha, hardens edges, and adds a 1px ink outline.
##   godot --headless --path . --script res://tools/build_battle_art.gd

const SRC: String = "res://art_src/battle/"
const OUT: String = "res://art/battle/"
const OUTLINE := Color("0b1220")

## name -> source file, crop region in the source (empty = whole), and target size.
## A target of (0, h) keeps the aspect ratio from the height, (w, 0) from the width.
const SPRITES: Dictionary = {
	"mira": {"src": "mira_raw.png", "size": Vector2i(0, 80)},
	"tovan": {"src": "tovan_raw.png", "size": Vector2i(0, 86)},
	"nell": {"src": "nell_raw.png", "size": Vector2i(0, 86)},
	"pip": {"src": "pip_raw.png", "size": Vector2i(46, 0)},
	"pump": {"src": "pump_raw.png", "size": Vector2i(0, 168)},
	"prop_mooring": {"src": "props_raw.png", "region": Rect2i(0, 0, 520, 768), "size": Vector2i(0, 40)},
	"prop_lantern": {"src": "props_raw.png", "region": Rect2i(520, 0, 360, 768), "size": Vector2i(0, 66)},
	"prop_barrel": {"src": "props_raw.png", "region": Rect2i(880, 0, 528, 768), "size": Vector2i(0, 40)},
}

const VIEW := Vector2i(640, 360)
## Rows of the 640x360 stage painting: the bay ends and the deck begins here.
const DECK_TOP: int = 190
const BACKDROP_BOTTOM: int = 198


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_build_stage()
	for sprite_name: String in SPRITES:
		_build_sprite(sprite_name, SPRITES[sprite_name])
	_write_shadow()
	_write_glow()
	_write_droplet()
	quit(0)


func _build_stage() -> void:
	var image: Image = _load(SRC + "stage_raw.png")
	image = _downsample(image, VIEW)
	var backdrop: Image = image.get_region(Rect2i(0, 0, VIEW.x, BACKDROP_BOTTOM))
	var deck: Image = image.get_region(Rect2i(0, DECK_TOP, VIEW.x, VIEW.y - DECK_TOP))
	_save(backdrop, "backdrop")
	_save(deck, "deck")


func _build_sprite(sprite_name: String, spec: Dictionary) -> void:
	var image: Image = _load(SRC + String(spec["src"]))
	if spec.has("region"):
		image = image.get_region(spec["region"])
	_key_and_premultiply(image)
	var used: Rect2i = image.get_used_rect()
	image = image.get_region(used)
	var target: Vector2i = spec["size"]
	if target.x == 0:
		target.x = maxi(1, roundi(float(used.size.x) * target.y / used.size.y))
	elif target.y == 0:
		target.y = maxi(1, roundi(float(used.size.y) * target.x / used.size.x))
	image = _downsample(image, target)
	_unpremultiply_and_harden(image)
	image = _outlined(image)
	_save(image, sprite_name)
	print("%s: source rect %s -> %s" % [sprite_name, used, image.get_size()])


func _load(path: String) -> Image:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	image.convert(Image.FORMAT_RGBA8)
	return image


func _is_key(c: Color) -> bool:
	if c.r > 0.55 and c.b > 0.55 and c.g < minf(c.r, c.b) * 0.62:
		return absf(c.r - c.b) < 0.35
	return false


func _key_and_premultiply(image: Image) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var c: Color = image.get_pixel(x, y)
			if _is_key(c):
				image.set_pixel(x, y, Color(0, 0, 0, 0))


## Repeated halving keeps every source pixel contributing; one big bilinear step would alias.
func _downsample(image: Image, target: Vector2i) -> Image:
	var result: Image = image.duplicate()
	while result.get_width() > target.x * 2 and result.get_height() > target.y * 2:
		result.resize(result.get_width() / 2, result.get_height() / 2, Image.INTERPOLATE_BILINEAR)
	result.resize(target.x, target.y, Image.INTERPOLATE_BILINEAR)
	return result


func _unpremultiply_and_harden(image: Image) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var c: Color = image.get_pixel(x, y)
			if c.a < 0.5:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				image.set_pixel(x, y, Color(c.r / c.a, c.g / c.a, c.b / c.a, 1.0).clamp())


func _outlined(image: Image) -> Image:
	var w: int = image.get_width() + 2
	var h: int = image.get_height() + 2
	var out := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	out.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), Vector2i(1, 1))
	var edges: Array[Vector2i] = []
	for y in h:
		for x in w:
			if out.get_pixel(x, y).a > 0.0:
				continue
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var p: Vector2i = Vector2i(x, y) + d
				if p.x >= 0 and p.y >= 0 and p.x < w and p.y < h and out.get_pixel(p.x, p.y).a > 0.0:
					edges.append(Vector2i(x, y))
					break
	for p in edges:
		out.set_pixel(p.x, p.y, OUTLINE)
	return out


## Stepped contact shadow: three flat alpha bands, so it reads as pixel art.
func _write_shadow() -> void:
	var size := Vector2i(32, 10)
	var image := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	var center := Vector2(size) * 0.5
	for y in size.y:
		for x in size.x:
			var d: float = Vector2((x + 0.5 - center.x) / center.x, (y + 0.5 - center.y) / center.y).length()
			var a: float = 0.0
			if d < 0.55:
				a = 0.62
			elif d < 0.8:
				a = 0.42
			elif d < 1.0:
				a = 0.22
			image.set_pixel(x, y, Color(0.02, 0.03, 0.08, a))
	_save(image, "fx_shadow")


func _write_glow() -> void:
	var size: int = 64
	var image := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var d: float = Vector2(x + 0.5 - size * 0.5, y + 0.5 - size * 0.5).length() / (size * 0.5)
			var a: float = clampf(1.0 - d, 0.0, 1.0)
			image.set_pixel(x, y, Color(1, 1, 1, a * a))
	_save(image, "fx_glow")


func _write_droplet() -> void:
	var image := Image.create_empty(2, 2, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	_save(image, "fx_droplet")


func _save(image: Image, file_name: String) -> void:
	var err: Error = image.save_png(ProjectSettings.globalize_path(OUT + file_name + ".png"))
	if err != OK:
		push_error("could not save %s: %s" % [file_name, err])
