extends Node
## Outil de développement : mesure le coût d'une image à plusieurs endroits des deux chapitres (synchronisation verticale
## coupée, images non limitées). Affiche, par endroit : images par seconde et temps de calcul d'une image (ms).
## Usage : godot --path ghafla res://tests/dev/bench.tscn  [-- low|medium|high]
const SaveData := preload("res://scripts/core/save_data.gd")
var main: Node

const SPOTS := {
	1: [["house", 500.0], ["street", 3000.0], ["market", 6500.0], ["cave", 10000.0], ["peak", 14000.0]],
	2: [["love", 4000.0], ["parade", 8000.0], ["spirits", 11000.0], ["graves", 15000.0]],
}

func _ready() -> void:
	var save := SaveData.get_instance()
	save.path = "user://ghafla_bench_save.json"
	save.reset_progress()
	save.note_seen = true
	save.intro_seen = true
	save.lang = "fr"
	save.set_flag("c2_intro")
	save.set_flag("door_open")
	save.set_flag("c2_door_open")
	for a in OS.get_cmdline_user_args():
		if a in ["low", "medium", "high"]:
			save.quality = ["low", "medium", "high"].find(a)
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(main)
	main.get_node("QuranText").allow_network = false
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	await get_tree().create_timer(1.0).timeout
	var total_ms := 0.0
	var n := 0
	for chap in [1, 2]:
		main.debug_chapter(chap)
		await get_tree().create_timer(1.5).timeout
		for spot in SPOTS[chap]:
			main.world.debug_teleport(spot[1])
			await get_tree().create_timer(1.0).timeout
			main.dialogue.reset()
			# le personnage marche pendant la mesure : c'est le cas coûteux (tout le décor défile)
			main.world.player.frozen = false
			main.world.player.use_scripted_input = true
			main.world.player.input_x = 1.0
			var frames := 0
			var proc := 0.0
			var t0 := Time.get_ticks_usec()
			while Time.get_ticks_usec() - t0 < 2000000:
				await get_tree().process_frame
				frames += 1
				proc += Performance.get_monitor(Performance.TIME_PROCESS)
			main.world.player.input_x = 0.0
			var ms := 2000.0 / float(frames)
			total_ms += ms
			n += 1
			print("[bench] c%d %-8s %6.0f img/s  %5.2f ms/image  (script+dessin %5.2f ms, %d nœuds)" % [chap, spot[0], float(frames) / 2.0, ms, proc / float(frames) * 1000.0, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))])
		main._back_to_title()
		await get_tree().create_timer(1.2).timeout
	print("[bench] moyenne %.2f ms/image" % (total_ms / float(n)))
	DirAccess.remove_absolute("user://ghafla_bench_save.json")
	get_tree().quit()
