extends Node2D
## Personnage de profil dessiné en code, SANS visage : une tête unie, la silhouette d'un homme en thobe.
## Il sert à la cinématique et au jeu. Le squelette est piloté par quelques paramètres (hanche, rotation du
## buste, cibles des mains et des pieds), résolus par une cinématique inverse à deux os.
## Repère : l'origine est au sol, sous les pieds ; il regarde vers +x (retourner avec `facing`).

const P := preload("res://scripts/core/palette.gd")
const DrawUtil := preload("res://scripts/core/draw_util.gd")

const THIGH := 44.0
const SHIN := 44.0
const TORSO := 56.0
const UPPER_ARM := 30.0
const FOREARM := 28.0
const HEAD_R := 14.0

# --- Pose (animable avec des Tween) ---
var hip: Vector2 = Vector2(0, -86)
var body_rot: float = 0.0  # buste autour de la hanche : + penche vers l'avant, -PI/2 couché
var head_tilt: float = 0.0
var hand_f: Vector2 = Vector2(6, 50)  # relatif à l'épaule, dans le repère du buste
var hand_b: Vector2 = Vector2(2, 50)
var foot_f: Vector2 = Vector2(10, 0)
var foot_b: Vector2 = Vector2(-10, 0)
var skirt: float = 1.0  # 1 : thobe long (debout) ; 0 : jambes visibles (assis, couché)
var book: float = 0.0  # 0 rien, 1 livre fermé, 2 livre ouvert

# --- Aspect ---
var shade: float = 0.0  # 0 normal, 1 silhouette à contre-jour
var shade_color: Color = Color(0.03, 0.03, 0.08)
var thobe_color: Color = P.THOBE
var facing: int = 1:
	set(v):
		facing = 1 if v >= 0 else -1
		scale.x = float(facing)

# --- Marche automatique (jeu) ---
var walking: bool = false
var running: bool = false
var airborne: bool = false
var reaching: float = 0.0
var phase: float = 0.0
var breath: float = 0.0  # respiration (buste qui monte et descend)
var _t: float = 0.0


func _process(delta: float) -> void:
	_t += delta
	if walking and not airborne:
		phase += delta * (11.0 if running else 8.0)
	if airborne or walking or reaching > 0.0:
		_apply_motion()
	queue_redraw()


func reset_pose() -> void:
	hip = Vector2(0, -86)
	body_rot = 0.0
	head_tilt = 0.0
	hand_f = Vector2(6, 50)
	hand_b = Vector2(2, 50)
	foot_f = Vector2(10, 0)
	foot_b = Vector2(-10, 0)
	skirt = 1.0
	book = 0.0


## Anime plusieurs propriétés à la fois : pose({"hip": Vector2(0, -40), "body_rot": 0.3}, 1.2).
func pose(values: Dictionary, duration: float = 0.6, trans: Tween.TransitionType = Tween.TRANS_SINE) -> Tween:
	var tw := create_tween().set_parallel(true).set_trans(trans).set_ease(Tween.EASE_IN_OUT)
	for key in values.keys():
		tw.tween_property(self, str(key), values[key], duration)
	return tw


func _apply_motion() -> void:
	if airborne:
		hip = Vector2(0, -80)
		foot_f = Vector2(18, -22)
		foot_b = Vector2(-10, -12)
		hand_f = Vector2(22, 24)
		hand_b = Vector2(10, 30)
		body_rot = 0.06
	elif walking:
		var stride := 30.0 if running else 24.0
		var s := sin(phase)
		var c := cos(phase)
		hip = Vector2(0, -86 + absf(s) * 2.5)
		foot_f = Vector2(s * stride, -maxf(0.0, c) * 11.0)
		foot_b = Vector2(-s * stride, -maxf(0.0, -c) * 11.0)
		hand_f = Vector2(6 - s * 16.0, 50.0 - absf(c) * 4.0)
		hand_b = Vector2(2 + s * 16.0, 50.0)
		body_rot = 0.10 if running else 0.03
	if reaching > 0.0:
		hand_f = hand_f.lerp(Vector2(52, -8), reaching)
		hand_b = hand_b.lerp(Vector2(44, 2), reaching * 0.7)
		body_rot = lerpf(body_rot, 0.14, reaching)


func _col(c: Color) -> Color:
	return c.lerp(shade_color, shade)


func _ik(root: Vector2, target: Vector2, l1: float, l2: float, bend: float) -> Array:
	var reach := root.distance_to(target)
	reach = clampf(reach, absf(l1 - l2) + 0.01, l1 + l2 - 0.01)
	var dir := (target - root).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.DOWN
	var a := (l1 * l1 - l2 * l2 + reach * reach) / (2.0 * reach)
	var h := sqrt(maxf(l1 * l1 - a * a, 0.0))
	var joint := root + dir * a + Vector2(-dir.y, dir.x) * bend * h
	var end := root + dir * reach
	return [joint, end]


func _limb(a: Vector2, b: Vector2, w: float, color: Color, outline: bool = false) -> void:
	if outline:
		var edge := color.darkened(0.28)
		draw_line(a, b, edge, w + 2.5, true)
		draw_circle(a, w * 0.5 + 1.25, edge)
		draw_circle(b, w * 0.5 + 1.25, edge)
	draw_line(a, b, color, w, true)
	draw_circle(a, w * 0.5, color)
	draw_circle(b, w * 0.5, color)


func shoulder_pos() -> Vector2:
	return hip + Vector2(0, -TORSO + sin(_t * 1.6) * breath).rotated(body_rot)


func head_pos() -> Vector2:
	return shoulder_pos() + Vector2(0, -(HEAD_R + 8.0)).rotated(body_rot + head_tilt)


## Position des mains dans le repère du personnage (utile pour poser un objet).
func hands_center() -> Vector2:
	var sh := shoulder_pos()
	return sh + ((hand_f + hand_b) * 0.5).rotated(body_rot)


func _draw() -> void:
	var sh := shoulder_pos()
	var thobe := _col(thobe_color)
	var thobe_far := _col(thobe_color.darkened(0.14))
	var skin := _col(P.SKIN)
	var skin_far := _col(P.SKIN.darkened(0.15))
	var shoe := _col(Color("3a2f2a"))

	# Jambes et bras : (racine, cible, longueurs, courbure)
	var leg_f := _ik(hip + Vector2(3, 0), foot_f, THIGH, SHIN, -1.0)
	var leg_b := _ik(hip + Vector2(-3, 0), foot_b, THIGH, SHIN, -1.0)
	var arm_f := _ik(sh, sh + hand_f.rotated(body_rot), UPPER_ARM, FOREARM, 1.0)
	var arm_b := _ik(sh, sh + hand_b.rotated(body_rot), UPPER_ARM, FOREARM, 1.0)

	# 1. bras éloigné
	_limb(sh, arm_b[0], 12.0, thobe_far, true)
	_limb(arm_b[0], arm_b[1], 10.0, thobe_far, true)
	draw_circle(arm_b[1], 4.6, skin_far)

	# 2. jambe éloignée
	if skirt < 0.5:
		_limb(hip, leg_b[0], 21.0, thobe_far)
		_limb(leg_b[0], leg_b[1], 17.0, thobe_far)
	_foot(leg_b[1], shoe.darkened(0.1))

	# 3. tronc
	var torso := PackedVector2Array([
		hip + Vector2(-15, 0).rotated(body_rot),
		hip + Vector2(15, 0).rotated(body_rot),
		hip + Vector2(14, -TORSO * 0.55).rotated(body_rot),
		hip + Vector2(11, -TORSO).rotated(body_rot),
		hip + Vector2(-11, -TORSO).rotated(body_rot),
		hip + Vector2(-14, -TORSO * 0.5).rotated(body_rot),
	])
	draw_colored_polygon(torso, thobe)

	# 4. thobe long, qui suit les pieds
	if skirt >= 0.5:
		var hem_y := -10.0
		var sway_f := foot_f.x * 0.30
		var sway_b := foot_b.x * 0.30
		var skirt_pts := PackedVector2Array([
			Vector2(-15, hip.y),
			Vector2(15, hip.y),
			Vector2(19 + sway_f * 0.4, hip.y * 0.45),
			Vector2(22 + sway_f, hem_y),
			Vector2(-20 + sway_b, hem_y),
			Vector2(-19 + sway_b * 0.4, hip.y * 0.45),
		])
		draw_colored_polygon(skirt_pts, thobe)
		# pli discret du tissu
		draw_line(Vector2(2, hip.y * 0.7), Vector2(3 + sway_f * 0.6, hem_y - 2), _col(thobe_color.darkened(0.08)), 2.0, true)
	else:
		_limb(hip, leg_f[0], 23.0, thobe, true)
		_limb(leg_f[0], leg_f[1], 19.0, thobe, true)
	_foot(leg_f[1], shoe)
	if skirt >= 0.5:
		_foot(leg_b[1], shoe.darkened(0.1))

	# 5. tête (unie, sans traits) : cou, crâne, calotte
	var hc := head_pos()
	var ang := body_rot + head_tilt
	draw_line(sh, hc, skin, 9.0, true)
	draw_circle(hc, HEAD_R, skin)
	var cap := PackedVector2Array()
	for i in range(13):
		var a := lerpf(-PI * 0.97, -PI * 0.03, float(i) / 12.0)
		cap.append(Vector2(cos(a), sin(a)) * (HEAD_R + 0.8))
	for i in range(6):
		var t := float(i) / 5.0
		cap.append(Vector2(lerpf(HEAD_R * 0.98, -HEAD_R * 0.98, t), -1.5 + sin(t * PI) * 2.5))
	var cap_world := PackedVector2Array()
	for v in cap:
		cap_world.append(hc + v.rotated(ang))
	draw_colored_polygon(cap_world, _col(Color("f2eee4")))

	# 6. livre entre les mains
	if book > 0.0:
		_draw_book(arm_f[1], arm_b[1])

	# 7. bras proche
	_limb(sh, arm_f[0], 13.0, thobe, true)
	_limb(arm_f[0], arm_f[1], 11.0, thobe, true)
	draw_circle(arm_f[1], 5.0, skin)


func _foot(ankle: Vector2, color: Color) -> void:
	draw_line(ankle + Vector2(0, -1), ankle + Vector2(13, -1), color, 8.0, true)
	draw_circle(ankle + Vector2(13, -1), 4.0, color)


func _draw_book(h1: Vector2, h2: Vector2) -> void:
	var mid := (h1 + h2) * 0.5 + Vector2(2, -6).rotated(body_rot)
	var a := body_rot
	if book < 1.5:
		var pts := PackedVector2Array([Vector2(-11, -16), Vector2(11, -16), Vector2(11, 16), Vector2(-11, 16)])
		var out := PackedVector2Array()
		for p in pts:
			out.append(mid + p.rotated(a))
		draw_colored_polygon(out, _col(P.EMERALD))
		draw_colored_polygon(_xf(DrawUtil.star(Vector2.ZERO, 6.0, 3.2, 8), mid, a), _col(P.GOLD))
	else:
		var left := PackedVector2Array([Vector2(-22, -14), Vector2(0, -12), Vector2(0, 16), Vector2(-22, 18)])
		var right := PackedVector2Array([Vector2(0, -12), Vector2(22, -14), Vector2(22, 18), Vector2(0, 16)])
		draw_colored_polygon(_xf(left, mid, a), _col(P.PARCHMENT))
		draw_colored_polygon(_xf(right, mid, a), _col(P.PARCHMENT_SHADE))
		var cover := PackedVector2Array([Vector2(-24, -13), Vector2(24, -13), Vector2(24, 21), Vector2(-24, 21)])
		draw_polyline(_xf(cover, mid, a), _col(P.EMERALD), 2.0, true)


func _xf(points: PackedVector2Array, origin: Vector2, angle: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in points:
		out.append(origin + p.rotated(angle))
	return out
