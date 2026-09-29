extends Node2D
## Le monde jouable : une longue promenade de gauche à droite à travers un rêve.
## Zones : maison, rue endormie, pont de nuages, souk, grotte, sommet.
## Le monde ne connaît ni l'interface ni les dialogues : il émet des signaux, `main.gd` les relaie.

const P := preload("res://scripts/core/palette.gd")
const DrawUtil := preload("res://scripts/core/draw_util.gd")
const Sfx := preload("res://scripts/core/sfx.gd")
const PlayerScript := preload("res://scripts/world/player.gd")
const CollisionScript := preload("res://scripts/world/collision.gd")
const Backdrop := preload("res://scripts/world/backdrop.gd")
const GroundArt := preload("res://scripts/world/ground_art.gd")
const PagePickup := preload("res://scripts/world/page_pickup.gd")
const Interactable := preload("res://scripts/world/interactable.gd")
const Prop := preload("res://scripts/world/prop.gd")
const Fx := preload("res://scripts/world/fx.gd")
const Chapter2 := preload("res://scripts/world/chapter2.gd")
const ZoneHouse := preload("res://scripts/world/zones/zone_house.gd")
const ZoneStreet := preload("res://scripts/world/zones/zone_street.gd")
const ZoneMarket := preload("res://scripts/world/zones/zone_market.gd")
const ZoneCave := preload("res://scripts/world/zones/zone_cave.gd")
const ZonePeak := preload("res://scripts/world/zones/zone_peak.gd")

signal page_collected(page: int, screen_pos: Vector2, data: Dictionary)
signal story_trigger(id: String)
signal zone_entered(id: String)
signal item_collected(id: String)
signal toast(text: String)
signal prompt_changed(text: String)
signal finished

const WORLD_W := 15600.0
const GROUND_Y := 620.0
const ZONES := [
	["house", 0.0, 1935.0],
	["street", 1935.0, 4200.0],
	["bridge", 4200.0, 4980.0],
	["market", 4980.0, 8500.0],
	["cave", 8500.0, 12300.0],
	["peak", 12300.0, 15600.0],
]

const GROUND_STOPS := [
	[1935.0, Color("5b4a7a"), Color("241b3f"), Color("a58fc9"), 0.40],
	[4200.0, Color("5b4a7a"), Color("241b3f"), Color("a58fc9"), 0.40],
	[5000.0, Color("a8625a"), Color("3a1f3a"), Color("f2b675"), 0.05],
	[8400.0, Color("a8625a"), Color("3a1f3a"), Color("f2b675"), 0.05],
	[9000.0, Color("2b2848"), Color("0f0d22"), Color("6a6aa0"), 0.0],
	[12200.0, Color("2b2848"), Color("0f0d22"), Color("6a6aa0"), 0.0],
	[12800.0, Color("3a3560"), Color("141230"), Color("8f88c8"), 0.18],
	[15600.0, Color("3a3560"), Color("141230"), Color("f0c88a"), 0.18],
]

var chapter: int = 1  # 1 : le premier rêve ; 2 : le second
var world_w: float = WORLD_W
var zones_def: Array = ZONES
var ground_stops: Array = GROUND_STOPS
var save: RefCounted
var mushaf: RefCounted
var player: Node2D
var collision: RefCounted = CollisionScript.new()
var backdrop: Node2D
var story: Array = []
var zone: String = ""
var placed_pages: Array = []  # numéros des pages placées dans ce prototype
var pickups: Dictionary = {}  # identifiant (voir def_id) -> PagePickup
var _defs: Array = []
var checkpoints: PackedVector2Array = PackedVector2Array()
var events: Dictionary = {}  # événements déjà déclenchés (pièces disparues, etc.)

var back_props: Node2D
var ground_root: Node2D
var pages_root: Node2D
var front_props: Node2D
var glow_layer: Node2D
var fx: Node2D
var zones: Array = []
var _overlay_mat: ShaderMaterial
var _overlay_layer: CanvasLayer
var _last_target: Node = null
var _built: bool = false
var frozen_by_story: bool = false


func start(save_data: RefCounted, mushaf_data: RefCounted, spawn: Vector2 = Vector2(-1, -1), chapter_number: int = 1) -> void:
	save = save_data
	mushaf = mushaf_data
	chapter = chapter_number
	if chapter == 2:
		world_w = Chapter2.WORLD_W
		zones_def = Chapter2.ZONES
		ground_stops = Chapter2.GROUND_STOPS
	_load_data()
	_build()
	var pos := spawn
	if pos.x < 0.0:
		pos = Vector2(500.0, 340.0)
	player.teleport(pos)
	_built = true


func _load_data() -> void:
	var suffix := "" if chapter == 1 else "_%d" % chapter
	var text := FileAccess.get_file_as_string("res://data/world_pages%s.json" % suffix)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		placed_pages.clear()
		_defs = parsed.get("pages", [])
		for d in _defs:
			for pg in pages_of_def(d):
				if not placed_pages.has(pg):
					placed_pages.append(pg)
	var dlg: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue%s.json" % suffix))
	if typeof(dlg) == TYPE_DICTIONARY:
		story = dlg.get("triggers", [])


func page_defs() -> Array:
	return _defs


## Identifiant d'une page à prendre : « 322 » pour une page entière, « 600:102 » pour la part d'une sourate sur une page.
static func def_id(d: Dictionary) -> String:
	if d.has("part"):
		return "%d:%d" % [int(d["page"]), int(d["part"])]
	return str(int(d["page"]))


## Pages touchées par une entrée : sa page, toutes les pages de la sourate offerte en entier, ou la liste « pages » d'une part.
func pages_of_def(d: Dictionary) -> Array:
	if d.has("grant_surah"):
		return mushaf.surah_pages(int(d["grant_surah"]))
	if d.has("pages"):
		return d["pages"]
	return [int(d["page"])]


## Tout ce que porte cette entrée est-il déjà dans le Mushaf ?
func owned(d: Dictionary) -> bool:
	if d.has("part"):
		for pg in pages_of_def(d):
			if not save.has_part(int(pg), int(d["part"])):
				return false
		return true
	if d.has("grant_surah"):
		var sid := int(d["grant_surah"])
		for pg in mushaf.surah_pages(sid):
			if not save.has_part(pg, sid):
				return false
		return true
	return save.has_page(int(d["page"]))


func _build() -> void:
	backdrop = Backdrop.new()
	backdrop.chapter = chapter
	backdrop.world_w = world_w
	var sky_layer := CanvasLayer.new()
	sky_layer.layer = -10
	sky_layer.name = "SkyLayer"
	sky_layer.add_child(backdrop)
	add_child(sky_layer)

	back_props = _layer("BackProps", -5)
	ground_root = _layer("Ground", -3)
	pages_root = _layer("Pages", 0)
	front_props = _layer("FrontProps", 4)
	glow_layer = _layer("Glow", 5)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow_layer.material = add

	player = PlayerScript.new()
	player.collision = collision
	player.z_index = 2
	add_child(player)
	backdrop.camera = player.camera
	player.camera.limit_left = 0
	player.camera.limit_right = int(world_w)
	player.camera.limit_top = -900
	player.camera.limit_bottom = 900
	player.footstep.connect(func() -> void: Sfx.play("step", -12.0, randf_range(0.9, 1.1)))
	player.jumped.connect(func() -> void: Sfx.play("step", -8.0, 1.25))
	player.landed.connect(func(hard: bool) -> void: Sfx.play("step", -6.0 if hard else -14.0, 0.8))
	player.interact_target_changed.connect(_on_target_changed)

	fx = Fx.new()
	fx.world = self
	fx.z_index = 6
	add_child(fx)

	# Murs invisibles aux extrémités du monde
	add_static_rect(Rect2(-80.0, -1200.0, 130.0, 3000.0))
	add_static_rect(Rect2(world_w - 50.0, -1200.0, 130.0, 3000.0))

	if chapter == 2:
		zones = Chapter2.make_zones()
	else:
		zones = [ZoneHouse.new(), ZoneStreet.new(), ZoneMarket.new(), ZoneCave.new(), ZonePeak.new()]
	for z in zones:
		z.build(self)
	_build_pages()
	_build_overlay()
	checkpoints = PackedVector2Array([Vector2(500, 340), Vector2(2000, 620), Vector2(4230, 620), Vector2(5040, 620), Vector2(8500, 620), Vector2(12320, 620)])


func _layer(node_name: String, z: int) -> Node2D:
	var n := Node2D.new()
	n.name = node_name
	n.z_index = z
	add_child(n)
	return n


# ---------------------------------------------------------------- terrain

## Bloc plein (mur, plafond) ou, avec one_way, plateforme que l'on peut traverser par le dessous.
## Renvoie le dictionnaire du bloc (clé "on" pour l'activer ou le désactiver, ex. une porte).
func add_static_rect(rect: Rect2, one_way: bool = false, visual: bool = false, color: Color = Color("6a5a8a")) -> Dictionary:
	var block := {}
	if one_way:
		collision.add_platform(rect)
	else:
		block = collision.add_blocker(rect)
	if visual:
		var art := Node2D.new()
		art.draw.connect(func() -> void: _draw_stone(art, rect, color))
		ground_root.add_child(art)
	return block


func add_collision_line(points: PackedVector2Array) -> void:
	collision.add_line(points)


func add_ground(line: PackedVector2Array, detail_seed: int = 3) -> void:
	collision.add_line(line)
	var art := GroundArt.new()
	art.points = line
	art.stops = ground_stops
	art.detail_seed = detail_seed
	ground_root.add_child(art)


func ground_at(x: float) -> float:
	return collision.ground_height(x, GROUND_Y)


## Pierre flottante (pont de nuages, ledges de la grotte).
func add_stone(rect: Rect2, color: Color = Color("6a5a8a"), one_way: bool = true) -> void:
	add_static_rect(rect, one_way, true, color)


func _draw_stone(ci: Node2D, rect: Rect2, color: Color) -> void:
	var rr := Rect2(rect.position, rect.size)
	DrawUtil.rrect(ci, Rect2(rr.position + Vector2(0, 4), rr.size), Color(0, 0, 0, 0.25), 10.0)
	DrawUtil.rrect(ci, rr, color, 10.0)
	ci.draw_line(rr.position + Vector2(8, 3), Vector2(rr.end.x - 8.0, rr.position.y + 3.0), color.lightened(0.3), 3.0, true)
	# dessous en pointe, comme un îlot de rêve
	var tri := PackedVector2Array([Vector2(rr.position.x + 10.0, rr.end.y - 4.0), Vector2(rr.end.x - 10.0, rr.end.y - 4.0), Vector2(rr.position.x + rr.size.x * 0.5, rr.end.y + 26.0)])
	ci.draw_colored_polygon(tri, color.darkened(0.25))


## Petit escalier de pierres pour atteindre une corniche : les marches font au plus 70 px.
func add_ledge(x: float, ground_y: float, height: float, width: float = 150.0, from_left: bool = true, color: Color = Color("5a4d7c")) -> void:
	var steps := maxi(1, int(ceil(height / 70.0)))
	for i in range(steps):
		var h := height * float(i + 1) / float(steps)
		var off := float(steps - 1 - i) * 130.0 * (-1.0 if from_left else 1.0)
		add_stone(Rect2(x - width * 0.5 + off, ground_y - h, width, 26.0), color, true)


func add_prop(kind: String, pos: Vector2, params: Dictionary = {}, front: bool = false) -> Node2D:
	var n := Prop.new()
	n.kind = kind
	n.position = pos
	n.params = params
	n.world = self
	(front_props if front else back_props).add_child(n)
	return n


func add_glow(pos: Vector2, radius: float, color: Color, pulse: float = 0.0) -> Node2D:
	var g := Node2D.new()
	g.position = pos
	var t0 := randf() * 6.0
	g.draw.connect(func() -> void:
		var k := 1.0 + pulse * sin(Time.get_ticks_msec() * 0.002 + t0)
		DrawUtil.glow(g, Vector2.ZERO, radius * k, color))
	if pulse > 0.0:
		var timer := Timer.new()
		timer.wait_time = 0.05
		timer.autostart = true
		timer.timeout.connect(g.queue_redraw)
		g.add_child(timer)
	glow_layer.add_child(g)
	return g


# ---------------------------------------------------------------- pages

func _build_pages() -> void:
	for d in page_defs():
		if owned(d):
			continue
		var x := float(d["x"])
		var lift := float(d.get("lift", 60.0))
		var gy: float = ground_at(x)
		if d.has("y"):
			gy = float(d["y"])
		var pk := PagePickup.new()
		pk.setup(self, d)
		pk.position = Vector2(x, gy - lift)
		pk.add_to_group("light_source")
		pages_root.add_child(pk)
		pickups[def_id(d)] = pk
		if d.has("ledge"):
			add_ledge(x, gy, float(d["ledge"]), float(d.get("ledge_w", 150.0)), bool(d.get("ledge_left", true)))
	# une page qui attendait un événement déjà survenu (souk traversé) est visible d'emblée
	for pk in pickups.values():
		var rv: Dictionary = pk.data.get("reveal", {})
		if pk.hidden_state and str(rv.get("type", "")) == "event" and save.flag(ckey("ev_" + str(rv.get("event", "")))):
			pk.reveal()
	for it in zones:
		if it.has_method("after_pages"):
			it.after_pages(self)


func collect_page(pk: Node) -> void:
	if owned(pk.data):
		return
	var d: Dictionary = pk.data
	if d.has("part"):
		for pg in pages_of_def(d):
			save.add_part(int(pg), int(d["part"]))
	elif d.has("grant_surah"):
		var sid := int(d["grant_surah"])
		for pg in mushaf.surah_pages(sid):
			save.add_part(pg, sid)
	else:
		save.add_page(int(d["page"]))
	pk.collected = true
	pk.visible = false  # plus de lueur ni de colonne de lumière une fois la page prise
	pk.remove_from_group("light_source")
	pk.remove_from_group("interactable")
	Sfx.play("page", -4.0, 1.0)
	save.save_file()
	var screen: Vector2 = get_viewport().get_canvas_transform() * (pk.global_position as Vector2)
	page_collected.emit(int(d["page"]), screen, d)


func others_collected(id: String) -> bool:
	for d in _defs:
		if def_id(d) != id and not owned(d):
			return false
	return true


func others_progress(id: String) -> Vector2i:
	var have := 0
	var total := 0
	for d in _defs:
		if def_id(d) == id:
			continue
		total += 1
		if owned(d):
			have += 1
	return Vector2i(have, total)


func reveal_page(page: int) -> void:
	var id := str(page)
	if pickups.has(id):
		pickups[id].reveal()


func toast_text(text: String) -> void:
	toast.emit(text)


func give_item(id: String) -> void:
	if save.has_item(id):
		return
	save.add_item(id)
	save.save_file()
	item_collected.emit(id)
	Sfx.play("unlock", -4.0, 1.0)


func trigger_event(id: String) -> void:
	if events.has(id):
		return
	events[id] = true
	save.set_flag(ckey("ev_" + id))
	for z in zones:
		if z.has_method("on_event"):
			z.on_event(self, id)
	# les pages cachées peuvent attendre un événement
	for pk in pickups.values():
		var rv: Dictionary = pk.data.get("reveal", {})
		if pk.hidden_state and str(rv.get("type", "")) == "event" and str(rv.get("event", "")) == id:
			pk.reveal()


func _on_target_changed(target: Node) -> void:
	_last_target = target
	if target == null:
		prompt_changed.emit("")
	elif target.has_method("prompt_text"):
		prompt_changed.emit(target.prompt_text())
	else:
		prompt_changed.emit(str(target.get("prompt")))


# ---------------------------------------------------------------- cycle

func _physics_process(_delta: float) -> void:
	if not _built:
		return
	var x := player.global_position.x
	var z := zone_at(x)
	if z != zone:
		zone = z
		zone_entered.emit(z)
	if player.global_position.y > 1300.0:
		player.respawn()
		toast.emit("Le rêve te ramène doucement en arrière.")
	for s in story:
		var sid := str(s["id"])
		if save.flag(sid):
			continue
		if x >= float(s["x"]) and (not s.has("x_max") or x <= float(s["x_max"])):
			save.set_flag(sid)
			story_trigger.emit(sid)
	for it in zones:
		if it.has_method("process"):
			it.process(self, _delta)


func _process(_delta: float) -> void:
	if not _built:
		return
	_update_overlay()


func zone_at(x: float) -> String:
	for z in zones_def:
		if x >= z[1] and x < z[2]:
			return z[0]
	return str(zones_def[zones_def.size() - 1][0])


## Nom d'un repère de sauvegarde, propre au chapitre (le chapitre 1 garde ses noms d'origine).
func ckey(name: String) -> String:
	return name if chapter == 1 else "c%d_%s" % [chapter, name]


func cave_factor() -> float:
	if chapter != 1:
		return 0.0
	var x := player.global_position.x
	return smoothstep(9100.0, 9300.0, x) * (1.0 - smoothstep(12000.0, 12200.0, x))


# ---------------------------------------------------------------- obscurité de la grotte

func _build_overlay() -> void:
	_overlay_layer = CanvasLayer.new()
	_overlay_layer.layer = 3
	_overlay_layer.name = "DarkOverlay"
	var rect := ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform float darkness = 0.0;
uniform vec4 tint : source_color = vec4(0.015, 0.02, 0.06, 1.0);
uniform vec2 lights[24];
uniform float radii[24];
uniform int count = 0;
uniform float aspect = 1.7778;
void fragment() {
	float lit = 0.0;
	for (int i = 0; i < 24; i++) {
		if (i >= count) { break; }
		vec2 d = (SCREEN_UV - lights[i]);
		d.x *= aspect;
		lit += 1.0 - smoothstep(0.0, radii[i], length(d));
	}
	lit = clamp(lit, 0.0, 1.0);
	COLOR = vec4(tint.rgb, darkness * (1.0 - lit * lit * (3.0 - 2.0 * lit)));
}
"""
	_overlay_mat = ShaderMaterial.new()
	_overlay_mat.shader = shader
	rect.material = _overlay_mat
	_overlay_layer.add_child(rect)
	add_child(_overlay_layer)


func _update_overlay() -> void:
	var dark := cave_factor() * 0.95
	_overlay_mat.set_shader_parameter("darkness", dark)
	if dark < 0.01:
		return
	var vp := get_viewport_rect().size
	var xf := get_viewport().get_canvas_transform()
	var pos := PackedVector2Array()
	var rad := PackedFloat32Array()
	pos.resize(24)
	rad.resize(24)
	var n := 0
	var sources: Array = [[player.global_position + Vector2(0, -80), 300.0]]
	# les pages éclairent la grotte, sauf celles qui sont encore cachées
	for node in get_tree().get_nodes_in_group("light_source"):
		if node is Node2D and node.visible and not bool(node.get("hidden_state")):
			var radius: Variant = node.get("light_radius")
			sources.append([node.global_position, float(radius) if radius != null else 120.0])
	for c in get_tree().get_nodes_in_group("cave_light"):
		sources.append([c.global_position, float(c.get_meta("radius", 90.0))])
	for src in sources:
		if n >= 24:
			break
		var s: Vector2 = xf * (src[0] as Vector2)
		if s.x < -400.0 or s.x > vp.x + 400.0 or s.y < -400.0 or s.y > vp.y + 400.0:
			continue
		pos[n] = Vector2(s.x / vp.x, s.y / vp.y)
		rad[n] = float(src[1]) / vp.y
		n += 1
	_overlay_mat.set_shader_parameter("lights", pos)
	_overlay_mat.set_shader_parameter("radii", rad)
	_overlay_mat.set_shader_parameter("count", n)
	_overlay_mat.set_shader_parameter("aspect", vp.x / vp.y)


func player_distance(pos: Vector2) -> float:
	return player.global_position.distance_to(pos)


# ---------------------------------------------------------------- aides pour les tests et le débogage

func debug_teleport(x: float, y: float = -1.0) -> void:
	var yy := y if y >= 0.0 else ground_at(x) - 2.0
	player.teleport(Vector2(x, yy))
