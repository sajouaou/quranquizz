extends RefCounted
## Collisions du monde, sans moteur physique : un sol en polylignes (le terrain), des plateformes à sens unique
## (pierres flottantes) et des blocs pleins (murs, plafonds, porte). Simple, déterministe, léger pour Android.
## Convention : y augmente vers le bas ; le personnage est un rectangle dont l'origine est sous les pieds.

const HALF_W := 17.0
const HEIGHT := 148.0

var lines: Array = []  # PackedVector2Array, x croissant : surface supérieure d'un sol plein
var platforms: Array = []  # Rect2 : seule la face supérieure porte, on peut la traverser par le dessous
var blockers: Array = []  # {"rect": Rect2, "on": bool}


func add_line(points: PackedVector2Array) -> void:
	lines.append(points)


func add_platform(rect: Rect2) -> void:
	platforms.append(rect)


func add_blocker(rect: Rect2) -> Dictionary:
	var b := {"rect": rect, "on": true}
	blockers.append(b)
	return b


## Plus haute surface porteuse à l'abscisse x, dont la hauteur est comprise entre y_lo et y_hi (bornes incluses).
## Renvoie INF s'il n'y en a pas.
func surface_between(x: float, y_lo: float, y_hi: float) -> float:
	var best := INF
	for line in lines:
		var first: Vector2 = line[0]
		var last: Vector2 = line[line.size() - 1]
		if x < first.x or x > last.x:
			continue
		var y := _line_y(line, x)
		if y >= y_lo and y <= y_hi and y < best:
			best = y
	for r in platforms:
		var rect: Rect2 = r
		if x >= rect.position.x and x <= rect.end.x:
			var y := rect.position.y
			if y >= y_lo and y <= y_hi and y < best:
				best = y
	return best


func ground_height(x: float, default_y: float = 620.0) -> float:
	var best := INF
	for line in lines:
		var first: Vector2 = line[0]
		var last: Vector2 = line[line.size() - 1]
		if x >= first.x and x <= last.x:
			best = minf(best, _line_y(line, x))
	return default_y if best == INF else best


func _line_y(line: PackedVector2Array, x: float) -> float:
	for i in range(line.size() - 1):
		var a := line[i]
		var b := line[i + 1]
		if x <= b.x:
			var span := b.x - a.x
			var t := 0.0 if span <= 0.0001 else (x - a.x) / span
			return lerpf(a.y, b.y, t)
	return line[line.size() - 1].y


func body_rect(x: float, feet_y: float) -> Rect2:
	return Rect2(x - HALF_W, feet_y - HEIGHT, HALF_W * 2.0, HEIGHT)


## Empêche de traverser un bloc horizontalement. Renvoie l'abscisse corrigée et si l'on a heurté quelque chose.
func resolve_x(new_x: float, feet_y: float, dir: float) -> Array:
	var rect := body_rect(new_x, feet_y)
	var hit := false
	var x := new_x
	for b in blockers:
		if not b["on"]:
			continue
		var br: Rect2 = b["rect"]
		if rect.intersects(br):
			hit = true
			x = br.position.x - HALF_W if dir > 0.0 else br.end.x + HALF_W
			rect = body_rect(x, feet_y)
	return [x, hit]


## Plafond : si la tête entre dans un bloc en montant, renvoie le y (pieds) corrigé, sinon NAN.
func resolve_head(x: float, new_feet_y: float) -> float:
	var rect := body_rect(x, new_feet_y)
	for b in blockers:
		if not b["on"]:
			continue
		var br: Rect2 = b["rect"]
		if rect.intersects(br):
			return br.end.y + HEIGHT
	return NAN
