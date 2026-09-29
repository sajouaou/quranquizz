extends Control
## Le Mushaf du personnage : un livre ouvert (double page), une vue d'ensemble des 604 pages et la liste des sourates.
## Une page retrouvée porte son texte ; une page manquante est blanche. Le texte n'est jamais écrit dans le code
## (voir core/quran_text.gd) ; hors ligne et sans texte fourni, la page affiche des traits abstraits.

const P := preload("res://scripts/core/palette.gd")
const DrawUtil := preload("res://scripts/core/draw_util.gd")
const UiTheme := preload("res://scripts/ui/ui_theme.gd")
const Assets := preload("res://scripts/core/assets.gd")
const QuranText := preload("res://scripts/core/quran_text.gd")

signal closed

## Dans ce prototype, les pages « qui existent » (placées dans le monde) sont signalées par un anneau discret.
const SHOW_PLACED_HINT := true

var mushaf: RefCounted
var save: RefCounted
var placed_pages: Array = []

var mode: String = "book"  # book | index | surahs
var right_page: int = 1  # page impaire de droite ; la page paire de gauche est right_page + 1
var hover_page: int = 0

var _dim: ColorRect
var _panel: Control
var _title: Label
var _tabs: Dictionary = {}
var _views: Dictionary = {}
var _nav: HBoxContainer
var _nav_label: Label
var _scroll: ScrollContainer
var _list: VBoxContainer
var _tooltip: Label


class View:
	extends Control
	var ui: Control
	var kind: String = ""

	func _draw() -> void:
		if ui != null:
			ui.draw_view(self, kind)

	func _gui_input(event: InputEvent) -> void:
		if ui != null:
			ui.view_input(self, kind, event)


func setup(save_data: RefCounted, mushaf_data: RefCounted, placed: Array) -> void:
	save = save_data
	mushaf = mushaf_data
	placed_pages = placed


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	_dim = ColorRect.new()
	_dim.color = Color(0.01, 0.01, 0.05, 0.82)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)

	_panel = Control.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.offset_left = 36
	_panel.offset_right = -36
	_panel.offset_top = 22
	_panel.offset_bottom = -22
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 10)
	_panel.add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	root.add_child(header)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 30)
	_title.add_theme_color_override("font_color", P.GOLD)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	for entry in [["book", "Livre"], ["index", "Vue d'ensemble"], ["surahs", "Sourates"]]:
		var b := Button.new()
		b.text = entry[1]
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(set_mode.bind(entry[0]))
		header.add_child(b)
		_tabs[entry[0]] = b
	var close := Button.new()
	close.text = "Fermer"
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(close_book)
	header.add_child(close)

	var stack := Control.new()
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(stack)
	for kind in ["book", "index"]:
		var v := View.new()
		v.ui = self
		v.kind = kind
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		v.mouse_filter = Control.MOUSE_FILTER_STOP
		v.resized.connect(v.queue_redraw)
		stack.add_child(v)
		_views[kind] = v
	_scroll = ScrollContainer.new()
	_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	stack.add_child(_scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	_scroll.add_child(_list)
	_views["surahs"] = _scroll

	_nav = HBoxContainer.new()
	_nav.alignment = BoxContainer.ALIGNMENT_CENTER
	_nav.add_theme_constant_override("separation", 16)
	root.add_child(_nav)
	var next := Button.new()
	next.text = "<  Pages suivantes"
	next.focus_mode = Control.FOCUS_NONE
	next.pressed.connect(turn.bind(1))
	_nav.add_child(next)
	_nav_label = Label.new()
	_nav_label.custom_minimum_size = Vector2(280, 0)
	_nav_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nav.add_child(_nav_label)
	var prev := Button.new()
	prev.text = "Pages précédentes  >"
	prev.focus_mode = Control.FOCUS_NONE
	prev.pressed.connect(turn.bind(-1))
	_nav.add_child(prev)

	_tooltip = Label.new()
	_tooltip.add_theme_font_size_override("font_size", 20)
	_tooltip.add_theme_color_override("font_color", P.GOLD)
	_tooltip.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_tooltip.add_theme_constant_override("outline_size", 6)
	_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip.visible = false
	add_child(_tooltip)

	if QuranText.inst != null:
		QuranText.inst.loaded.connect(func(_p: int) -> void: _refresh())


func is_open() -> bool:
	return visible


## Ouvre le livre sur la page voulue (0 : dernière page retrouvée, sinon la première).
func open_book(page: int = 0) -> void:
	if page <= 0:
		page = _latest_collected()
	right_page = _spread_of(page)
	visible = true
	set_mode("book")
	get_tree().paused = true


func close_book() -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = false
	closed.emit()


func _latest_collected() -> int:
	var latest := -1
	for k in save.parts.keys():
		latest = maxi(latest, int(str(k).get_slice(":", 0)))
	return latest if latest > 0 else 1


func _spread_of(page: int) -> int:
	var p := clampi(page, 1, mushaf.total_pages)
	return p if p % 2 == 1 else p - 1


func set_mode(new_mode: String) -> void:
	mode = new_mode
	for k in _tabs.keys():
		(_tabs[k] as Button).button_pressed = (k == mode)
	for k in _views.keys():
		(_views[k] as Control).visible = (k == mode)
	_nav.visible = (mode == "book")
	if mode == "surahs":
		_rebuild_surahs()
	_refresh()


func turn(direction: int) -> void:
	right_page = clampi(right_page + 2 * direction, 1, mushaf.total_pages - (1 if mushaf.total_pages % 2 == 0 else 0))
	if right_page % 2 == 0:
		right_page -= 1
	_refresh()


func _refresh() -> void:
	if not visible and not is_inside_tree():
		return
	_title.text = "Mon Mushaf  ·  %d / %d pages retrouvées" % [save.count(), mushaf.total_pages]
	_nav_label.text = "Pages %d – %d" % [right_page, right_page + 1]
	for k in ["book", "index"]:
		(_views[k] as Control).queue_redraw()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("mushaf") or event.is_action_pressed("pause"):
		close_book()
		get_viewport().set_input_as_handled()
	elif mode == "book" and event.is_action_pressed("move_left"):
		turn(1)
		get_viewport().set_input_as_handled()
	elif mode == "book" and event.is_action_pressed("move_right"):
		turn(-1)
		get_viewport().set_input_as_handled()


# ----------------------------------------------------------------------------------------------- dessin

func draw_view(c: Control, kind: String) -> void:
	if kind == "book":
		_draw_book(c)
	else:
		_draw_index(c)


func _draw_book(c: Control) -> void:
	var sz := c.size
	var page_h := minf(sz.y - 24.0, (sz.x - 60.0) / 2.0 / 0.72)
	var page_w := page_h * 0.72
	var cx := sz.x * 0.5
	var cy := sz.y * 0.5
	var cover := Rect2(cx - page_w - 18.0, cy - page_h * 0.5 - 14.0, page_w * 2.0 + 36.0, page_h + 28.0)
	DrawUtil.rrect(c, cover, Color("1c3a2f"), 18.0, Color(0.91, 0.77, 0.42, 0.85), 3)
	var left := Rect2(cx - page_w - 3.0, cy - page_h * 0.5, page_w, page_h)
	var right := Rect2(cx + 3.0, cy - page_h * 0.5, page_w, page_h)
	_draw_page(c, left, right_page + 1)
	_draw_page(c, right, right_page)
	# ombre de la reliure
	DrawUtil.hgrad(c, Rect2(cx - 22.0, cy - page_h * 0.5, 22.0, page_h), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.28))
	DrawUtil.hgrad(c, Rect2(cx, cy - page_h * 0.5, 22.0, page_h), Color(0, 0, 0, 0.28), Color(0, 0, 0, 0.0))


func _draw_page(c: Control, r: Rect2, p: int) -> void:
	if p < 1 or p > mushaf.total_pages:
		c.draw_rect(r, Color("162e26"))
		return
	var font := Assets.font_book()
	var prog: Vector2i = save.page_progress(p)
	if prog.x == 0:
		# Page manquante : blanche, seulement son numéro tout en bas
		c.draw_rect(r, Color("fbfaf6"))
		c.draw_rect(r, Color(0, 0, 0, 0.07), false, 1.0)
		c.draw_string(font, Vector2(r.position.x, r.end.y - 20.0), "%d" % p, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 20, Color(0.6, 0.6, 0.62, 0.9))
		if p in placed_pages:
			c.draw_string(font, Vector2(r.position.x, r.get_center().y), "cette page attend quelque part dans le rêve", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 17, Color(0.7, 0.7, 0.72, 0.8))
		return
	# Page (au moins en partie) retrouvée
	c.draw_rect(r, P.PARCHMENT)
	var inner := r.grow(-12.0)
	c.draw_rect(inner, P.GOLD_DEEP, false, 2.0)
	c.draw_rect(inner.grow(-5.0), Color(P.GOLD_DEEP, 0.5), false, 1.0)
	var body := Rect2(inner.position.x + 20.0, inner.position.y + 18.0, inner.size.x - 40.0, inner.size.y - 18.0 - 56.0)
	_draw_parts(c, font, body, p)
	# Pied de page : numéro, juz, sourate
	c.draw_string(font, Vector2(inner.position.x, inner.end.y - 30.0), DrawUtil.arabic_digits(p), HORIZONTAL_ALIGNMENT_CENTER, inner.size.x, 26, Color("6b4a12"))
	c.draw_string(font, Vector2(inner.position.x + 14.0, inner.end.y - 12.0), "Juz' %d" % mushaf.juz_of_page(p), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.4, 0.3, 0.15, 0.8))
	if prog.x < prog.y:
		c.draw_string(font, Vector2(inner.position.x, inner.end.y - 12.0), "%d / %d parties" % [prog.x, prog.y], HORIZONTAL_ALIGNMENT_RIGHT, inner.size.x - 14.0, 15, Color(0.55, 0.3, 0.1, 0.9))
	else:
		c.draw_string(font, Vector2(inner.position.x, inner.end.y - 12.0), mushaf.page_title(p), HORIZONTAL_ALIGNMENT_RIGHT, inner.size.x - 14.0, 15, Color(0.4, 0.3, 0.15, 0.8))


## Le corps d'une page : une zone par sourate présente sur la page, séparées par un bandeau au nom de la sourate quand elle commence ici.
## Une partie non retrouvée reste blanche.
func _draw_parts(c: Control, font: Font, body: Rect2, p: int) -> void:
	var parts: Array = mushaf.parts_of_page(p)
	var segs: Array = QuranText.get_segments(p)
	var text_of := {}
	for sg in segs:
		text_of[int(sg["surah"])] = str(sg["text"])
	var all_text := text_of.size() >= parts.size()
	# poids de chaque zone : longueur du texte si on l'a, sinon nombre de versets
	var weights := []
	var total := 0.0
	for pt in parts:
		var w: float = float(str(text_of.get(int(pt[0]), "")).length()) if all_text else float(int(pt[2]) - int(pt[1]) + 1)
		w = maxf(w, 1.0) + (60.0 if all_text else 2.0) * (1.0 if int(pt[1]) == 1 else 0.0)
		weights.append(w)
		total += w
	var gap := 12.0
	var avail := body.size.y - gap * float(parts.size() - 1)
	var y := body.position.y
	var size_cap := 26
	var layouts := []
	for i in range(parts.size()):
		var pt: Array = parts[i]
		var h: float = avail * float(weights[i]) / total
		var rect := Rect2(body.position.x, y, body.size.x, h)
		var head := 0.0
		if int(pt[1]) == 1:
			head = 40.0
		layouts.append({"rect": rect, "head": head})
		y += h + gap
	# une même taille de texte pour toute la page : la plus grande qui convient à chaque zone
	if all_text:
		for i in range(parts.size()):
			var sid := int(parts[i][0])
			var rect: Rect2 = layouts[i]["rect"]
			var text_rect := Rect2(rect.position.x, rect.position.y + float(layouts[i]["head"]), rect.size.x, maxf(rect.size.y - float(layouts[i]["head"]), 10.0))
			if bool(save.has_part(p, sid)):
				size_cap = mini(size_cap, _fit_size(font, str(text_of[sid]), text_rect))
	for i in range(parts.size()):
		var pt: Array = parts[i]
		var sid := int(pt[0])
		var have: bool = save.has_part(p, sid)
		var rect: Rect2 = layouts[i]["rect"]
		var head: float = layouts[i]["head"]
		if head > 0.0:
			_draw_banner(c, font, Rect2(rect.position.x, rect.position.y, rect.size.x, 34.0), str(mushaf.surah(sid).get("name_ar", "")), have)
		var text_rect := Rect2(rect.position.x, rect.position.y + head, rect.size.x, maxf(rect.size.y - head, 10.0))
		if not have:
			c.draw_rect(text_rect, Color("fbfaf6"))
			c.draw_rect(text_rect, Color(0, 0, 0, 0.08), false, 1.0)
			c.draw_string(font, Vector2(text_rect.position.x, text_rect.get_center().y + 6.0), "%s : à retrouver" % str(mushaf.surah(sid).get("name_fr", "")), HORIZONTAL_ALIGNMENT_CENTER, text_rect.size.x, 17, Color(0.62, 0.6, 0.6, 0.9))
		elif text_of.has(sid):
			_draw_text_fit(c, font, str(text_of[sid]), text_rect, size_cap)
		else:
			_draw_script_lines(c, text_rect, p * 31 + sid)
	if segs.is_empty() and prog_any(p):
		c.draw_string(font, Vector2(body.position.x, body.end.y + 22.0), "Texte disponible en ligne", HORIZONTAL_ALIGNMENT_CENTER, body.size.x, 14, Color(0.4, 0.3, 0.15, 0.75))


func prog_any(p: int) -> bool:
	return save.page_progress(p).x > 0


## Bandeau de début de sourate : filets dorés et nom de la sourate.
func _draw_banner(c: Control, font: Font, r: Rect2, name_ar: String, have: bool) -> void:
	var col := Color("6b4a12") if have else Color(0.6, 0.58, 0.55, 0.9)
	var mid := r.position.y + r.size.y * 0.5
	c.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, r.size.y), Color(P.GOLD, 0.16 if have else 0.0))
	c.draw_rect(r, Color(col, 0.7), false, 1.5)
	c.draw_line(Vector2(r.position.x + 6.0, r.position.y + 5.0), Vector2(r.end.x - 6.0, r.position.y + 5.0), Color(col, 0.35), 1.0)
	c.draw_line(Vector2(r.position.x + 6.0, r.end.y - 5.0), Vector2(r.end.x - 6.0, r.end.y - 5.0), Color(col, 0.35), 1.0)
	c.draw_string(font, Vector2(r.position.x, mid + 9.0), "سورة " + name_ar, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 24, col)


func _fit_size(font: Font, text: String, body: Rect2) -> int:
	for s in [26, 24, 22, 20, 18, 16, 14, 13]:
		var h := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_FILL, body.size.x, s, -1, TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND, TextServer.JUSTIFICATION_WORD_BOUND | TextServer.JUSTIFICATION_KASHIDA, TextServer.DIRECTION_RTL).y
		if h <= body.size.y:
			return s
	return 13


func _draw_text_fit(c: Control, font: Font, text: String, body: Rect2, size_cap: int = 26) -> void:
	var chosen := mini(_fit_size(font, text, body), size_cap)
	# jamais plus de lignes que la zone n'en contient (même si la mesure du texte diffère du rendu)
	var max_lines := maxi(1, int(body.size.y / font.get_height(chosen)))
	c.draw_multiline_string(font, Vector2(body.position.x, body.position.y + font.get_ascent(chosen)), text, HORIZONTAL_ALIGNMENT_FILL, body.size.x, chosen, max_lines, Color("2a1c08"), TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND, TextServer.JUSTIFICATION_WORD_BOUND | TextServer.JUSTIFICATION_KASHIDA, TextServer.DIRECTION_RTL)


func _draw_script_lines(c: Control, body: Rect2, seed_v: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v * 131
	var lines := maxi(2, int(body.size.y / 26.0))
	var step := body.size.y / float(lines)
	for i in range(lines):
		var y := body.position.y + step * (float(i) + 0.5)
		var x := body.position.x
		var end_x := body.end.x if i < lines - 1 else body.position.x + body.size.x * rng.randf_range(0.4, 0.8)
		while x < end_x:
			var seg := rng.randf_range(4.0, 10.0)
			var dy := rng.randf_range(-1.5, 1.5)
			c.draw_line(Vector2(x, y + dy), Vector2(minf(x + seg, end_x), y + dy), Color(0.3, 0.22, 0.1, 0.55), 1.8, true)
			x += seg + rng.randf_range(1.5, 4.0)


# --- Vue d'ensemble : une case par page, rangées par juz. Or = retrouvée, blanc = manquante.

func _grid_layout(size_v: Vector2) -> Dictionary:
	var col_w := (size_v.x - 30.0) / 2.0
	var label_w := 74.0
	var cell_w := minf(26.0, (col_w - label_w - 8.0) / 23.0)
	var row_h := minf(40.0, (size_v.y - 44.0) / 15.0)
	return {"col_w": col_w, "label_w": label_w, "cell_w": cell_w, "row_h": row_h, "top": 34.0}


func _cell_rect(lay: Dictionary, page: int) -> Rect2:
	var juz: int = mushaf.juz_of_page(page)
	var first: int = mushaf.juz_range(juz).x
	var col := 0 if juz <= 15 else 1
	var row := (juz - 1) % 15
	var x: float = float(col) * (lay["col_w"] + 30.0) + lay["label_w"] + float(page - first) * lay["cell_w"]
	var y: float = lay["top"] + float(row) * lay["row_h"]
	return Rect2(x, y, lay["cell_w"] - 2.0, lay["row_h"] - 8.0)


func _draw_index(c: Control) -> void:
	var lay := _grid_layout(c.size)
	var font := Assets.font_book()
	c.draw_string(font, Vector2(0, 22), "Or : page retrouvée   ·   Rayures : page à moitié   ·   Blanc : page manquante   ·   Clique une case pour ouvrir la page", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.7))
	for juz in range(1, 31):
		var col := 0 if juz <= 15 else 1
		var row := (juz - 1) % 15
		var lx: float = float(col) * (lay["col_w"] + 30.0)
		var ly: float = lay["top"] + float(row) * lay["row_h"] + (lay["row_h"] - 8.0) * 0.72
		c.draw_string(font, Vector2(lx, ly), "Juz' %d" % juz, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.75))
	for p in range(1, mushaf.total_pages + 1):
		var r := _cell_rect(lay, p)
		var got: bool = save.has_page(p)
		var color := P.GOLD if got else Color(0.96, 0.95, 0.9, 0.9)
		c.draw_rect(r, color)
		var pg: Vector2i = save.page_progress(p)
		if not got and pg.x > 0:  # page à moitié retrouvée : autant de tranches dorées que de parties
			for k in range(pg.y):
				if save.has_part(p, int(mushaf.surah_ids_on_page(p)[k])):
					c.draw_rect(Rect2(r.position.x, r.position.y + r.size.y * float(k) / float(pg.y), r.size.x, r.size.y / float(pg.y)), P.GOLD)
		if got:
			c.draw_rect(Rect2(r.position.x, r.end.y - 3.0, r.size.x, 3.0), P.GOLD_DEEP)
		elif SHOW_PLACED_HINT and p in placed_pages:
			c.draw_rect(r.grow(-3.0), Color(P.GOLD, 0.9), false, 2.0)
		if mushaf.surahs_starting_on(p).size() > 0:
			c.draw_line(Vector2(r.position.x, r.position.y - 3.0), Vector2(r.end.x, r.position.y - 3.0), Color(1, 1, 1, 0.55), 2.0)
		if p == hover_page:
			c.draw_rect(r.grow(2.0), Color.WHITE, false, 2.0)


func view_input(v: Control, kind: String, event: InputEvent) -> void:
	if kind != "index":
		return
	if event is InputEventMouseMotion:
		var p := _page_at(v, event.position)
		if p != hover_page:
			hover_page = p
			v.queue_redraw()
			if p > 0:
				_tooltip.text = "Page %d — %s%s" % [p, mushaf.page_title(p), "" if save.has_page(p) else "  (manquante)"]
				_tooltip.visible = true
			else:
				_tooltip.visible = false
		if _tooltip.visible:
			_tooltip.position = get_local_mouse_position() + Vector2(16, 18)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p := _page_at(v, event.position)
		if p > 0:
			_tooltip.visible = false
			right_page = _spread_of(p)
			set_mode("book")


func _page_at(v: Control, pos: Vector2) -> int:
	var lay := _grid_layout(v.size)
	for p in range(1, mushaf.total_pages + 1):
		if _cell_rect(lay, p).grow(1.0).has_point(pos):
			return p
	return 0


# --- Liste des sourates avec leur progression

func _rebuild_surahs() -> void:
	for ch in _list.get_children():
		ch.queue_free()
	for s in mushaf.surahs:
		var id: int = int(s["id"])
		var rng: Vector2i = mushaf.surah_range(id)
		var have := 0
		for p in range(rng.x, rng.y + 1):
			if save.has_page(p):
				have += 1
		var total := rng.y - rng.x + 1
		var b := Button.new()
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.focus_mode = Control.FOCUS_NONE
		b.text = "%3d.  %s  ·  %s        %d / %d" % [id, s["name_fr"], s["name_ar"], have, total]
		if have == total:
			b.add_theme_color_override("font_color", P.GOLD)
		b.pressed.connect(func() -> void:
			right_page = _spread_of(int(s["start_page"]))
			set_mode("book"))
		_list.add_child(b)
