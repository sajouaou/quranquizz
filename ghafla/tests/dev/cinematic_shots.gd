extends Node
## Outil de développement : joue les deux cinématiques (vraie fenêtre, temps accéléré) et enregistre une capture
## toutes les 3 secondes de film dans user://shots/cin1_XX.png et cin2_XX.png.
## Usage : godot --path ghafla res://tests/dev/cinematic_shots.tscn  [-- 2]   (« 2 » : seulement la seconde)

const Inputs := preload("res://scripts/core/inputs.gd")
const Sfx := preload("res://scripts/core/sfx.gd")
const I18n := preload("res://scripts/core/i18n.gd")
const UiTheme := preload("res://scripts/ui/ui_theme.gd")
const Cinematic1 := preload("res://scripts/cinematic/cinematic.gd")
const Cinematic2 := preload("res://scripts/cinematic/cinematic2.gd")


func _ready() -> void:
	Inputs.ensure_actions()
	add_child(Sfx.new())
	Sfx.set_master(0.0)
	I18n.set_language("fr")
	get_tree().root.content_scale_size = Vector2i(1280, 720)
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	DirAccess.make_dir_recursive_absolute("user://shots")
	var only2: bool = "2" in OS.get_cmdline_user_args()
	Engine.time_scale = 3.0
	for n in ([2] if only2 else [1, 2]):
		var cin: Node2D = Cinematic1.new() if n == 1 else Cinematic2.new()
		add_child(cin)
		var done := [false]
		cin.finished.connect(func() -> void: done[0] = true)
		cin.run()
		var i := 0
		while not done[0] and i < 40:
			await get_tree().create_timer(3.0).timeout
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("user://shots/cin%d_%02d.png" % [n, i])
			i += 1
		cin.queue_free()
		await get_tree().process_frame
	Engine.time_scale = 1.0
	get_tree().quit()
