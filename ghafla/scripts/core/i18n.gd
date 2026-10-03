extends RefCounted
## Textes du jeu et traduction. Aucun texte affiché n'est écrit dans le code : tout est dans locales/<langue>/*.json.
##   locales/languages.json      liste des langues proposées (code, nom affiché)
##   locales/<code>/ui.json      menus, boutons, interface, note, fin, Mushaf
##   locales/<code>/world.json   invites, messages du monde, indices des sceaux
##   locales/<code>/cinematic.json   sous-titres des cinématiques
##   locales/<code>/dialogue_N.json  scènes et pensées du chapitre N (structure : data/dialogue*.json)
##   locales/<code>/verses.json  traduction publiée des versets cités (copiée par tools/fetch_translations.py)
##   locales/<code>/surahs.json  noms des sourates
## Une clé absente d'une langue retombe sur le français (langue de référence) ; absente partout, la clé elle-même est affichée.
## Les textes peuvent contenir des {repères} remplacés à l'affichage : t("menu.continue", {"chapter": 2}).

const DIR := "res://locales"
const REFERENCE := "fr"
const FILES := ["ui", "world", "cinematic"]

static var lang: String = REFERENCE
static var _strings: Dictionary = {}  # langue -> {clé: texte}
static var _surah_names: Dictionary = {}  # langue -> {id: nom}
static var _verses: Dictionary = {}  # langue -> {"translator": nom, "verses": {"21:1": texte}}
static var _dialogues: Dictionary = {}  # "langue/chapitre" -> dictionnaire
static var _missing: Dictionary = {}
static var _languages: Array = []


## Langues disponibles : [{"code": "fr", "name": "Français"}, …].
static func languages() -> Array:
	if _languages.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("%s/languages.json" % DIR))
		if typeof(parsed) == TYPE_DICTIONARY:
			_languages = parsed.get("languages", [])
		if _languages.is_empty():
			_languages = [{"code": REFERENCE, "name": "Français"}]
	return _languages


static func has_language(code: String) -> bool:
	for l in languages():
		if str(l["code"]) == code:
			return true
	return false


## Choisit la langue : un code connu, ou "" pour suivre celle de l'appareil (français par défaut).
static func set_language(code: String) -> void:
	if code == "" or not has_language(code):
		code = _system_language()
	lang = code
	_load(REFERENCE)
	_load(lang)
	TranslationServer.set_locale(lang)


static func _system_language() -> String:
	var os_lang := OS.get_locale_language()
	return os_lang if has_language(os_lang) else REFERENCE


static func language_name(code: String) -> String:
	for l in languages():
		if str(l["code"]) == code:
			return str(l["name"])
	return code


## Code de la langue suivante dans la liste (pour un bouton qui fait défiler les langues).
static func next_language(code: String) -> String:
	var list := languages()
	for i in range(list.size()):
		if str(list[i]["code"]) == code:
			return str(list[(i + 1) % list.size()]["code"])
	return REFERENCE


static func _load(code: String) -> void:
	if _strings.has(code):
		return
	var merged := {}
	for f in FILES:
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("%s/%s/%s.json" % [DIR, code, f]))
		if typeof(parsed) == TYPE_DICTIONARY:
			for k in parsed.keys():
				if not str(k).begins_with("_"):
					merged[str(k)] = parsed[k]
	_strings[code] = merged
	var sn: Variant = JSON.parse_string(FileAccess.get_file_as_string("%s/%s/surahs.json" % [DIR, code]))
	_surah_names[code] = sn.get("names", {}) if typeof(sn) == TYPE_DICTIONARY else {}
	var vs: Variant = JSON.parse_string(FileAccess.get_file_as_string("%s/%s/verses.json" % [DIR, code]))
	_verses[code] = vs if typeof(vs) == TYPE_DICTIONARY else {}


## Texte d'une clé, dans la langue courante, avec ses {repères} remplacés.
static func t(key: String, args: Dictionary = {}) -> String:
	_ensure()
	var text: Variant = (_strings[lang] as Dictionary).get(key)
	if text == null:
		text = (_strings[REFERENCE] as Dictionary).get(key)
	if text == null:
		if not _missing.has(key):
			_missing[key] = true
			push_warning("Texte manquant : %s" % key)
		return key
	var s := str(text)
	for k in args.keys():
		s = s.replace("{%s}" % str(k), str(args[k]))
	return s


static func _ensure() -> void:
	if not _strings.has(lang) or not _strings.has(REFERENCE):
		_load(REFERENCE)
		_load(lang)


static func has_key(key: String, code: String = REFERENCE) -> bool:
	_load(code)
	return (_strings[code] as Dictionary).has(key)


## Toutes les clés d'une langue (pour vérifier qu'une traduction est complète).
static func keys_of(code: String) -> Array:
	_load(code)
	return (_strings[code] as Dictionary).keys()


static func surah_name(id: int, fallback: String = "") -> String:
	_ensure()
	var n: Variant = (_surah_names[lang] as Dictionary).get(str(id))
	if n == null:
		n = (_surah_names[REFERENCE] as Dictionary).get(str(id))
	return str(n) if n != null else fallback


## Traduction publiée d'un verset cité (« 21:1 », « 103:1-3 ») dans la langue demandée, sinon en français.
## Renvoie {"text": ..., "translator": ...}. Ces textes sont copiés par tools/fetch_translations.py, jamais écrits à la main.
static func verse(ref: String, code: String = "") -> Dictionary:
	if code == "":
		code = lang
	_load(REFERENCE)
	_load(code)
	for c in [code, REFERENCE]:
		var doc: Dictionary = _verses.get(c, {})
		var text: Variant = (doc.get("verses", {}) as Dictionary).get(ref)
		if text != null:
			return {"text": str(text), "translator": str(doc.get("translator", ""))}
	return {"text": "", "translator": ""}


## Scènes d'un chapitre : la structure (data/dialogue*.json) complétée par les textes de la langue courante,
## ou du français pour ce qui manque. Renvoie {"triggers": [...], "reactions": {...}}.
static func dialogue(chapter: int, code: String = "") -> Dictionary:
	if code == "":
		code = lang
	var cache_key := "%s/%d" % [code, chapter]
	if _dialogues.has(cache_key):
		return _dialogues[cache_key]
	var suffix := "" if chapter == 1 else "_%d" % chapter
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue%s.json" % suffix))
	var out := {"triggers": [], "reactions": {}}
	if typeof(parsed) != TYPE_DICTIONARY:
		return out
	var base: Dictionary = _read_dialogue(REFERENCE, chapter)
	var mine: Dictionary = base if code == REFERENCE else _read_dialogue(code, chapter)
	for t_def in parsed.get("triggers", []):
		var e: Dictionary = (t_def as Dictionary).duplicate(true)
		_fill(e, (mine.get("triggers", {}) as Dictionary).get(str(e["id"]), {}), (base.get("triggers", {}) as Dictionary).get(str(e["id"]), {}))
		out["triggers"].append(e)
	var reactions: Dictionary = parsed.get("reactions", {})
	for id in reactions.keys():
		var e: Dictionary = (reactions[id] as Dictionary).duplicate(true)
		_fill(e, (mine.get("reactions", {}) as Dictionary).get(id, {}), (base.get("reactions", {}) as Dictionary).get(id, {}))
		if e.has("meaning"):  # le verset cité : traduction publiée de la langue (verses.json), référence dans la structure
			var v := verse(str(e["meaning"]["ref"]), code)
			e["meaning"]["text"] = v["text"]
			e["meaning"]["translator"] = v["translator"]
		out["reactions"][id] = e
	_dialogues[cache_key] = out
	return out


static func _fill(entry: Dictionary, mine: Dictionary, base: Dictionary) -> void:
	for k in ["lines", "pool", "objective"]:
		if mine.has(k):
			entry[k] = mine[k]
		elif base.has(k):
			entry[k] = base[k]


static func _read_dialogue(code: String, chapter: int) -> Dictionary:
	var path := "%s/%s/dialogue_%d.json" % [DIR, code, chapter]
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}
