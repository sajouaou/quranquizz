extends Node
## Tests du prototype. Lancer : tools/test.sh  (ou : godot --headless --path ghafla res://tests/test_runner.tscn)
## Code de sortie 0 si tout passe. Les lignes commençant par [test] sont lues par le script de test.
##  1. données (pages, dialogues, sourates), 2. Mushaf, 3. sauvegarde, 4. sons, 5. garde-fou « adab »,
##  6. monde : verrous, pages cachées, 7. un bot qui atteint chaque page, 8. un bot qui traverse tout le monde.

const SaveData := preload("res://scripts/core/save_data.gd")
const MushafData := preload("res://scripts/core/mushaf_data.gd")
const Assets := preload("res://scripts/core/assets.gd")
const Inputs := preload("res://scripts/core/inputs.gd")
const Sfx := preload("res://scripts/core/sfx.gd")
const World := preload("res://scripts/world/world.gd")
const Chapter2 := preload("res://scripts/world/chapter2.gd")
const TouchControls := preload("res://scripts/ui/touch_controls.gd")

const TMP_SAVE := "user://ghafla_test_save.json"
const ARABIC_ALLOWED := ["غفلة", "سورة"]  # le titre du jeu et le mot « sourate » : aucun texte coranique

var passed: int = 0
var failed: int = 0
var world: Node2D
var save: RefCounted
var mushaf: RefCounted
var pages_def: Array = []
var dialogue: Dictionary = {}

# état du bot
var _bot_on: bool = false
var _bot_goal: Vector2 = Vector2.ZERO
var _bot_hist: Array = []
var _bot_jump_hold: int = 0
var _bot_interact: bool = false


func _ready() -> void:
	Inputs.ensure_actions()
	add_child(Sfx.new())
	mushaf = MushafData.get_instance()
	_test_scripts_compile()
	_test_data()
	_test_data(2)
	_test_mushaf()
	_test_save()
	_test_sounds()
	_test_inputs()
	_test_adab()
	await _test_world()
	await _test_reachability()
	await _test_traversal()
	await _test_world2()
	await _test_reachability(2)
	await _test_traversal(2)
	print("[test] ---------------------------------")
	print("[test] %d réussis, %d échoués" % [passed, failed])
	if DisplayServer.get_name() == "headless":
		get_tree().quit(1 if failed > 0 else 0)


func ok(cond: bool, label: String) -> void:
	if cond:
		passed += 1
		print("[test] ok    ", label)
	else:
		failed += 1
		print("[test] ECHEC ", label)


func _json(path: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


# ------------------------------------------------------------------------------- 0. compilation

func _test_scripts_compile() -> void:
	# Charge chaque script : une erreur d'analyse (signature qui masque une méthode du moteur, type non déduit...) se voit ici.
	var files := []
	_walk("res://scripts", files)
	_walk("res://tests", files)
	var bad := []
	for path in files:
		if not (path as String).ends_with(".gd"):
			continue
		var script: Variant = load(path)
		if script == null or not (script is GDScript):
			bad.append(path)
	ok(bad.is_empty(), "tous les scripts se compilent %s" % str(bad.slice(0, 3)))


# ------------------------------------------------------------------------------------------- 1. données

func _test_data(chap: int = 1) -> void:
	var suffix := "" if chap == 1 else "_%d" % chap
	var tag := "" if chap == 1 else " [chapitre %d]" % chap
	var wp: Dictionary = _json("res://data/world_pages%s.json" % suffix)
	var dlg: Dictionary = _json("res://data/dialogue%s.json" % suffix)
	var defs: Array = wp.get("pages", [])
	if chap == 1:
		dialogue = dlg
		pages_def = defs
	ok(defs.size() >= 10, "world_pages : au moins 10 pages placées (%d)" % defs.size())
	var seen := {}
	var in_range := true
	var firsts := 0
	var finals := 0
	for d in defs:
		var p := int(d["page"])
		if p < 1 or p > 604:
			in_range = false
		seen[World.def_id(d)] = true
		firsts += 1 if bool(d.get("first", false)) else 0
		finals += 1 if bool(d.get("final", false)) else 0
	ok(in_range, "pages placées entre 1 et 604" + tag)
	ok(seen.size() == defs.size(), "pas de page (ni de partie de page) placée en double" + tag)
	ok(firsts == 1 and finals == 1, "une seule première page et une seule dernière" + tag)

	var reactions: Dictionary = dlg.get("reactions", {})
	var missing := []
	var kinds_ok := true
	var locks_ok := true
	var reveal_ok := true
	for d in defs:
		var r := str(d.get("reaction", ""))
		if r != "" and not reactions.has(r):
			missing.append(r)
		var kind := str(d.get("kind", "visible"))
		if not ["visible", "hidden", "locked"].has(kind):
			kinds_ok = false
		if kind == "locked":
			var lock: Dictionary = d.get("lock", {})
			if not ["key", "pages", "others", "count"].has(str(lock.get("type", ""))):
				locks_ok = false
			for lp in lock.get("pages", []):
				if not seen.has(str(int(lp))):
					locks_ok = false
			if str(lock.get("type", "")) == "others" and not bool(d.get("final", false)):
				locks_ok = false
		if kind == "hidden":
			var rv: Dictionary = d.get("reveal", {})
			if not ["wait", "event", "vein"].has(str(rv.get("type", ""))):
				reveal_ok = false
	ok(missing.is_empty(), "toutes les réactions existent %s" % str(missing))
	ok(kinds_ok, "types de pages valides (visible, hidden, locked)" + tag)
	ok(locks_ok, "verrous valides (les pages exigées existent, « others » seulement sur la dernière)" + tag)
	ok(reveal_ok, "révélations valides (wait, event, vein)" + tag)
	var parts_ok := true
	for d in defs:
		if d.has("part") and not mushaf.surah_ids_on_page(int(d["page"])).has(int(d["part"])):
			parts_ok = false
			print("[test]   la sourate ", d["part"], " n'est pas sur la page ", d["page"])
		if d.has("grant_surah") and not mushaf.surah_pages(int(d["grant_surah"])).has(int(d["page"])):
			parts_ok = false
	ok(parts_ok, "chaque partie de page et chaque sourate offerte existe sur sa page" + tag)

	# Dialogues : chaque déclencheur et chaque réaction a du texte, les références « sens approximatif » sont bien formées
	var lines_ok := true
	var refs_ok := true
	for t in dlg.get("triggers", []):
		if (t.get("lines", []) as Array).is_empty():
			lines_ok = false
	for k in reactions.keys():
		var r: Dictionary = reactions[k]
		if (r.get("lines", []) as Array).is_empty() and (r.get("pool", []) as Array).is_empty():
			lines_ok = false
		if r.has("meaning"):
			var ref := str(r["meaning"].get("ref", ""))
			if not _ref_valid(ref) or str(r["meaning"].get("text", "")) == "":
				refs_ok = false
				print("[test]   référence invalide : ", k, " ", ref)
	ok(lines_ok, "chaque déclencheur et chaque réaction contient du texte" + tag)
	ok(refs_ok, "références « sens approximatif » valides (sourate:verset ou sourate:début-fin)" + tag)

	# Le sens cité correspond bien à la sourate de la page
	var match_ok := true
	for d in defs:
		var r: Dictionary = reactions.get(str(d.get("reaction", "")), {})
		if r.has("meaning"):
			var sid := int(str(r["meaning"]["ref"]).split(":")[0])
			if not mushaf.surah_pages(sid).has(int(d["page"])):
				match_ok = false
				print("[test]   la page ", d["page"], " n'est pas dans la sourate ", sid)
	ok(match_ok, "le « sens approximatif » cité correspond à la sourate de la page" + tag)

	# Ordre des déclencheurs d'histoire
	var xs_ok := true
	for t in dlg.get("triggers", []):
		if float(t["x"]) < 0.0 or float(t["x"]) > (World.WORLD_W if chap == 1 else Chapter2.WORLD_W):
			xs_ok = false
	ok(xs_ok, "déclencheurs d'histoire dans les limites du monde" + tag)


## « 21:1 » ou « 103:1-3 » : la sourate existe et les versets sont dans ses limites.
func _ref_valid(ref: String) -> bool:
	var parts := ref.split(":")
	if parts.size() != 2 or not parts[0].is_valid_int():
		return false
	var sid := int(parts[0])
	if sid < 1 or sid > 114:
		return false
	var verses: int = int(mushaf.surah(sid)["verses"])
	var span := parts[1].split("-")
	if span.size() < 1 or span.size() > 2:
		return false
	for v in span:
		if not v.is_valid_int() or int(v) < 1 or int(v) > verses:
			return false
	return span.size() == 1 or int(span[0]) <= int(span[1])


# ------------------------------------------------------------------------------------------ 2. Mushaf

func _test_mushaf() -> void:
	ok(mushaf.total_pages == 604, "le Mushaf de Médine compte 604 pages")
	ok(mushaf.surahs.size() == 114, "114 sourates")
	ok(mushaf.juz_starts.size() == 30, "30 juz")
	ok(int(mushaf.surah_of_page(1)["id"]) == 1, "la page 1 est dans Al-Fatiha")
	ok(int(mushaf.surah_of_page(604)["id"]) == 114, "la page 604 est dans An-Nas")
	ok(int(mushaf.surah_of_page(322)["id"]) == 21, "la page 322 est dans Al-Anbiya")
	var kahf: Vector2i = mushaf.surah_range(18)
	ok(kahf.x == 293 and kahf.y == 304, "Al-Kahf occupe les pages 293 à 304 (%s)" % str(kahf))
	ok(mushaf.juz_of_page(1) == 1 and mushaf.juz_of_page(604) == 30, "juz de la première et de la dernière page")
	var mono := true
	var last := 0
	for s in mushaf.surahs:
		if int(s["start_page"]) < last:
			mono = false
		last = int(s["start_page"])
	ok(mono, "les pages de début de sourate sont croissantes")
	ok(not mushaf.is_valid_page(0) and not mushaf.is_valid_page(605) and mushaf.is_valid_page(604), "pages valides : 1 à 604")


# ---------------------------------------------------------------------------------------- 3. sauvegarde

func _test_save() -> void:
	var s := SaveData.new()
	s.path = TMP_SAVE
	s.add_page(322)
	s.add_page(1)
	s.add_item("key_chest")
	s.set_flag("house_start")
	s.revealed["page_1"] = true
	s.intro_seen = true
	s.note_seen = true
	s.player_x = 2100.5
	s.player_y = 620.0
	s.volume = 0.35
	s.touch_controls = 1
	ok(s.save_file(), "écriture de la sauvegarde")
	var t := SaveData.new()
	t.path = TMP_SAVE
	ok(t.load_file(), "lecture de la sauvegarde")
	ok(t.count() == 2 and t.has_page(322) and t.has_page(1), "pages retrouvées conservées")
	ok(t.has_item("key_chest") and t.flag("house_start") and t.revealed.has("page_1"), "objets, repères et pages révélées conservés")
	ok(t.intro_seen and t.note_seen and absf(t.player_x - 2100.5) < 0.01 and absf(t.volume - 0.35) < 0.001 and t.touch_controls == 1, "réglages et position conservés")
	t.reset_progress()
	ok(t.count() == 0 and not t.intro_seen and t.note_seen and absf(t.volume - 0.35) < 0.001, "nouvelle partie : la progression est effacée, les réglages restent")
	# fichier corrompu : pas de plantage
	var f := FileAccess.open(TMP_SAVE, FileAccess.WRITE)
	f.store_string("{ceci n'est pas du json")
	f.close()
	var c := SaveData.new()
	c.path = TMP_SAVE
	ok(not c.load_file() and c.count() == 0, "sauvegarde corrompue : ignorée sans erreur")
	var g := FileAccess.open(TMP_SAVE, FileAccess.WRITE)
	g.store_string(JSON.stringify({"pages": ["x", 999999, 7], "volume": 9.0, "player": []}))
	g.close()
	var w := SaveData.new()
	w.path = TMP_SAVE
	w.load_file()
	ok(w.volume <= 1.0 and w.player_x == -1.0, "valeurs hors limites : volume borné, position par défaut")
	DirAccess.remove_absolute(TMP_SAVE)


# ------------------------------------------------------------------------------------------------ 4. sons

func _test_sounds() -> void:
	ok(Assets.font_arabic().data.size() > 10000 and Assets.font_book().data.size() > 10000, "polices Amiri chargées (arabe et latin)")
	ok(Assets.font_book().has_char(0x00E9) and Assets.font_book().get_supported_chars().length() > 100, "la police du livre couvre le français")
	for n in ["step", "page", "unlock", "door", "wind", "heart", "air", "drip"]:
		var st := Assets.sound(n)
		ok(st != null and st.data.size() > 2000 and st.format == AudioStreamWAV.FORMAT_16_BITS, "son « %s » chargé (16 bits)" % n)


func _test_inputs() -> void:
	var pairs := [
		[KEY_RIGHT, "move_right"], [KEY_D, "move_right"], [KEY_LEFT, "move_left"], [KEY_Q, "move_left"], [KEY_A, "move_left"],
		[KEY_SPACE, "jump"], [KEY_UP, "jump"], [KEY_W, "jump"], [KEY_Z, "jump"], [KEY_E, "interact"], [KEY_ENTER, "interact"],
		[KEY_M, "mushaf"], [KEY_TAB, "mushaf"], [KEY_ESCAPE, "pause"], [KEY_SHIFT, "run"],
	]
	var bad := []
	for pr in pairs:
		var ev := InputEventKey.new()
		ev.keycode = pr[0]
		ev.pressed = true
		if not InputMap.event_is_action(ev, pr[1]):
			bad.append("%s -> %s" % [OS.get_keycode_string(pr[0]), pr[1]])
	ok(bad.is_empty(), "les touches (QWERTY et AZERTY) sont liées aux actions %s" % str(bad))
	# Le tactile passe par des actions : l'état doit suivre, et l'événement doit être reçu par les _unhandled_input
	TouchControls.set_action("jump", true)
	ok(Input.is_action_pressed("jump"), "le tactile appuie l'action (état)")
	TouchControls.set_action("jump", false)
	ok(not Input.is_action_pressed("jump"), "et la relâche")
	TouchControls.set_action("move_right", true)
	ok(Input.get_axis("move_left", "move_right") > 0.5, "le tactile pilote Input.get_axis")
	TouchControls.set_action("move_right", false)
	ok(absf(Input.get_axis("move_left", "move_right")) < 0.01, "et revient à zéro")


# ----------------------------------------------------------------------------------------- 5. garde-fou

func _test_adab() -> void:
	# Aucun texte coranique n'est écrit dans le code ni dans les données du jeu (hors noms de sourates).
	var bad := []
	var files := []
	_walk("res://scripts", files)
	_walk("res://data", files)
	_walk("res://scenes", files)
	for path in files:
		if path.ends_with("surahs.json") or not (path.ends_with(".gd") or path.ends_with(".json") or path.ends_with(".tscn") or path.ends_with(".cfg")):
			continue
		var text := FileAccess.get_file_as_string(path)
		for run in _arabic_runs(text):
			if not ARABIC_ALLOWED.has(run):
				bad.append("%s : %s" % [path, run])
	ok(bad.is_empty(), "aucun texte arabe hors liste autorisée %s" % str(bad.slice(0, 3)))
	ok(files.size() > 20, "garde-fou : %d fichiers analysés" % files.size())


## Suites de lettres arabes (U+0621 à U+064A et U+0671 à U+06D3) d'un texte.
func _arabic_runs(text: String) -> Array:
	var runs := []
	var cur := ""
	for i in range(text.length()):
		var c := text.unicode_at(i)
		if (c >= 0x0621 and c <= 0x064A) or (c >= 0x0671 and c <= 0x06D3) or (c >= 0x064B and c <= 0x065F and cur != ""):
			cur += text[i]
		elif cur != "":
			runs.append(cur)
			cur = ""
	if cur != "":
		runs.append(cur)
	return runs


func _walk(dir_path: String, out: Array) -> void:
	var d := DirAccess.open(dir_path)
	if d == null:
		return
	for f in d.get_files():
		out.append(dir_path.path_join(f))
	for sub in d.get_directories():
		_walk(dir_path.path_join(sub), out)


# ------------------------------------------------------------------------------------------- 6. monde

func _make_world(chap: int = 1) -> void:
	if world != null:
		world.queue_free()
		await get_tree().process_frame
	save = SaveData.new()
	save.path = TMP_SAVE
	world = World.new()
	world.name = "World"
	add_child(world)
	world.start(save, mushaf, Vector2(-1, -1), chap)
	world.player.use_scripted_input = true
	await get_tree().physics_frame


func _test_world() -> void:
	await _make_world()
	ok(world.placed_pages.size() >= 12, "le monde place les pages du fichier (%d pages touchées)" % world.placed_pages.size())
	ok(world.pickups.size() == pages_def.size(), "une page dans le monde par entrée du fichier")

	# Pages cachées : invisibles au départ
	var hidden := 0
	for pk in world.pickups.values():
		if pk.hidden_state:
			hidden += 1
	ok(hidden >= 5, "il y a des pages cachées (%d)" % hidden)
	ok(not world.pickups["600:102"].can_interact(), "la partie cachée (600 : At-Takathur) ne peut pas être prise")
	world.trigger_event("coins_gone")
	ok(not world.pickups["600:102"].hidden_state, "l'événement « coins_gone » révèle At-Takathur")

	# Prise d'une page
	var got := []
	world.page_collected.connect(func(page: int, _s: Vector2, _d: Dictionary) -> void: got.append(page))
	var first: Node = world.pickups["322"]
	world.collect_page(first)
	ok(got == [322] and save.has_page(322), "prendre une page émet page_collected et l'enregistre")
	world.collect_page(first)
	ok(got == [322], "une page ne se prend qu'une fois")

	# Verrous
	save.collected.erase(322)
	var chest: Node = world.pickups["601:104"]
	ok(chest.locked and not chest.lock_satisfied(), "le coffre (601) est fermé sans clé")
	world.give_item("key_chest")
	ok(chest.lock_satisfied(), "la clé ouvre le coffre")
	var seal: Node = world.pickups["304"]
	ok(seal.locked and not seal.lock_satisfied(), "le sceau d'Al-Kahf (304) est fermé au début")
	for p in range(293, 304):
		save.add_page(p)
	ok(seal.lock_satisfied(), "le sceau s'ouvre quand 293 à 303 sont retrouvées")
	var last: Node = world.pickups["604"]
	ok(last.locked and not last.lock_satisfied(), "le sceau de l'aube (604) est fermé tant qu'il manque des pages")
	for d in world.page_defs():
		if World.def_id(d) != "604":
			_own_def(d)
	ok(last.lock_satisfied(), "le sceau de l'aube s'ouvre quand toutes les autres pages sont là")

	await _test_parts()
	await _test_persistence()
	DirAccess.remove_absolute(TMP_SAVE)


func _own_def(d: Dictionary) -> void:
	if d.has("part"):
		for pg in world.pages_of_def(d):
			save.add_part(int(pg), int(d["part"]))
	elif d.has("grant_surah"):
		for pg in mushaf.surah_pages(int(d["grant_surah"])):
			save.add_part(pg, int(d["grant_surah"]))
	else:
		save.add_page(int(d["page"]))


## Ce qui a été fait ne réapparaît pas quand on recharge le monde avec la même sauvegarde.
func _test_persistence() -> void:
	await _make_world()
	world.collect_page(world.pickups["322"])
	world.collect_page(world.pickups["600"])
	world.trigger_event("coins_gone")
	for n in world.pages_root.get_children():
		if n.get("id") == "rack" or n.get("id") == "vein_300" or n.get("id") == "door":
			n.interact(world.player)
	var data: Dictionary = save.to_dict()
	world.queue_free()
	await get_tree().process_frame
	var save2 := SaveData.new()
	save2.path = TMP_SAVE
	save2.from_dict(JSON.parse_string(JSON.stringify(data)))
	world = World.new()
	world.name = "World"
	add_child(world)
	world.start(save2, mushaf)
	await get_tree().physics_frame
	ok(not world.pickups.has("322") and not world.pickups.has("600"), "les pages déjà prises ne réapparaissent pas au rechargement")
	ok(world.pickups.has("600:101") and world.pickups.has("600:102"), "… mais celles qui restent à trouver sont là")
	ok(not world.pickups["600:102"].hidden_state, "la partie révélée par les pièces reste révélée")
	var market: Variant = null
	for z in world.zones:
		if z.get("coins") != null:
			market = z
	ok(market != null and (market.coins as Array).is_empty(), "les pièces dissoutes ne reviennent pas")
	var usable := 0
	for n in world.pages_root.get_children():
		if (n.get("id") == "rack" or n.get("id") == "vein_300" or n.get("id") == "door") and n.can_interact():
			usable += 1
	ok(usable == 0, "le portant, la veine de lumière et la porte utilisés ne se réactivent pas")
	ok(save2.has_item("key_chest"), "la clé trouvée est gardée")


## Chapitre 2 : le monde se construit, les verrous en chaîne (alcool), Qarun caché jusqu'à l'événement, les sourates offertes.
func _test_world2() -> void:
	await _make_world(2)
	ok(world.chapter == 2 and world.world_w == Chapter2.WORLD_W, "le monde du chapitre 2 se construit")
	ok(world.pickups.size() == world.page_defs().size(), "une page dans le monde par entrée du chapitre 2")
	var m2: Node = world.pickups["85"]
	var m3: Node = world.pickups["123"]
	ok(m2.locked and not m2.lock_satisfied() and m3.locked and not m3.lock_satisfied(), "les deuxième et troisième paroles sur le vin sont scellées")
	world.collect_page(world.pickups["34"])
	ok(m2.lock_satisfied() and not m3.lock_satisfied(), "lire la première ouvre la deuxième, pas la troisième")
	save.add_page(85)
	ok(m3.lock_satisfied(), "puis la troisième")
	var qarun: Node = world.pickups["394:28"]
	ok(qarun.hidden_state, "la page de Qarun est cachée")
	world.trigger_event("qarun_fell")
	ok(not qarun.hidden_state, "elle se révèle quand la terre l'a englouti")
	world.collect_page(qarun)
	ok(save.has_page(394) and save.has_page(395) and save.has_part(396, 28) and not save.has_page(396), "la fin d'Al-Qasas (pages 394 à 396) est prise ; la page 396 garde le début d'Al-'Ankabut à part")
	world.collect_page(world.pickups["411"])
	ok(save.has_page(411) and save.has_page(412) and save.has_page(413) and save.has_page(414), "Luqman offerte en entier (pages 411 à 414)")
	world.collect_page(world.pickups["285"])
	ok(save.has_part(282, 17) and save.has_part(293, 17) and save.has_page(283), "Al-Isra offerte en entier (pages 282 à 293)")
	world.collect_page(world.pickups["353"])
	ok(save.has_part(350, 24) and save.has_part(359, 24) and save.has_page(355), "An-Nur offerte en entière (pages 350 à 359)")
	var last: Node = world.pickups["582"]
	ok(last.locked and not last.lock_satisfied(), "le sceau final d'An-Naba' est fermé")
	for d in world.page_defs():
		if World.def_id(d) != "582":
			_own_def(d)
	ok(last.lock_satisfied(), "il s'ouvre quand tout le reste est revenu")
	DirAccess.remove_absolute(TMP_SAVE)


## Parties de page (une page peut porter plusieurs sourates) et sourates offertes en entier.
func _test_parts() -> void:
	await _make_world()
	ok(mushaf.surah_ids_on_page(600) == [100, 101, 102], "la page 600 porte 3 sourates : Al-'Adiyat, Al-Qari'ah, At-Takathur")
	ok(mushaf.surah_ids_on_page(601) == [103, 104, 105], "la page 601 porte Al-'Asr, Al-Humazah, Al-Fil")
	ok(mushaf.surah_pages(67) == [562, 563, 564], "Al-Mulk occupe les pages 562 à 564")
	world.collect_page(world.pickups["600:102"])
	ok(save.has_part(600, 102) and not save.has_part(600, 101) and not save.has_page(600), "At-Takathur seule : la page 600 n'est pas complète")
	ok(save.page_progress(600) == Vector2i(1, 3) and save.count() == 0, "progression de la page 600 : 1 partie sur 3, aucune page complète")
	world.collect_page(world.pickups["600"])
	world.collect_page(world.pickups["600:101"])
	ok(save.has_part(599, 100) and not save.has_page(599), "Al-'Adiyat est prise en entier (son début est sur la page 599, qui reste à moitié)")
	ok(save.has_page(600) and save.count() == 1, "les trois parties réunies complètent la page 600")
	world.collect_page(world.pickups["601:103"])
	ok(save.page_progress(601) == Vector2i(1, 3) and not save.has_page(601), "Al-'Asr est prise à part de Al-Humazah et Al-Fil")
	world.collect_page(world.pickups["562"])
	ok(save.has_page(562) and save.has_page(563), "Al-Mulk offerte en entier : pages 562 et 563 complètes")
	ok(save.has_part(564, 67) and not save.has_page(564), "… et la part d'Al-Mulk sur la page 564 (qui porte aussi le début d'Al-Qalam)")
	world.collect_page(world.pickups["415"])
	ok(save.has_page(415) and save.has_page(416) and save.has_page(417), "As-Sajdah offerte en entier : pages 415 à 417")
	# aller-retour de sauvegarde avec des parties
	var s2 := SaveData.new()
	s2.path = TMP_SAVE
	s2.from_dict(save.to_dict())
	ok(s2.has_part(564, 67) and s2.has_page(562) and s2.page_progress(601) == Vector2i(1, 3), "les parties survivent à la sauvegarde")


# ----------------------------------------------------------------------------- 7. accessibilité (bot)

func _physics_process(_delta: float) -> void:
	if not _bot_on or world == null or world.player == null:
		return
	var p: Node2D = world.player
	var pos: Vector2 = p.global_position
	var dx: float = _bot_goal.x - pos.x
	var dir: float = 0.0
	if absf(dx) > 10.0:
		dir = signf(dx)
	p.input_x = dir
	# on ne court pas quand un vide approche : une course de 300 px dépasse la pierre suivante
	var gap_soon := false
	var pxp: float = pos.x
	for step in range(1, 9):
		if dir != 0.0 and world.collision.surface_between(pxp + dir * float(step) * 40.0, pos.y - 30.0, pos.y + 60.0) == INF:
			gap_soon = true
	p.input_run = absf(dx) > 200.0 and not gap_soon
	_bot_hist.append(pos)
	if _bot_hist.size() > 14:
		_bot_hist.pop_front()
	var want_jump := false
	var grounded: bool = p.is_on_floor()
	if grounded and dir != 0.0:
		# bloqué contre un obstacle ou une marche : on saute
		if _bot_hist.size() >= 14 and absf((_bot_hist[0] as Vector2).x - pos.x) < 3.0:
			want_jump = true
		# le sol s'arrête juste devant : on saute au bord
		var ahead: float = world.collision.surface_between(pos.x + dir * 8.0, pos.y - 20.0, pos.y + 40.0)
		if ahead == INF:
			want_jump = true
		# la cible est plus haute : on saute en approchant
		if _bot_goal.y < pos.y - 30.0 and absf(dx) < 220.0:
			want_jump = true
	if want_jump and _bot_jump_hold <= 0:
		_bot_jump_hold = 36
	p.input_jump = _bot_jump_hold > 0
	if _bot_jump_hold > 0:
		_bot_jump_hold -= 1
	if _bot_interact:
		p.do_interact()
		_bot_interact = false


func _bot_go(goal: Vector2, max_ticks: int, stop_when: Callable) -> bool:
	_bot_goal = goal
	_bot_hist.clear()
	_bot_jump_hold = 0
	_bot_on = true
	var ticks := 0
	while ticks < max_ticks:
		await get_tree().physics_frame
		ticks += 1
		if stop_when.call():
			_bot_on = false
			world.player.input_x = 0.0
			world.player.input_jump = false
			return true
	_bot_on = false
	world.player.input_x = 0.0
	world.player.input_jump = false
	return false


func _test_reachability(chap: int = 1) -> void:
	await _make_world(chap)
	var tag := "" if chap == 1 else " [chapitre %d]" % chap
	var defs: Array = pages_def if chap == 1 else world.page_defs()
	var unreachable := []
	for d in defs:
		var page := int(d["page"])
		var pk: Node2D = world.pickups[World.def_id(d)]
		# on rend la page prenable, sans toucher aux règles : on veut seulement savoir si le corps du joueur l'atteint
		pk.hidden_state = false
		pk._appear = 1.0
		if pk.locked and pk.lock_satisfied() == false:
			pk.locked = false
		var start_x := clampf(pk.global_position.x - 420.0, 2100.0, world.world_w)
		var gy: float = world.ground_at(start_x)
		world.player.teleport(Vector2(start_x, gy - 2.0))
		await get_tree().physics_frame
		var goal := pk.global_position
		var reached: bool = await _bot_go(goal, 900, func() -> bool: return world.player.target == pk)
		if not reached:
			unreachable.append(page)
			print("[test]   page ", page, " non atteinte : joueur ", world.player.global_position, " page ", goal)
	ok(unreachable.is_empty(), "le bot atteint chaque page (%d / %d) %s%s" % [defs.size() - unreachable.size(), defs.size(), str(unreachable), tag])


# --------------------------------------------------------------------------- 8. traversée complète

func _test_traversal(chap: int = 1) -> void:
	await _make_world(chap)
	var p: Node2D = world.player
	# La porte d'entrée est verrouillée par un objet à activer : le bot fait comme le joueur (il agit quand on lui propose).
	var xs := [1990.0, 4200.0, 5300.0, 8200.0, 9300.0, 12300.0, 14800.0]
	if chap == 2:
		xs = [1990.0, 3300.0, 5200.0, 7900.0, 9300.0, 11000.0, 12600.0, 15000.0, 16600.0]
	var goals := []
	for gx in xs:
		goals.append(Vector2(gx, 99999.0))
	var stuck_at := -1.0
	var elapsed := 0.0
	for g in goals:
		var reached := false
		var tries := 0
		while not reached and tries < 2:
			tries += 1
			reached = await _bot_go(g, 1500, func() -> bool:
				# interagir avec les objets non-pages rencontrés (porte, coffre à vêtements, veine de lumière)
				var t: Node = p.target
				if t != null and not t.is_in_group("page_pickup"):
					_bot_interact = true
				return absf(p.global_position.x - g.x) < 30.0)
			print("[test]   objectif x=%.0f : %s (joueur en %s, essai %d)" % [g.x, "atteint" if reached else "raté", str(p.global_position), tries])
			if not reached and p.global_position.y > 1200.0:
				break
		elapsed += 1.0
		if not reached:
			stuck_at = p.global_position.x
			break
	var tag := "" if chap == 1 else " [chapitre %d]" % chap
	ok(stuck_at < 0.0, "le bot traverse tout le monde, de la chambre au bout du chemin (bloqué en x=%.0f)%s" % [stuck_at, tag])
	if stuck_at < 0.0:
		ok(world.zone_at(p.global_position.x) == ("peak" if chap == 1 else "graves"), "il arrive dans la dernière zone%s" % tag)
	DirAccess.remove_absolute(TMP_SAVE)
