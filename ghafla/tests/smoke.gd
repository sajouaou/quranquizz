extends Node
## Parcours de fumée : démarre la vraie scène principale et enchaîne menu, note, cinématique, jeu, page, livre, pause, retour au menu,
## reprise et fin. Vérifie l'état à chaque étape ; tools/test.sh refuse aussi toute ligne « SCRIPT ERROR » dans la sortie.
## Lancer : godot --headless --fixed-fps 60 --path ghafla res://tests/smoke_runner.tscn

const SaveData := preload("res://scripts/core/save_data.gd")
const I18n := preload("res://scripts/core/i18n.gd")

var main: Node
var failed: int = 0
var passed: int = 0


func _ready() -> void:
	# sauvegarde jetable : on ne touche pas à celle du joueur
	var save := SaveData.get_instance()
	save.path = "user://ghafla_smoke_save.json"
	save.reset_progress()
	save.note_seen = false
	save.lang = ""
	var scene: PackedScene = load("res://scenes/main.tscn")
	main = scene.instantiate()
	add_child(main)
	main.get_node("QuranText").allow_network = false  # pas de réseau dans les tests
	await _run()
	DirAccess.remove_absolute("user://ghafla_smoke_save.json")
	print("[smoke] ---------------------------------")
	print("[smoke] %d réussis, %d échoués" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)


func ok(cond: bool, label: String) -> void:
	if cond:
		passed += 1
		print("[smoke] ok    ", label)
	else:
		failed += 1
		print("[smoke] ECHEC ", label)


func _state() -> String:
	return str(main.State.keys()[main.state])


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _until(cond: Callable, max_seconds: float) -> bool:
	var t := 0.0
	while t < max_seconds:
		if cond.call():
			return true
		await get_tree().create_timer(0.1).timeout
		t += 0.1
	return cond.call()


func _flush_dialogue() -> void:
	for i in range(40):
		main.debug_advance(4)
		await _wait(0.2)
		if not main.dialogue.active and main._scene_queue.is_empty():
			break


func _run() -> void:
	await _wait(1.0)
	# tout premier démarrage : aucune langue choisie, le jeu la demande avant le menu
	ok(_state() == "LANGUAGE" and main.ui_root.has_node("LanguageChoice") and main.title == null, "premier démarrage : le choix de la langue s'affiche avant le menu")
	main.ui_root.get_node("LanguageChoice").chosen.emit("fr")
	await _wait(1.5)
	ok(main.save.lang == "fr" and I18n.lang == "fr", "la langue choisie est enregistrée")
	ok(_state() == "TITLE", "puis le menu principal")

	# changer de langue reconstruit l'interface et recharge les scènes dans la nouvelle langue, puis retour au français
	main.save.lang = "en"
	I18n.set_language("en")
	main._on_language_changed()
	await _wait(1.2)
	ok(_state() == "TITLE" and main.title != null and main.reactions["fatiha"]["lines"][0].begins_with("Al-Fatiha… Seventeen"), "langue anglaise : menu reconstruit et scènes traduites")
	ok(main.hud._count_label != null and main.pause_menu != null, "l'interface en jeu est reconstruite")
	main.save.lang = "fr"
	I18n.set_language("fr")
	main._on_language_changed()
	await _wait(1.2)
	ok(_state() == "TITLE" and main.title != null and main.reactions["fatiha"]["lines"][0].begins_with("Al-Fatiha… Dix-sept"), "retour au français")

	# nouvelle partie -> note -> cinématique
	main._on_new_game()
	await _wait(0.5)
	ok(_state() == "NOTE" and main.note != null, "première partie : la note sur la fiction s'affiche")
	main.note.accepted.emit()
	await _wait(0.5)
	ok(_state() == "CINEMATIC" and main.cinematic != null, "puis la cinématique")
	await _wait(6.0)
	ok(main.cinematic != null and not main.cinematic.done, "la cinématique se déroule")
	main.debug_skip_cinematic()
	ok(await _until(func() -> bool: return _state() == "PLAY", 15.0), "passer la cinématique lance le jeu")
	ok(main.world != null and main.world.player != null, "le monde et le personnage existent")
	ok(main.save.intro_seen and main.save.note_seen, "la sauvegarde retient cinématique et note vues")

	# première page
	main.debug_teleport(2010.0)
	await _wait(1.0)
	main.debug_collect(322)
	await _wait(2.0)
	ok(main.save.has_page(322), "la première page (Al-Anbiya) est prise")
	ok(main.dialogue.active or not main._scene_queue.is_empty(), "le personnage réagit (scène)")
	await _flush_dialogue()
	ok(not main.dialogue.active and not main.world.player.frozen, "la scène finie, le personnage est libéré")

	# Mushaf
	main._toggle_book()
	await _wait(0.3)
	ok(main.book.is_open() and get_tree().paused, "le Mushaf s'ouvre (le jeu se met en pause)")
	main.book.close_book()
	await _wait(0.2)
	ok(not main.book.is_open() and not get_tree().paused, "il se ferme")

	# pause
	main._toggle_pause()
	await _wait(0.2)
	ok(main.paused_menu and get_tree().paused and main.pause_menu.visible, "la pause s'affiche")
	main._toggle_pause()
	await _wait(0.2)
	ok(not main.paused_menu and not get_tree().paused, "la reprise fonctionne")

	# changer de langue depuis la pause : l'interface est refaite, la partie continue au même endroit
	var before: Vector2 = main.world.player.global_position
	main._toggle_pause()
	await _wait(0.2)
	main.save.lang = "en"
	I18n.set_language("en")
	main._on_language_changed()
	await _wait(0.3)
	ok(_state() == "PLAY" and main.paused_menu and main.pause_menu.visible and main.world != null, "langue changée en jeu : retour sur la pause, la partie est conservée")
	ok(main.world.pickups.values()[0].prompt_text() == "Take the page" and main.reactions["fatiha"]["meaning"]["translator"].contains("Khattab"), "invites et versets passent en anglais (The Clear Quran)")
	main.save.lang = "fr"
	I18n.set_language("fr")
	main._on_language_changed()
	await _wait(0.3)
	main._toggle_pause()
	await _wait(0.2)
	ok(not get_tree().paused and main.world.player.global_position.distance_to(before) < 40.0 and main.reactions["fatiha"]["meaning"]["translator"].contains("Hamidullah"), "retour au français (Hamidullah), le personnage n'a pas bougé")

	# retour au menu et « Continuer », en pleine scène de dialogue : rien ne doit rester à l'écran au retour
	main.dialogue.show_scene(["Une pensée qui ne doit pas survivre au retour au menu."], {}, func() -> void: pass)
	main.dialogue.whisper("Un murmure en attente.")
	main.world.player.frozen = true
	ok(main.dialogue.active and main.dialogue._panel.visible, "une scène de dialogue est affichée avant de quitter")
	main._toggle_pause()
	await _wait(0.2)
	main._back_to_title()
	main._back_to_title()  # plusieurs clics d'affilée : un seul retour au menu
	ok(not main.pause_menu.visible and not get_tree().paused, "« Menu principal » ferme la pause immédiatement")
	ok(await _until(func() -> bool: return _state() == "TITLE" and main.title != null, 5.0), "retour au menu principal")
	await _wait(0.5)
	ok(not main.dialogue.active and not main.dialogue._panel.visible and main.dialogue._whisper_queue.is_empty(), "le dialogue est remis à zéro au retour au menu")
	main._on_continue()
	ok(await _until(func() -> bool: return _state() == "PLAY" and main.world != null, 8.0), "« Continuer » relance le monde sans cinématique")
	ok(not main.dialogue.active and not main.dialogue._panel.visible and not main.world.player.frozen, "après « Continuer » : pas de fenêtre de dialogue fantôme, le personnage est libre")
	ok(main.save.has_page(322) and main.hud._count == main.save.count(), "la progression et le compteur sont conservés")

	# fin : les autres pages, puis la dernière
	main.debug_give_all()
	main.debug_teleport(15250.0)
	await _wait(1.0)
	main.debug_collect(604)
	# la téléportation a aussi déclenché les scènes d'histoire des zones traversées : on les fait défiler jusqu'à la fin
	var t := 0.0
	var saw_final := false
	while t < 30.0 and not (_state() == "END" and main.end_card != null):
		if main.dialogue.active:
			main.debug_advance(2)
		if main._finale_done and main.dialogue.active:
			saw_final = true
		await _wait(0.2)
		t += 0.2
	ok(saw_final, "la dernière page déclenche la scène finale")
	ok(_state() == "END" and main.end_card != null, "puis la carte de fin")
	main._end_keep_exploring()
	ok(_state() == "PLAY" and not main.world.player.frozen, "on peut continuer à explorer après la fin")
	ok(main.save.finished, "la fin est enregistrée")


	# chapitre 2 : la suite du rêve
	main._end_next_chapter()
	await _wait(0.5)
	ok(_state() == "CINEMATIC" and main.chapter == 2 and main.cinematic != null, "le chapitre 2 commence par sa cinématique")
	await _wait(5.0)
	main.debug_skip_cinematic()
	ok(await _until(func() -> bool: return _state() == "PLAY" and main.world != null and main.world.chapter == 2, 15.0), "puis le monde du chapitre 2")
	ok(main.save.flag("c2_intro") and main.save.chapter == 2, "la sauvegarde retient le chapitre 2")
	main.debug_teleport(2010.0)
	await _wait(1.0)
	main.debug_collect(411)
	await _wait(2.0)
	ok(main.save.has_page(411) and main.save.has_page(414), "la première page du chapitre 2 (Luqman) est prise en entier")
	await _flush_dialogue()
	main._back_to_title()
	ok(await _until(func() -> bool: return _state() == "TITLE" and main.title != null, 5.0), "retour au menu depuis le chapitre 2")
	await _wait(0.5)
	main._on_continue()
	ok(await _until(func() -> bool: return _state() == "PLAY" and main.world != null and main.world.chapter == 2, 8.0), "« Continuer » reprend le chapitre 2")
	ok(main.save.has_page(411) and main.world.pickups.has("411") == false, "la page déjà prise ne réapparaît pas")
	main._back_to_title()
	ok(await _until(func() -> bool: return _state() == "TITLE" and main.title != null, 5.0), "retour au menu")
	await _wait(0.5)
	main._on_chapter1()
	ok(await _until(func() -> bool: return _state() == "PLAY" and main.world != null and main.world.chapter == 1, 8.0), "on peut reprendre le chapitre 1")
