extends Node2D
## Une page du Mushaf éparpillée dans le rêve.
##  - visible : elle brille, on la prend avec E ;
##  - cachée  : elle n'apparaît qu'après un geste (rester immobile, toucher une veine de lumière, un événement) ;
##  - verrouillée : scellée (sceau de lumière ou coffre) jusqu'à ce qu'une condition soit remplie.
## Les pages portent des traits abstraits, jamais de texte coranique.

const P := preload("res://scripts/core/palette.gd")
const DrawUtil := preload("res://scripts/core/draw_util.gd")
const I18n := preload("res://scripts/core/i18n.gd")
const Sfx := preload("res://scripts/core/sfx.gd")

signal revealed_now(pickup: Node)
signal unlocked_now(pickup: Node)

var page: int = 0
var id: String = ""
var data: Dictionary = {}
var world: Node2D
var collected: bool = false
var hidden_state: bool = false
var locked: bool = false
var lock: Dictionary = {}
var ground_dy: float = 60.0  # distance jusqu'au sol, sous la page
var light_radius: float = 150.0
var focus_dy: float = 0.0

var _t: float = 0.0
var _appear: float = 1.0
var _unlock: float = 0.0
var _wait: float = 0.0
var _glow: Node2D
var _lines: Array = []
var _seed: int = 0
var _spin: float = 0.0  # avance de la spirale du signe « page cachée »
var _shimmer: AudioStreamPlayer2D  # frisselis positionnel : on entend la page avant de la voir


func setup(w: Node2D, d: Dictionary) -> void:
	world = w
	data = d
	page = int(d["page"])
	id = w.def_id(d)
	lock = d.get("lock", {})
	ground_dy = float(d.get("lift", 60.0))
	var rs = w.save.revealed
	hidden_state = d.get("kind", "visible") == "hidden" and not rs.has("page_" + id)
	locked = d.get("kind", "visible") == "locked" and not rs.has("unlock_" + id)
	_appear = 0.0 if hidden_state else 1.0
	_unlock = 0.0 if locked else 1.0
	_seed = page * 7919
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	for i in range(7):
		_lines.append(rng.randf_range(0.55, 1.0))


func _ready() -> void:
	add_to_group("interactable")
	_shimmer = Sfx.emitter(self, "shimmer", Vector2.ZERO, -80.0, 380.0)
	if hidden_state:
		z_index = 5  # le signe d'une page cachée passe devant le décor
	_glow = Node2D.new()
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = mat
	_glow.draw.connect(_draw_glow)
	add_child(_glow)
	add_to_group("page_pickup")


func is_chest() -> bool:
	return locked and lock.get("visual", "seal") == "chest"


func can_interact() -> bool:
	return not collected and not hidden_state and _appear > 0.85


func prompt_text() -> String:
	if locked:
		return I18n.t("pickup.open_with_key" if lock_satisfied() and str(lock.get("type", "")) == "key" else "pickup.locked")
	return I18n.t("pickup.take")


func interact(_player: Node) -> void:
	if collected:
		return
	if locked:
		if lock_satisfied():
			unlock()
		else:
			world.toast_text(lock_hint())
		return
	world.collect_page(self)


func lock_satisfied() -> bool:
	match str(lock.get("type", "")):
		"key":
			return world.save.has_item(str(lock.get("item", "")))
		"pages":
			for p in lock.get("pages", []):
				if not world.save.has_page(int(p)):
					return false
			return true
		"others":
			return world.others_collected(id)
		"count":
			return world.save.count() >= int(lock.get("n", 1))
	return true


func lock_hint() -> String:
	var hint_key := "hint.c%d.%s" % [world.chapter, world.def_id(data)]
	var h := I18n.t(hint_key) if I18n.has_key(hint_key) else I18n.t("pickup.default_hint")
	match str(lock.get("type", "")):
		"pages":
			var need: Array = lock.get("pages", [])
			var have := 0
			for p in need:
				if world.save.has_page(int(p)):
					have += 1
			h += I18n.t("pickup.progress", {"have": have, "total": need.size()})
		"others":
			var c: Vector2i = world.others_progress(id)
			h += I18n.t("pickup.progress", {"have": c.x, "total": c.y})
	return h


func unlock() -> void:
	if not locked:
		return
	locked = false
	world.save.revealed["unlock_" + id] = true
	unlocked_now.emit(self)
	var tw := create_tween()
	tw.tween_property(self, "_unlock", 1.0, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func reveal() -> void:
	if not hidden_state:
		return
	hidden_state = false
	z_index = 0
	world.save.revealed["page_" + id] = true
	revealed_now.emit(self)
	var tw := create_tween()
	tw.tween_property(self, "_appear", 1.0, 1.1).set_trans(Tween.TRANS_SINE)


func _process(delta: float) -> void:
	_t += delta
	if collected:
		if _shimmer != null:
			_shimmer.queue_free()
			_shimmer = null
		return
	if _shimmer != null:  # un frémissement très doux, seulement tout près ; une page cachée s'entend un peu mieux : c'est un indice
		var target := -31.0 if hidden_state else (-40.0 if locked else -33.0)
		_shimmer.volume_db = move_toward(_shimmer.volume_db, target, 40.0 * delta)
	var p = world.player
	# loin de l'écran : rien à animer ni à dessiner
	var far: bool = absf(p.global_position.x - global_position.x) > 1500.0
	if far:
		return
	if hidden_state:
		var rv: Dictionary = data.get("reveal", {})
		if str(rv.get("type", "")) == "wait":
			var near: bool = absf(p.global_position.x - global_position.x) < float(rv.get("radius", 110.0)) and p.is_on_floor()
			if near and p.idle_time() > 0.3:
				_wait += delta
				if _wait >= float(rv.get("seconds", 2.5)):
					reveal()
			else:
				_wait = maxf(_wait - delta * 1.5, 0.0)
	elif locked and str(lock.get("type", "")) != "" and lock.get("auto", true):
		# Le sceau se défait tout seul dès que la condition est remplie, sous les yeux du joueur.
		if absf(p.global_position.x - global_position.x) < 420.0 and lock_satisfied():
			unlock()
	queue_redraw()
	_glow.queue_redraw()


## Signe d'une page cachée. Il ne doit ressembler à aucune autre particule du jeu : les poussières d'ambiance sont
## des points ronds, flous et dorés ; ici ce sont des étoiles nettes à quatre branches, d'un vert d'eau presque blanc,
## qui montent en spirale. On les voit de loin, et de mieux en mieux en s'approchant.
const HIDDEN_TINT := Color(0.45, 1.0, 0.86)

func _draw_hidden_sign() -> void:
	var d: float = absf(world.player.global_position.x - global_position.x)
	var g := lerpf(0.55, 1.0, clampf(1.0 - d / 700.0, 0.0, 1.0))
	# Quand le joueur reste immobile tout près, les étoiles se resserrent, accélèrent et s'éclairent : c'est le seul
	# signe que la page arrive (aucun cercle, ni au sol ni autour).
	var need := float(data.get("reveal", {}).get("seconds", 2.5))
	var prog := clampf(_wait / need, 0.0, 1.0)
	_spin += get_process_delta_time() * (0.2 + 1.1 * prog)
	if prog > 0.01:
		DrawUtil.glow(self, Vector2.ZERO, 40.0 + 70.0 * prog, Color(HIDDEN_TINT, 0.30 * prog))
	# étoiles à quatre branches qui montent en spirale, du sol jusqu'au-dessus de la page
	var count := 10
	var height := ground_dy + 90.0
	for i in range(count):
		var ph := fposmod(_spin + float(i) / float(count), 1.0)
		var swirl := ph * TAU * 1.5 + float(i) * 0.9
		var pos := Vector2(sin(swirl) * 30.0 * (1.0 - ph * 0.45) * (1.0 - 0.6 * prog), ground_dy - ph * height)
		var a := minf(1.0, g * sin(PI * ph) * (1.0 + prog))
		var r := 5.0 + 5.0 * sin(PI * ph) + (2.0 if i % 3 == 0 else 0.0) + 3.0 * prog
		var rot := _t * 0.9 + float(i)
		draw_colored_polygon(DrawUtil.star(pos, r * 1.7, r * 0.45, 4, rot), Color(HIDDEN_TINT, a * 0.55))
		draw_colored_polygon(DrawUtil.star(pos, r, r * 0.24, 4, rot), Color(1, 1, 1, a))


func _bob() -> float:
	return sin(_t * 2.0 + float(page)) * 6.0


func _chest_rise() -> float:
	# La page sort du coffre : de 0 (dedans) à 1 (en haut)
	return _unlock


func _draw() -> void:
	if collected:
		return
	if hidden_state:
		_draw_hidden_sign()
		return

	var y := _bob()
	if is_chest():
		var lift_up := _chest_rise()
		# coffre posé au sol, la page en sort quand il s'ouvre
		var base := Vector2(0, ground_dy - 22.0)
		_draw_chest(base, lift_up)
		y = lerpf(ground_dy - 30.0, _bob(), lift_up)
		if lift_up < 0.35:
			return
	_draw_sheet(Vector2(0, y), 1.0)
	if locked and not is_chest():
		_draw_seal(Vector2(0, y))


func _draw_sheet(pos: Vector2, scale_f: float) -> void:
	var a := _appear
	draw_set_transform(pos, sin(_t * 1.3 + float(page)) * 0.08, Vector2.ONE * scale_f * (0.6 + 0.4 * a))
	var w := 36.0
	var h := 50.0
	DrawUtil.rrect(self, Rect2(-w / 2.0 + 2.0, -h / 2.0 + 3.0, w, h), Color(0, 0, 0, 0.25 * a), 5.0)
	DrawUtil.rrect(self, Rect2(-w / 2.0, -h / 2.0, w, h), DrawUtil.with_alpha(P.PARCHMENT, a), 5.0, DrawUtil.with_alpha(P.GOLD_DEEP, a), 2)
	draw_colored_polygon(DrawUtil.star(Vector2(0, -h / 2.0 + 9.0), 5.0, 2.6, 8), DrawUtil.with_alpha(P.GOLD_DEEP, a))
	for i in range(_lines.size()):
		var ly := -h / 2.0 + 18.0 + float(i) * 4.9
		var lw: float = (w - 14.0) * _lines[i]
		draw_line(Vector2(-lw / 2.0, ly), Vector2(lw / 2.0, ly), Color(0.35, 0.27, 0.12, 0.7 * a), 1.6, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_seal(center: Vector2) -> void:
	var fade := 1.0 - _unlock
	var r := 44.0 + _unlock * 30.0
	for i in range(2):
		var rot := _t * (0.5 if i == 0 else -0.35)
		var poly := DrawUtil.star(center, r - float(i) * 10.0, (r - float(i) * 10.0) * 0.66, 8, rot)
		var closed := PackedVector2Array(poly)
		closed.append(poly[0])
		draw_polyline(closed, Color(1.0, 0.9, 0.62, 0.75 * fade), 2.0, true)


func _draw_chest(base: Vector2, open: float) -> void:
	var w := 84.0
	var h := 40.0
	var wood := Color("6b4a2f")
	var dark := Color("3d2a1a")
	var band := Color("b8862b")
	# corps
	draw_rect(Rect2(base.x - w / 2.0, base.y - h / 2.0, w, h), wood)
	draw_rect(Rect2(base.x - w / 2.0, base.y - h / 2.0, w, 5.0), dark)
	for bx in [-28.0, 28.0]:
		draw_rect(Rect2(base.x + bx - 3.0, base.y - h / 2.0, 6.0, h), band)
	# couvercle : pivot à l'arrière, il se soulève
	var pivot := Vector2(base.x - w / 2.0, base.y - h / 2.0)
	var ang := -open * 1.1
	var lid := PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w - 4.0, -18.0), Vector2(6.0, -18.0)])
	var out := PackedVector2Array()
	for p in lid:
		out.append(pivot + p.rotated(ang))
	draw_colored_polygon(out, wood.lightened(0.08))
	draw_polyline(out, dark, 2.0, true)
	# serrure : disparaît quand c'est ouvert
	if open < 0.3:
		var lock_pos := Vector2(base.x, base.y - h / 2.0 + 3.0)
		draw_circle(lock_pos, 6.0, band)
		draw_rect(Rect2(lock_pos.x - 1.5, lock_pos.y, 3.0, 8.0), dark)


func _draw_glow() -> void:
	if collected or hidden_state:
		return
	var a := _appear
	var y := _bob()
	if is_chest():
		y = lerpf(ground_dy - 30.0, _bob(), _chest_rise())
		if _chest_rise() < 0.35:
			DrawUtil.glow(_glow, Vector2(0, ground_dy - 30.0), 60.0, Color(1.0, 0.85, 0.5, 0.18))
			return
	var pulse := 0.8 + 0.2 * sin(_t * 2.4)
	DrawUtil.glow(_glow, Vector2(0, y), 96.0 * pulse, Color(1.0, 0.86, 0.5, 0.55 * a))
	# colonne de lumière pour les pages visibles : on les repère de loin
	if not locked:
		DrawUtil.vgrad(_glow, Rect2(-20, y - 320.0, 40, 330), Color(1.0, 0.9, 0.6, 0.0), Color(1.0, 0.9, 0.6, 0.20 * a))
