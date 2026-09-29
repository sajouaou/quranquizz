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
	_test_mushaf()
	_test_save()
	_test_sounds()
	_test_inputs()
	_test_adab()
	await _test_world()
	await _test_reachability()
	await _test_traversal()
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

func _test_data() -> void:
	var wp: Dictionary = _json("res://data/world_pages.json")
	dialogue = _json("res://data/dialogue.json")
	pages_def = wp.get("pages", [])
	ok(pages_def.size() >= 10, "world_pages : au moins 10 pages placées (%d)" % pages_def.size())
	var seen := {}
	var in_range := true
	var firsts := 0
	var finals := 0
	for d in pages_def:
		var p := int(d["page"])
		if p < 1 or p > 604:
			in_range = false
		seen[p] = true
		firsts += 1 if bool(d.get("first", false)) else 0
		finals += 1 if bool(d.get("final", false)) else 0
	ok(in_range, "pages placées entre 1 et 604")
	ok(seen.size() == pages_def.size(), "pas de page placée en double")
	ok(firsts == 1 and finals == 1, "une seule première page et une seule dernière")

	var reactions: Dictionary = dialogue.get("reactions", {})
	var missing := []
	var kinds_ok := true
	var locks_ok := true
	var reveal_ok := true
	for d in pages_def:
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
				if not seen.has(int(lp)):
					locks_ok = false
			if str(lock.get("type", "")) == "others" and not bool(d.get("final", false)):
				locks_ok = false
		if kind == "hidden":
			var rv: Dictionary = d.get("reveal", {})
			if not ["wait", "event", "vein"].has(str(rv.get("type", ""))):
				reveal_ok = false
	ok(missing.is_empty(), "toutes les réactions existent %s" % str(missing))
	ok(kinds_ok, "types de pages valides (visible, hidden, locked)")
	ok(locks_ok, "verrous valides (les pages exigées existent, « others » seulement sur la dernière)")
	ok(reveal_ok, "révélations valides (wait, event, vein)")

	# Dialogues : chaque déclencheur et chaque réaction a du texte, les références « sens approximatif » sont bien formées
	var lines_ok := true
	var refs_ok := true
	for t in dialogue.get("triggers", []):
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
	ok(lines_ok, "chaque déclencheur et chaque réaction contient du texte")
	ok(refs_ok, "références « sens approximatif » valides (sourate:verset ou sourate:début-fin)")

	# Le sens cité correspond bien à la sourate de la page
	var match_ok := true
	for d in pages_def:
		var r: Dictionary = reactions.get(str(d.get("reaction", "")), {})
		if r.has("meaning"):
			var sid := int(str(r["meaning"]["ref"]).split(":")[0])
			var rng: Vector2i = mushaf.surah_range(sid)
			if int(d["page"]) < rng.x or int(d["page"]) > rng.y:
				match_ok = false
				print("[test]   la page ", d["page"], " n'est pas dans la sourate ", sid)
	ok(match_ok, "le « sens approximatif » cité correspond à la sourate de la page")

	# Ordre des déclencheurs d'histoire
	var xs_ok := true
	for t in dialogue.get("triggers", []):
		if float(t["x"]) < 0.0 or float(t["x"]) > World.WORLD_W:
			xs_ok = false
	ok(xs_ok, "déclencheurs d'histoire dans les limites du monde")


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

func _make_world() -> void:
	if world != null:
		world.queue_free()
		await get_tree().process_frame
	save = SaveData.new()
	save.path = TMP_SAVE
	world = World.new()
	world.name = "World"
	add_child(world)
	world.start(save, mushaf)
	world.player.use_scripted_input = true
	await get_tree().physics_frame


func _test_world() -> void:
	await _make_world()
	ok(world.placed_pages.size() == pages_def.size(), "le monde place toutes les pages du fichier (%d)" % world.placed_pages.size())
	ok(world.pickups.size() == pages_def.size(), "une page dans le monde par entrée du fichier")

	# Pages cachées : invisibles au départ
	var hidden := 0
	for pk in world.pickups.values():
		if pk.hidden_state:
			hidden += 1
	ok(hidden >= 5, "il y a des pages cachées (%d)" % hidden)
	ok(not world.pickups[600].can_interact(), "la page cachée (600) ne peut pas être prise")
	world.trigger_event("coins_gone")
	ok(not world.pickups[600].hidden_state, "l'événement « coins_gone » révèle la page 600")

	# Prise d'une page
	var got := []
	world.page_collected.connect(func(page: int, _s: Vector2, _d: Dictionary) -> void: got.append(page))
	var first: Node = world.pickups[322]
	world.collect_page(first)
	ok(got == [322] and save.has_page(322), "prendre une page émet page_collected et l'enregistre")
	world.collect_page(first)
	ok(got == [322], "une page ne se prend qu'une fois")

	# Verrous
	save.collected.erase(322)
	var chest: Node = world.pickups[601]
	ok(chest.locked and not chest.lock_satisfied(), "le coffre (601) est fermé sans clé")
	world.give_item("key_chest")
	ok(chest.lock_satisfied(), "la clé ouvre le coffre")
	var seal: Node = world.pickups[304]
	ok(seal.locked and not seal.lock_satisfied(), "le sceau d'Al-Kahf (304) est fermé au début")
	for p in range(293, 304):
		save.add_page(p)
	ok(seal.lock_satisfied(), "le sceau s'ouvre quand 293 à 303 sont retrouvées")
	var last: Node = world.pickups[604]
	ok(last.locked and not last.lock_satisfied(), "le sceau de l'aube (604) est fermé tant qu'il manque des pages")
	for p in world.placed_pages:
		if int(p) != 604:
			save.add_page(int(p))
	ok(last.lock_satisfied(), "le sceau de l'aube s'ouvre quand toutes les autres pages sont là")

	DirAccess.remove_absolute(TMP_SAVE)


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


func _test_reachability() -> void:
	await _make_world()
	var unreachable := []
	for d in pages_def:
		var page := int(d["page"])
		var pk: Node2D = world.pickups[page]
		# on rend la page prenable, sans toucher aux règles : on veut seulement savoir si le corps du joueur l'atteint
		pk.hidden_state = false
		pk._appear = 1.0
		if pk.locked and pk.lock_satisfied() == false:
			pk.locked = false
		var start_x := clampf(pk.global_position.x - 420.0, 2100.0, World.WORLD_W)
		var gy: float = world.ground_at(start_x)
		world.player.teleport(Vector2(start_x, gy - 2.0))
		await get_tree().physics_frame
		var goal := pk.global_position
		var reached: bool = await _bot_go(goal, 900, func() -> bool: return world.player.target == pk)
		if not reached:
			unreachable.append(page)
			print("[test]   page ", page, " non atteinte : joueur ", world.player.global_position, " page ", goal)
	ok(unreachable.is_empty(), "le bot atteint chaque page (%d / %d) %s" % [pages_def.size() - unreachable.size(), pages_def.size(), str(unreachable)])


# --------------------------------------------------------------------------- 8. traversée complète

func _test_traversal() -> void:
	await _make_world()
	var p: Node2D = world.player
	# La porte d'entrée est verrouillée par un objet à activer : le bot fait comme le joueur (il agit quand on lui propose).
	var goals := [
		Vector2(1990.0, 99999.0),
		Vector2(4200.0, 99999.0),
		Vector2(5300.0, 99999.0),
		Vector2(8200.0, 99999.0),
		Vector2(9300.0, 99999.0),
		Vector2(12300.0, 99999.0),
		Vector2(14800.0, 99999.0),
	]
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
	ok(stuck_at < 0.0, "le bot traverse tout le monde, de la chambre au sommet (bloqué en x=%.0f)" % stuck_at)
	if stuck_at < 0.0:
		ok(world.zone_at(p.global_position.x) == "peak", "il arrive dans la zone du sommet")
	DirAccess.remove_absolute(TMP_SAVE)
