extends RefCounted
## Sauvegarde locale (user://) : pages récoltées, objets, progression de l'histoire, réglages.

const DEFAULT_PATH := "user://ghafla_save.json"
const VERSION := 1

static var _inst: RefCounted

var path: String = DEFAULT_PATH
var collected: Dictionary = {}  # numéro de page -> true
var items: Dictionary = {}  # identifiant d'objet -> true
var revealed: Dictionary = {}  # identifiant de page cachée -> true
var flags: Dictionary = {}  # repères d'histoire déjà vus
var intro_seen: bool = false
var note_seen: bool = false  # la note « histoire fictive » a été lue
var finished: bool = false
var player_x: float = -1.0
var player_y: float = -1.0
var volume: float = 0.8
var touch_controls: int = -1  # -1 automatique, 0 non, 1 oui


static func get_instance() -> RefCounted:
	if _inst == null:
		_inst = new()
		_inst.load_file()
	return _inst


func exists() -> bool:
	return FileAccess.file_exists(path)


func count() -> int:
	return collected.size()


func has_page(page: int) -> bool:
	return collected.has(page)


func add_page(page: int) -> void:
	collected[page] = true


func has_item(id: String) -> bool:
	return items.has(id)


func add_item(id: String) -> void:
	items[id] = true


func flag(name: String) -> bool:
	return flags.has(name)


func set_flag(name: String) -> void:
	flags[name] = true


func to_dict() -> Dictionary:
	var pages: Array = collected.keys()
	pages.sort()
	return {
		"version": VERSION,
		"pages": pages,
		"items": items.keys(),
		"revealed": revealed.keys(),
		"flags": flags.keys(),
		"intro_seen": intro_seen,
		"note_seen": note_seen,
		"finished": finished,
		"player": [player_x, player_y],
		"volume": volume,
		"touch": touch_controls,
	}


func from_dict(d: Dictionary) -> void:
	collected.clear()
	items.clear()
	revealed.clear()
	flags.clear()
	for p in d.get("pages", []):
		collected[int(p)] = true
	for i in d.get("items", []):
		items[str(i)] = true
	for r in d.get("revealed", []):
		revealed[str(r)] = true
	for f in d.get("flags", []):
		flags[str(f)] = true
	intro_seen = bool(d.get("intro_seen", false))
	note_seen = bool(d.get("note_seen", false))
	finished = bool(d.get("finished", false))
	var pos: Array = d.get("player", [-1.0, -1.0])
	player_x = float(pos[0]) if pos.size() > 0 else -1.0
	player_y = float(pos[1]) if pos.size() > 1 else -1.0
	volume = clampf(float(d.get("volume", 0.8)), 0.0, 1.0)
	touch_controls = int(d.get("touch", -1))


func save_file() -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_warning("Sauvegarde impossible : %s" % path)
		return false
	f.store_string(JSON.stringify(to_dict()))
	return true


func load_file() -> bool:
	if not exists():
		return false
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:  # fichier abîmé : on repart de zéro sans bruit
		return false
	var parsed: Variant = json.data
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	from_dict(parsed)
	return true


## Nouvelle partie : on garde les réglages, pas la progression.
func reset_progress() -> void:
	collected.clear()
	items.clear()
	revealed.clear()
	flags.clear()
	player_x = -1.0
	player_y = -1.0
	intro_seen = false
	finished = false
	save_file()
