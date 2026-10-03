extends Node
## Outil de développement : lance le jeu (vraie fenêtre), se place à plusieurs endroits des deux chapitres et enregistre
## des captures dans user://shots/ (Linux : ~/.local/share/godot/app_userdata/Ghafla/shots/).
## Usage : godot --path ghafla res://tests/dev/world_shots.tscn  [-- en]    (« en » : captures en anglais)
## Sauvegarde jetable : la vôtre n'est pas touchée.
const SaveData := preload("res://scripts/core/save_data.gd")
const I18n := preload("res://scripts/core/i18n.gd")
var main: Node

const SPOTS := {
	1: [["house", 500.0], ["living", 1600.0], ["street", 3000.0], ["hidden", 3560.0], ["market", 6500.0], ["market_end", 8050.0], ["cave", 10000.0], ["cave_hidden", 10380.0], ["peak", 14000.0]],
	2: [["love", 4000.0], ["parade", 8000.0], ["spirits", 11000.0], ["graves", 13300.0], ["graves_hidden", 14330.0], ["graves_mid", 15500.0]],
}

func _ready() -> void:
	var save := SaveData.get_instance()
	save.path = "user://ghafla_shots_save.json"
	save.reset_progress()
	save.note_seen = true
	save.intro_seen = true
	save.set_flag("c2_intro")
	save.set_flag("door_open")
	save.set_flag("c2_door_open")
	save.lang = "en" if "en" in OS.get_cmdline_user_args() else "fr"
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(main)
	main.get_node("QuranText").allow_network = false
	await _run()
	DirAccess.remove_absolute("user://ghafla_shots_save.json")
	get_tree().quit()

func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("user://shots")
	get_viewport().get_texture().get_image().save_png("user://shots/%s.png" % n)

func _run() -> void:
	await get_tree().create_timer(1.8).timeout
	await _shot("00_title")
	main.title._show_chapters()
	await get_tree().create_timer(0.6).timeout
	await _shot("01_chapters")
	main.title._hide_chapters()
	for chap in [1, 2]:
		main.debug_chapter(chap)
		await get_tree().create_timer(2.5).timeout
		for spot in SPOTS[chap]:
			main.world.debug_teleport(spot[1])
			await get_tree().create_timer(2.2).timeout
			main.dialogue.reset()
			main.world.player.frozen = false
			await _shot("c%d_%s" % [chap, spot[0]])
		# un long verset cité, pour vérifier que la fenêtre le contient en entier
		var id := "takathur" if chap == 1 else "khamr2"
		main._enqueue_reaction(id, main.reactions[id])
		await get_tree().create_timer(4.0).timeout
		await _shot("c%d_verse" % chap)
		main._back_to_title()
		await get_tree().create_timer(1.5).timeout
