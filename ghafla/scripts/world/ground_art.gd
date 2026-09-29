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
	draw_polyline_colors(points, edge, 4.0, true)
