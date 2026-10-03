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
var veil: bool = false  # voile (silhouette d'une mère) : capuche unie, toujours sans visage
var veil_color: Color = Color("e6d5ef")
var head_scale: float = 1.0  # un enfant a la tête un peu plus grosse par rapport au corps
var facing: int = 1:
	set(v):
		facing = 1 if v >= 0 else -1
		scale.x = absf(scale.x) * float(facing)  # garde la taille (enfant) : seul le sens change

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


## Membre effilé (une manche, une jambe) : large à la racine, plus fin au bout, avec un liseré sombre pour le détacher.
func _tapered(a: Vector2, b: Vector2, wa: float, wb: float, color: Color) -> void:
	var dir := (b - a).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.DOWN
	var n := Vector2(-dir.y, dir.x)
	var edge := color.darkened(0.28)
	var e := 1.3
	draw_colored_polygon(PackedVector2Array([a + n * (wa * 0.5 + e), b + n * (wb * 0.5 + e), b - n * (wb * 0.5 + e), a - n * (wa * 0.5 + e)]), edge)
	draw_circle(a, wa * 0.5 + e, edge)
	draw_circle(b, wb * 0.5 + e, edge)
	draw_colored_polygon(PackedVector2Array([a + n * wa * 0.5, b + n * wb * 0.5, b - n * wb * 0.5, a - n * wa * 0.5]), color)
	draw_circle(a, wa * 0.5, color)
	draw_circle(b, wb * 0.5, color)


## Main : une petite forme allongée dans le prolongement de l'avant-bras (ni doigts ni détail).
func _hand(elbow: Vector2, wrist: Vector2, color: Color, size: float = 1.0) -> void:
	var dir := (wrist - elbow).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.DOWN
	var pts := DrawUtil.ellipse(Vector2.ZERO, 6.4 * size, 4.4 * size, 14)
	draw_colored_polygon(_xf(pts, wrist + dir * 4.0 * size, dir.angle()), color)


func shoulder_pos() -> Vector2:
	return hip + Vector2(0, -TORSO + sin(_t * 1.6) * breath).rotated(body_rot)


func head_pos() -> Vector2:
	return shoulder_pos() + Vector2(0, -(HEAD_R * head_scale + 8.0)).rotated(body_rot + head_tilt)


## Position des mains dans le repère du personnage (utile pour poser un objet).
func hands_center() -> Vector2:
	var sh := shoulder_pos()
	return sh + ((hand_f + hand_b) * 0.5).rotated(body_rot)


func _draw() -> void:
	var sh := shoulder_pos()
	var thobe := _col(thobe_color)
	var thobe_far := _col(thobe_color.darkened(0.14))
	var thobe_shade := _col(thobe_color.darkened(0.09))
	var fold := _col(thobe_color.darkened(0.16))
	var skin := _col(P.SKIN)
	var skin_far := _col(P.SKIN.darkened(0.15))
	var shoe := _col(Color("3a2f2a"))
	var rot := body_rot

	# Jambes et bras : (racine, cible, longueurs, courbure)
	var leg_f := _ik(hip + Vector2(3, 0), foot_f, THIGH, SHIN, -1.0)
	var leg_b := _ik(hip + Vector2(-3, 0), foot_b, THIGH, SHIN, -1.0)
	var arm_f := _ik(sh, sh + hand_f.rotated(rot), UPPER_ARM, FOREARM, 1.0)
	var arm_b := _ik(sh, sh + hand_b.rotated(rot), UPPER_ARM, FOREARM, 1.0)

	# 1. bras éloigné : manche effilée, poignet, main
	_tapered(sh, arm_b[0], 13.0, 11.0, thobe_far)
	_tapered(arm_b[0], arm_b[1], 11.0, 9.5, thobe_far)
	_hand(arm_b[0], arm_b[1], skin_far, 0.92)

	# 2. jambe éloignée
	if skirt < 0.5:
		_tapered(hip, leg_b[0], 22.0, 18.0, thobe_far)
		_tapered(leg_b[0], leg_b[1], 18.0, 14.0, thobe_far)
	_foot(leg_b[1], shoe.darkened(0.1))

	# 3. tronc de profil : dos légèrement arrondi, poitrine, épaules, base du cou
	var torso := PackedVector2Array([
		Vector2(-14, 2), Vector2(15, 2), Vector2(16.5, -TORSO * 0.42), Vector2(15, -TORSO * 0.78), Vector2(11, -TORSO - 1.0),
		Vector2(5, -TORSO - 5.0), Vector2(-5, -TORSO - 5.0), Vector2(-11.5, -TORSO - 1.0), Vector2(-15.5, -TORSO * 0.74), Vector2(-15, -TORSO * 0.34),
	])
	draw_colored_polygon(_xf(torso, hip, rot), thobe)
	# le dos reste dans l'ombre : c'est ce qui donne son volume au buste
	var back := PackedVector2Array([Vector2(-14, 2), Vector2(-5, 2), Vector2(-4, -TORSO * 0.5), Vector2(-5, -TORSO - 5.0), Vector2(-11.5, -TORSO - 1.0), Vector2(-15.5, -TORSO * 0.74), Vector2(-15, -TORSO * 0.34)])
	draw_colored_polygon(_xf(back, hip, rot), thobe_shade)

	# 4. thobe long : il s'évase jusqu'à l'ourlet, suit les pieds, et tombe en plis
	if skirt >= 0.5:
		var hem_y := -9.0
		var sway_f := foot_f.x * 0.30
		var sway_b := foot_b.x * 0.30
		var front_x := 22.0 + sway_f
		var back_x := -21.0 + sway_b
		var skirt_pts := PackedVector2Array([Vector2(-15, hip.y - 1.0), Vector2(15, hip.y - 1.0), Vector2(18.5 + sway_f * 0.35, hip.y * 0.5)])
		var hem := PackedVector2Array()
		for k in range(7):  # l'ourlet est une courbe douce, un peu plus bas au milieu
			var u := float(k) / 6.0
			hem.append(Vector2(lerpf(front_x, back_x, u), hem_y + sin(u * PI) * 3.0))
		skirt_pts.append_array(hem)
		skirt_pts.append(Vector2(-19.0 + sway_b * 0.35, hip.y * 0.5))
		draw_colored_polygon(skirt_pts, thobe)
		# pan arrière dans l'ombre, dans la continuité du dos
		draw_colored_polygon(PackedVector2Array([Vector2(-15, hip.y - 1.0), Vector2(-5, hip.y - 1.0), Vector2(-6.0 + sway_b * 0.5, hem_y + 2.0), hem[5], hem[6], Vector2(-19.0 + sway_b * 0.35, hip.y * 0.5)]), thobe_shade)
		# plis du tissu, en éventail depuis la taille
		draw_line(Vector2(3, hip.y * 0.72), Vector2(5.0 + sway_f * 0.6, hem_y), fold, 1.8, true)
		draw_line(Vector2(9, hip.y * 0.5), Vector2(14.0 + sway_f * 0.8, hem_y - 1.0), fold, 1.4, true)
		draw_line(Vector2(-8, hip.y * 0.55), Vector2(-11.0 + sway_b * 0.7, hem_y + 1.0), _col(thobe_color.darkened(0.2)), 1.4, true)
		draw_polyline(hem, _col(thobe_color.darkened(0.24)), 2.0, true)
	else:
		_tapered(hip, leg_f[0], 24.0, 20.0, thobe)
		_tapered(leg_f[0], leg_f[1], 20.0, 15.0, thobe)
	_foot(leg_f[1], shoe)
	if skirt >= 0.5:
		_foot(leg_b[1], shoe.darkened(0.1))
	# patte de boutonnage : un trait fin sur la poitrine
	draw_line(hip + Vector2(8, -TORSO + 2.0).rotated(rot), hip + Vector2(9.5, -TORSO * 0.42).rotated(rot), fold, 1.4, true)

	# 5. tête (unie, sans aucun trait de visage) : cou, crâne ovale, calotte ou voile
	var hc := head_pos()
	var ang := rot + head_tilt
	var hr := HEAD_R * head_scale
	draw_colored_polygon(PackedVector2Array([sh + Vector2(-5.5, -3.0).rotated(rot), sh + Vector2(5.5, -3.0).rotated(rot), hc + Vector2(4.5, hr * 0.5).rotated(ang), hc + Vector2(-4.5, hr * 0.5).rotated(ang)]), skin_far)
	draw_colored_polygon(_xf(DrawUtil.ellipse(Vector2.ZERO, hr * 0.94, hr * 1.06, 22), hc, ang), skin_far)
	draw_colored_polygon(_xf(DrawUtil.ellipse(Vector2(2.2, -0.5), hr * 0.80, hr * 0.98, 20), hc, ang), skin)  # l'avant du crâne prend la lumière
	if veil:
		# voile ample : il couvre la tête, les épaules et retombe sur la poitrine et dans le dos, d'un seul tenant
		var vc := _col(veil_color)
		var vshade := _col(veil_color.darkened(0.12))
		draw_colored_polygon(_xf(DrawUtil.ellipse(Vector2.ZERO, hr + 4.5, hr + 5.0, 22), hc, ang), vc)
		var drape := PackedVector2Array([
			hc + Vector2(-hr - 4.0, 2.0).rotated(ang), hc + Vector2(hr + 4.0, 2.0).rotated(ang),
			sh + Vector2(19, 6).rotated(rot), sh + Vector2(21, 24).rotated(rot), sh + Vector2(12, 31).rotated(rot),
			sh + Vector2(-2, 28).rotated(rot), sh + Vector2(-15, 33).rotated(rot), sh + Vector2(-21, 22).rotated(rot), sh + Vector2(-18, 5).rotated(rot),
		])
		draw_colored_polygon(drape, vc)
		draw_colored_polygon(PackedVector2Array([hc + Vector2(-hr - 4.0, 2.0).rotated(ang), hc + Vector2(-2.0, 4.0).rotated(ang), sh + Vector2(-4, 27).rotated(rot), sh + Vector2(-15, 33).rotated(rot), sh + Vector2(-21, 22).rotated(rot), sh + Vector2(-18, 5).rotated(rot)]), vshade)
		draw_line(hc + Vector2(hr * 0.5, hr + 2.0).rotated(ang), sh + Vector2(10, 29).rotated(rot), vshade, 1.6, true)
	else:
		# calotte : une coiffe basse avec son bandeau
		var cap := PackedVector2Array()
		for k in range(13):
			var a := lerpf(-PI * 0.98, -PI * 0.02, float(k) / 12.0)
			cap.append(Vector2(cos(a) * (hr * 0.96 + 0.8), sin(a) * (hr * 1.06 + 1.6)))
		cap.append(Vector2(hr * 0.96 + 0.8, 0.5))
		cap.append(Vector2(-hr * 0.96 - 0.8, 0.5))
		draw_colored_polygon(_xf(cap, hc, ang), _col(Color("f2eee4")))
		draw_line(hc + Vector2(-hr * 0.96 - 0.8, -0.5).rotated(ang), hc + Vector2(hr * 0.96 + 0.8, -0.5).rotated(ang), _col(Color("cfc8b8")), 2.2, true)

	# 6. livre entre les mains
	if book > 0.0:
		_draw_book(arm_f[1], arm_b[1])

	# 7. bras proche : manche effilée, poignet, main
	_tapered(sh, arm_f[0], 14.0, 12.0, thobe)
	_tapered(arm_f[0], arm_f[1], 12.0, 10.0, thobe)
	draw_line(arm_f[1] + (arm_f[1] - arm_f[0]).normalized().orthogonal() * 5.0, arm_f[1] - (arm_f[1] - arm_f[0]).normalized().orthogonal() * 5.0, fold, 1.6, true)
	_hand(arm_f[0], arm_f[1], skin)


## Chaussure de profil : talon, semelle, pointe arrondie.
func _foot(ankle: Vector2, color: Color) -> void:
	var pts := PackedVector2Array([Vector2(-5, 0), Vector2(15, 0), Vector2(17.5, -2.5), Vector2(15.5, -5.5), Vector2(6, -8.5), Vector2(-4, -8)])
	draw_colored_polygon(_xf(pts, ankle + Vector2(0, 1.5), 0.0), color)
	draw_line(ankle + Vector2(-5, 1.0), ankle + Vector2(16, 1.0), color.darkened(0.35), 1.6, true)


func _draw_book(h1: Vector2, h2: Vector2) -> void:
	var mid := (h1 + h2) * 0.5 + Vector2(2, -6).rotated(body_rot)
	var a := body_rot
	if book < 1.5:
		var pts := PackedVector2Array([Vector2(-14, -20), Vector2(14, -20), Vector2(14, 20), Vector2(-14, 20)])
		var out := PackedVector2Array()
		for p in pts:
			out.append(mid + p.rotated(a))
		draw_colored_polygon(out, _col(P.EMERALD))
		draw_colored_polygon(_xf(DrawUtil.star(Vector2.ZERO, 8.0, 4.2, 8), mid, a), _col(P.GOLD))
	else:
		var left := PackedVector2Array([Vector2(-27, -18), Vector2(0, -15), Vector2(0, 20), Vector2(-27, 23)])
		var right := PackedVector2Array([Vector2(0, -15), Vector2(27, -18), Vector2(27, 23), Vector2(0, 20)])
		draw_colored_polygon(_xf(left, mid, a), _col(P.PARCHMENT))
		draw_colored_polygon(_xf(right, mid, a), _col(P.PARCHMENT_SHADE))
		var cover := PackedVector2Array([Vector2(-30, -17), Vector2(30, -17), Vector2(30, 27), Vector2(-30, 27)])
		draw_polyline(_xf(cover, mid, a), _col(P.EMERALD), 2.0, true)


func _xf(points: PackedVector2Array, origin: Vector2, angle: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in points:
		out.append(origin + p.rotated(angle))
	return out
