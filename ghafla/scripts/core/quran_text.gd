extends Node
## Texte des pages du Mushaf. Aucun texte coranique n'est écrit dans le code ni dans ce dépôt :
##  1. res://data/mushaf_text/page_XXX.json  (facultatif, produit par tools/fetch_mushaf_text.py)
##  2. user://mushaf_text/page_XXX.json      (cache)
##  3. sinon, téléchargement une seule fois depuis l'API publique de quran.com quand le joueur est en ligne.
## Format d'un fichier : {"page": 322, "verses": [{"key": "21:1", "text": "..."}]}

const DrawUtil := preload("res://scripts/core/draw_util.gd")

signal loaded(page: int)

static var inst: Node

var allow_network: bool = true
var _texts: Dictionary = {}  # page -> texte prêt à afficher
var _failed: Dictionary = {}  # page -> instant de l'échec (nouvel essai après 45 s)
var _queue: Array = []
var _busy: bool = false


func _ready() -> void:
	inst = self
	DirAccess.make_dir_recursive_absolute("user://mushaf_text")


static func get_text(page: int) -> String:
	if inst == null:
		return ""
	return inst._get(page)


func _get(page: int) -> String:
	if _texts.has(page):
		return _texts[page]
	var verses := _read_local(page)
	if not verses.is_empty():
		_texts[page] = compose(verses)
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


func _pump() -> void:
	if _busy or _queue.is_empty():
		return
	_busy = true
	var page: int = _queue.pop_front()
	var req := HTTPRequest.new()
	req.timeout = 12.0
	add_child(req)
	req.request_completed.connect(func(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
		_on_done(page, result, code, body)
		req.queue_free())
	var err := req.request("https://api.quran.com/api/v4/quran/verses/uthmani?page_number=%d" % page)
	if err != OK:
		_failed[page] = Time.get_ticks_msec()
		_busy = false
		req.queue_free()


func _on_done(page: int, result: int, code: int, body: PackedByteArray) -> void:
	_busy = false
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
				ok = true
				loaded.emit(page)
	if not ok:
		_failed[page] = Time.get_ticks_msec()
	_pump()
