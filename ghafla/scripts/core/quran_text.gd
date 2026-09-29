extends Node
## Texte des pages du Mushaf. Aucun texte coranique n'est écrit dans le code ni dans ce dépôt :
##  1. res://data/mushaf_text/page_XXX.json  (facultatif, produit par tools/fetch_mushaf_text.py)
##  2. user://mushaf_text/page_XXX.json      (cache)
##  3. sinon, téléchargement une seule fois depuis l'API publique de quran.com quand le joueur est en ligne.
## Format d'un fichier : {"page": 322, "verses": [{"key": "21:1", "text": "..."}]}

const DrawUtil := preload("res://scripts/core/draw_util.gd")

signal loaded(page: int)
signal progress(done: int, total: int)  # téléchargement complet du Mushaf (voir prefetch_all)

static var inst: Node

var allow_network: bool = true
var _texts: Dictionary = {}  # page -> texte prêt à afficher
var _segs: Dictionary = {}  # page -> [{surah, first, text}] : le texte découpé par sourate
var _failed: Dictionary = {}  # page -> instant de l'échec (nouvel essai après 45 s)
var _queue: Array = []
var _active: int = 0  # requêtes en cours
var _prefetch_total: int = 0
var _prefetch_left: int = 0
var base_url: String = "https://api.quran.com/api/v4/quran/verses/uthmani?page_number="
const MAX_PARALLEL := 4
var total_pages: int = 604


func _ready() -> void:
	inst = self
	DirAccess.make_dir_recursive_absolute("user://mushaf_text")


static func get_text(page: int) -> String:
	if inst == null:
		return ""
	return inst._lookup(page)


func _lookup(page: int) -> String:
	if _texts.has(page):
		return _texts[page]
	var verses := _read_local(page)
	if not verses.is_empty():
		_texts[page] = compose(verses)
		_segs[page] = split_by_surah(verses)
		return _texts[page]
	if allow_network and not _queue.has(page):
		var failed_at: int = _failed.get(page, -100000)
		if Time.get_ticks_msec() - failed_at > 45000:
			_queue.append(page)
			_pump()
	return ""


func _read_local(page: int) -> Array:
	for path in ["res://data/mushaf_text/page_%03d.json" % page, "user://mushaf_text/page_%03d.json" % page]:
		if FileAccess.file_exists(path):
			var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
			if typeof(parsed) == TYPE_DICTIONARY and parsed.has("verses"):
				return parsed["verses"]
	return []


## Le texte de la page découpé par sourate : [{surah, first (premier verset présent), text}]. Vide tant que le texte n'est pas là.
static func get_segments(page: int) -> Array:
	if inst == null:
		return []
	inst._lookup(page)
	return inst._segs.get(page, [])


static func split_by_surah(verses: Array) -> Array:
	var out := []
	var cur := {}
	var buf := []
	for v in verses:
		var key := str(v.get("key", ""))
		var sid := int(key.get_slice(":", 0)) if key.contains(":") else 0
		var num := int(key.get_slice(":", 1)) if key.contains(":") else 0
		if cur.is_empty() or int(cur["surah"]) != sid:
			if not cur.is_empty():
				cur["text"] = compose(buf)
				out.append(cur)
			cur = {"surah": sid, "first": num, "text": ""}
			buf = []
		buf.append(v)
	if not cur.is_empty():
		cur["text"] = compose(buf)
		out.append(cur)
	return out


## Assemble les versets d'une page : texte, puis marque de fin de verset avec son numéro.
static func compose(verses: Array) -> String:
	var parts := PackedStringArray()
	for v in verses:
		var key := str(v.get("key", ""))
		var num := int(key.get_slice(":", 1)) if key.contains(":") else 0
		var marker := ""
		if num > 0:
			marker = " %s%s" % [String.chr(0x06DD), DrawUtil.arabic_digits(num)]
		parts.append(str(v.get("text", "")) + marker)
	return " ".join(parts)


## Télécharge le texte de toutes les pages qu'on n'a pas encore (en tâche de fond, quelques requêtes à la fois).
## Appelé pendant la cinématique d'ouverture ; sans réseau, les pages en échec seront redemandées à la demande.
func prefetch_all() -> void:
	if not allow_network:
		return
	var missing := 0
	for p in range(1, total_pages + 1):
		if not _cached(p) and not _queue.has(p):
			_queue.append(p)
			missing += 1
	_prefetch_total = missing
	_prefetch_left = missing
	progress.emit(0, missing)
	_pump()


func is_complete() -> bool:
	for p in range(1, total_pages + 1):
		if not _cached(p):
			return false
	return true


func missing_count() -> int:
	var n := 0
	for p in range(1, total_pages + 1):
		if not _cached(p):
			n += 1
	return n


func _cached(page: int) -> bool:
	return _texts.has(page) or FileAccess.file_exists("res://data/mushaf_text/page_%03d.json" % page) or FileAccess.file_exists("user://mushaf_text/page_%03d.json" % page)


func _pump() -> void:
	while _active < MAX_PARALLEL and not _queue.is_empty():
		var page: int = _queue.pop_front()
		var req := HTTPRequest.new()
		req.timeout = 12.0
		add_child(req)
		_active += 1
		req.request_completed.connect(func(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
			_on_done(page, result, code, body)
			req.queue_free())
		var err := req.request(base_url + str(page))
		if err != OK:
			_active -= 1
			_failed[page] = Time.get_ticks_msec()
			_count_done()
			req.queue_free()


func _count_done() -> void:
	if _prefetch_left > 0:
		_prefetch_left -= 1
		progress.emit(_prefetch_total - _prefetch_left, _prefetch_total)


func _on_done(page: int, result: int, code: int, body: PackedByteArray) -> void:
	_active = maxi(_active - 1, 0)
	var ok := false
	if result == HTTPRequest.RESULT_SUCCESS and code == 200:
		var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
		if typeof(parsed) == TYPE_DICTIONARY and parsed.has("verses"):
			var verses: Array = []
			for v in parsed["verses"]:
				verses.append({"key": str(v.get("verse_key", "")), "text": str(v.get("text_uthmani", ""))})
			if not verses.is_empty():
				var f := FileAccess.open("user://mushaf_text/page_%03d.json" % page, FileAccess.WRITE)
				if f != null:
					f.store_string(JSON.stringify({"page": page, "verses": verses}))
				_texts[page] = compose(verses)
				_segs[page] = split_by_surah(verses)
				ok = true
				loaded.emit(page)
	if not ok:
		_failed[page] = Time.get_ticks_msec()
	_count_done()
	_pump()
