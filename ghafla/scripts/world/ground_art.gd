extends Node2D
## Dessin d'un terrain : polygone en dégradé, bord, petits détails. La couleur varie avec la position en x.

const DrawUtil := preload("res://scripts/core/draw_util.gd")

var points: PackedVector2Array = PackedVector2Array()
var stops: Array = []  # [x, couleur du haut, couleur du bas, couleur du bord, densité de détails]
var bottom_y: float = 1800.0
var detail_seed: int = 7


func _stop_at(x: float) -> Array:
	if stops.is_empty():
		return [x, Color("3a2f5a"), Color("1a1430"), Color("6a5a8a"), 0.0]
	if x <= stops[0][0]:
		return stops[0]
	for i in range(stops.size() - 1):
		var a: Array = stops[i]
		var b: Array = stops[i + 1]
		if x <= b[0]:
			var t := smoothstep(a[0], b[0], x)
			return [x, (a[1] as Color).lerp(b[1], t), (a[2] as Color).lerp(b[2], t), (a[3] as Color).lerp(b[3], t), lerpf(a[4], b[4], t)]
	return stops[stops.size() - 1]


func _draw() -> void:
	if points.size() < 2:
		return
	var colors := PackedColorArray()
	for p in points:
		colors.append(_stop_at(p.x)[1])
	var first := points[0]
	var last := points[points.size() - 1]
	DrawUtil.fill_gradient(self, points, bottom_y, colors, func(x: float) -> Color: return _stop_at(x)[2])

	var edge := PackedColorArray()
	for p in points:
		edge.append(_stop_at(p.x)[3])
	# Profondeur : le sol est un plan qui s'éloigne du regard. Des filets parallèles, de plus en plus sombres et fins,
	# lui donnent une épaisseur (comme une scène de théâtre vue légèrement d'en haut), et une arête claire accroche la lumière.
	var depth_lines := [[16.0, 0.20, 3.0], [40.0, 0.14, 2.0], [76.0, 0.09, 2.0], [128.0, 0.05, 1.5]]
	for d in depth_lines:
		var shifted := PackedVector2Array()
		var dcol := PackedColorArray()
		for p in points:
			shifted.append(p + Vector2(0.0, d[0]))
			var c: Color = (_stop_at(p.x)[3] as Color).darkened(0.45)
			dcol.append(Color(c.r, c.g, c.b, d[1]))
		draw_polyline_colors(shifted, dcol, d[2], true)
	draw_polyline_colors(points, edge, 4.0, true)
	var rim := PackedColorArray()
	var rim_pts := PackedVector2Array()
	for p in points:
		var c: Color = (_stop_at(p.x)[3] as Color).lightened(0.35)
		rim.append(Color(c.r, c.g, c.b, 0.55))
		rim_pts.append(p + Vector2(0.0, -1.5))
	draw_polyline_colors(rim_pts, rim, 1.6, true)
