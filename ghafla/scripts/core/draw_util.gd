extends RefCounted
## Petites fonctions de dessin partagées : dégradés, halos, formes géométriques.
## Tout le jeu est dessiné en code (aucune image), pour rester léger et sans idole ni figure.

static var _glow: GradientTexture2D
static var _boxes: Dictionary = {}


static func glow_texture() -> GradientTexture2D:
	if _glow == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.28), Color(1, 1, 1, 0.0)])
		_glow = GradientTexture2D.new()
		_glow.gradient = g
		_glow.fill = GradientTexture2D.FILL_RADIAL
		_glow.fill_from = Vector2(0.5, 0.5)
		_glow.fill_to = Vector2(1.0, 0.5)
		_glow.width = 256
		_glow.height = 256
	return _glow


## Halo doux (à dessiner sur un nœud au mélange additif pour l'effet lumineux).
static func glow(ci: CanvasItem, pos: Vector2, radius: float, color: Color) -> void:
	var r := Vector2(radius, radius)
	ci.draw_texture_rect(glow_texture(), Rect2(pos - r, r * 2.0), false, color)


static func vgrad(ci: CanvasItem, rect: Rect2, top: Color, bottom: Color) -> void:
	var p := PackedVector2Array([
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
	])
	ci.draw_polygon(p, PackedColorArray([top, top, bottom, bottom]))


static func hgrad(ci: CanvasItem, rect: Rect2, left: Color, right: Color) -> void:
	var p := PackedVector2Array([
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
	])
	ci.draw_polygon(p, PackedColorArray([left, right, right, left]))


static func rrect(ci: CanvasItem, rect: Rect2, color: Color, radius: float = 8.0, border: Color = Color(0, 0, 0, 0), border_w: int = 0) -> void:
	var key := "%s|%s|%s|%s" % [color.to_html(true), radius, border.to_html(true), border_w]
	var sb: StyleBoxFlat = _boxes.get(key)
	if sb == null:
		sb = StyleBoxFlat.new()
		sb.bg_color = color
		sb.set_corner_radius_all(int(radius))
		sb.anti_aliasing = true
		if border_w > 0:
			sb.border_color = border
			sb.set_border_width_all(border_w)
		_boxes[key] = sb
	ci.draw_style_box(sb, rect)


static func ellipse(center: Vector2, rx: float, ry: float, n: int = 32) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(n):
		var a := TAU * float(i) / float(n)
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


## Étoile régulière à n branches (motif géométrique : ni figure ni représentation).
static func star(center: Vector2, r_out: float, r_in: float, n: int = 8, rot: float = 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(n * 2):
		var r := r_out if i % 2 == 0 else r_in
		var a := rot + PI * float(i) / float(n) - PI / 2.0
		pts.append(center + Vector2(cos(a), sin(a)) * r)
	return pts


## Croissant de lune : grand cercle (rayon r) privé d'un cercle plus petit décalé vers la droite.
## `cut` règle l'épaisseur (0.3 = très fin, 0.6 = épais). Le croissant s'ouvre vers +x avant rotation.
static func crescent(center: Vector2, r: float, cut: float = 0.42, rot: float = 0.0) -> PackedVector2Array:
	var d := r * cut * 2.0
	var rb := r * 0.86
	var x0 := (d * d + r * r - rb * rb) / (2.0 * d)
	var y0 := sqrt(maxf(r * r - x0 * x0, 0.0))
	var a_top := atan2(-y0, x0)
	var a_bot := atan2(y0, x0)
	var b_top := atan2(-y0, x0 - d)
	var b_bot := atan2(y0, x0 - d)
	var pts := PackedVector2Array()
	var steps := 26
	# arc extérieur : du bas vers le haut en passant par la gauche
	for i in range(steps + 1):
		var a := lerpf(a_bot, a_top + TAU, float(i) / float(steps))
		pts.append(center + Vector2(cos(a), sin(a)).rotated(rot) * r)
	# arc intérieur (bord du cercle retranché) : du haut vers le bas en passant par sa gauche
	for i in range(1, steps):
		var a := lerpf(b_top + TAU, b_bot, float(i) / float(steps))
		var q := Vector2(d + cos(a) * rb, sin(a) * rb)
		pts.append(center + q.rotated(rot))
	return pts


## Ligne d'horizon ondulée (somme de sinus), utile pour collines et montagnes.
static func hills(rng: RandomNumberGenerator, x0: float, x1: float, base_y: float, amp: float, step: float = 40.0) -> PackedVector2Array:
	var p1 := rng.randf() * TAU
	var p2 := rng.randf() * TAU
	var p3 := rng.randf() * TAU
	var pts := PackedVector2Array()
	var x := x0
	while x <= x1 + 0.01:
		var y := base_y
		y -= sin(x * 0.0031 + p1) * amp * 0.55
		y -= sin(x * 0.0083 + p2) * amp * 0.30
		y -= sin(x * 0.0197 + p3) * amp * 0.15
		pts.append(Vector2(x, y))
		x += step
	return pts


## Remplit l'espace entre une polyligne (x croissant) et la droite horizontale y = edge_y, par bandes.
## Plus robuste que draw_colored_polygon sur de longues courbes presque colinéaires, dont la triangulation échoue parfois.
static func fill_to(ci: CanvasItem, line: PackedVector2Array, edge_y: float, color: Color) -> void:
	for i in range(line.size() - 1):
		var a := line[i]
		var b := line[i + 1]
		if b.x - a.x < 0.01:
			continue
		var quad := PackedVector2Array([a, b, Vector2(b.x, edge_y), Vector2(a.x, edge_y)])
		if absf(a.y - edge_y) < 0.01 and absf(b.y - edge_y) < 0.01:
			continue
		if absf(a.y - edge_y) < 0.01:
			quad = PackedVector2Array([a, b, Vector2(b.x, edge_y)])
		elif absf(b.y - edge_y) < 0.01:
			quad = PackedVector2Array([a, b, Vector2(a.x, edge_y)])
		ci.draw_colored_polygon(quad, color)


## Comme fill_to, avec un dégradé vertical et une couleur de haut propre à chaque sommet.
static func fill_gradient(ci: CanvasItem, line: PackedVector2Array, edge_y: float, top_colors: PackedColorArray, bottom_color: Callable) -> void:
	for i in range(line.size() - 1):
		var a := line[i]
		var b := line[i + 1]
		if b.x - a.x < 0.01 or absf(a.y - edge_y) < 0.01 or absf(b.y - edge_y) < 0.01:
			continue
		var quad := PackedVector2Array([a, b, Vector2(b.x, edge_y), Vector2(a.x, edge_y)])
		var cols := PackedColorArray([top_colors[i], top_colors[i + 1], bottom_color.call(b.x), bottom_color.call(a.x)])
		ci.draw_polygon(quad, cols)


static func close_down(line: PackedVector2Array, bottom_y: float) -> PackedVector2Array:
	var poly := PackedVector2Array(line)
	poly.append(Vector2(line[line.size() - 1].x, bottom_y))
	poly.append(Vector2(line[0].x, bottom_y))
	return poly


static func lerp_y(line: PackedVector2Array, x: float) -> float:
	if line.is_empty():
		return 0.0
	if x <= line[0].x:
		return line[0].y
	for i in range(line.size() - 1):
		var a := line[i]
		var b := line[i + 1]
		if x <= b.x:
			var t := 0.0 if is_equal_approx(a.x, b.x) else (x - a.x) / (b.x - a.x)
			return lerpf(a.y, b.y, t)
	return line[line.size() - 1].y


static func with_alpha(c: Color, a: float) -> Color:
	return Color(c.r, c.g, c.b, c.a * a)


## Chiffres arabes orientaux (٠١٢…) pour afficher les numéros de page à la manière d'un mushaf.
static func arabic_digits(n: int) -> String:
	var out := ""
	for ch in str(n):
		out += String.chr(0x0660 + int(ch))
	return out
