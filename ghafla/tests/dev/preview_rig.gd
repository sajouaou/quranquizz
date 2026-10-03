extends Node2D
## Aperçu des poses du personnage (outil de développement).

const Rig := preload("res://scripts/cinematic/person_rig.gd")
const DrawUtil := preload("res://scripts/core/draw_util.gd")


func _ready() -> void:
	var poses := [
		{},
		{"walking": true},
		{"book": 2.0, "hip": Vector2(0, -46), "body_rot": 0.2, "head_tilt": 0.35, "hand_f": Vector2(30, 32), "hand_b": Vector2(24, 30), "skirt": 0.0, "foot_f": Vector2(44, -2), "foot_b": Vector2(38, -2)},
		{"body_rot": -PI / 2.0, "hip": Vector2(0, -30), "skirt": 0.0, "foot_f": Vector2(86, -30), "foot_b": Vector2(80, -30)},
		{"body_rot": -0.12, "hip": Vector2(0, -30), "skirt": 0.0, "foot_f": Vector2(86, -30), "foot_b": Vector2(80, -30)},
		{"reaching": 1.0},
		{"shade": 1.0},
		{"veil": true, "thobe_color": Color("2f6a5a")},
		{"head_scale": 1.22, "scale": Vector2(0.62, 0.62), "thobe_color": Color("5a8fd0")},
	]
	for i in range(poses.size()):
		var rig := Rig.new()
		rig.position = Vector2(80 + i * 140, 520)
		add_child(rig)
		for k in poses[i].keys():
			rig.set(k, poses[i][k])
		if poses[i].has("walking"):
			rig.phase = 0.9
	if "shot" in OS.get_cmdline_user_args():  # godot --path ghafla res://tests/dev/preview_rig.tscn -- shot
		await get_tree().create_timer(0.6).timeout
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("user://shots")
		get_viewport().get_texture().get_image().save_png("user://shots/rig.png")
		get_tree().quit()


func _draw() -> void:
	DrawUtil.vgrad(self, Rect2(0, 0, 1280, 720), Color("3b2f6e"), Color("f0a883"))
	draw_rect(Rect2(0, 520, 1280, 200), Color("2a1f4a"))
