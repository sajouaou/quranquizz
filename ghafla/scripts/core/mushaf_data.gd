extends RefCounted
## Structure du mushaf de Médine : sourates, juz et pages.
## Les données viennent de data/surahs.json. Aucun texte coranique n'est écrit dans le code.
##
## Le mushaf de Médine (Hafs 'an 'Asim, Complexe du Roi Fahd) compte 604 pages numérotées de 1 à 604.
## Le nombre total est lu dans le fichier de données : c'est la seule valeur à changer si l'on
## souhaite suivre un autre mushaf.

const PATH := "res://data/surahs.json"
const PARTS_PATH := "res://data/page_parts.json"
const I18n := preload("res://scripts/core/i18n.gd")

static var _inst: RefCounted

var total_pages: int = 604
var juz_starts: Array = []
var surahs: Array = []
var loaded: bool = false
var page_parts: Dictionary = {}  # page -> [[sourate, premier verset, dernier verset], ...] (numéros seulement)
var _surah_pages_cache: Dictionary = {}  # sourate -> pages (calcul coûteux, demandé très souvent)


static func get_instance() -> RefCounted:
	if _inst == null:
		_inst = new()
		_inst.load_data()
	return _inst


func load_data(path: String = PATH) -> bool:
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("MushafData: impossible de lire %s" % path)
		return false
	total_pages = int(parsed.get("total_pages", 604))
	juz_starts = parsed.get("juz_start_pages", [])
	surahs = parsed.get("surahs", [])
	loaded = surahs.size() == 114 and juz_starts.size() == 30
	var pp: Variant = JSON.parse_string(FileAccess.get_file_as_string(PARTS_PATH))
	if typeof(pp) == TYPE_DICTIONARY:
		for k in pp.get("pages", {}).keys():
			page_parts[int(k)] = pp["pages"][k]
	return loaded


func surah(id: int) -> Dictionary:
	return surahs[id - 1] if id >= 1 and id <= surahs.size() else {}


## Nom d'une sourate dans la langue courante (locales/<langue>/surahs.json), sinon celui des données.
func surah_name(s: Dictionary) -> String:
	return I18n.surah_name(int(s.get("id", 0)), str(s.get("name_fr", "")))


func surahs_starting_on(page: int) -> Array:
	var out: Array = []
	for s in surahs:
		if int(s["start_page"]) == page:
			out.append(s)
	return out


## Sourate « en cours » sur une page : la dernière dont le début est situé avant ou sur cette page.
func surah_of_page(page: int) -> Dictionary:
	var current: Dictionary = surahs[0] if not surahs.is_empty() else {}
	for s in surahs:
		if int(s["start_page"]) <= page:
			current = s
		else:
			break
	return current


func juz_of_page(page: int) -> int:
	var juz := 1
	for i in range(juz_starts.size()):
		if int(juz_starts[i]) <= page:
			juz = i + 1
	return juz


func juz_range(juz: int) -> Vector2i:
	var first: int = int(juz_starts[juz - 1])
	var last: int = total_pages if juz >= juz_starts.size() else int(juz_starts[juz]) - 1
	return Vector2i(first, last)


## Pages d'une sourate (approximation : de son début jusqu'à la veille du début de la suivante).
func surah_range(id: int) -> Vector2i:
	var first: int = int(surahs[id - 1]["start_page"])
	var last := total_pages
	if id < surahs.size():
		var next_start: int = int(surahs[id]["start_page"])
		last = maxi(first, next_start - 1) if next_start > first else first
	return Vector2i(first, last)


## Nom(s) à afficher pour une page : les sourates qui commencent dessus, sinon la sourate en cours.
func page_title(page: int, arabic: bool = false) -> String:
	var starting := surahs_starting_on(page)
	var list: Array = starting if not starting.is_empty() else [surah_of_page(page)]
	var names: PackedStringArray = []
	for s in list:
		names.append(s["name_ar"] if arabic else surah_name(s))
	return (" · " if not arabic else " ، ").join(names)


func is_valid_page(page: int) -> bool:
	return page >= 1 and page <= total_pages


## Les « parties » d'une page : une page peut porter la fin d'une sourate, une sourate entière, le début de la suivante…
## Renvoie [[sourate, premier verset, dernier verset], ...] dans l'ordre de la page.
func parts_of_page(page: int) -> Array:
	if page_parts.has(page):
		return page_parts[page]
	if not is_valid_page(page):
		return []
	return [[int(surah_of_page(page).get("id", 1)), 1, 1]]


func surah_ids_on_page(page: int) -> Array:
	var ids := []
	for pt in parts_of_page(page):
		ids.append(int(pt[0]))
	return ids


## Pages qui portent au moins un verset de la sourate.
func surah_pages(surah_id: int) -> Array:
	if _surah_pages_cache.has(surah_id):
		return _surah_pages_cache[surah_id]
	var out := []
	for p in range(1, total_pages + 1):
		if surah_ids_on_page(p).has(surah_id):
			out.append(p)
	_surah_pages_cache[surah_id] = out
	return out


## Pages concernées par une liste d'objets à prendre (les entrées de data/world_pages*.json) :
##  - "touched"  : toutes les pages dont au moins une partie est donnée ;
##  - "complete" : celles que ces objets suffisent à compléter (toutes leurs parties sont données).
## Sert à annoncer des nombres de pages exacts (menu des chapitres, carte de fin, indices des sceaux).
func pages_of_defs(defs: Array) -> Dictionary:
	var given := {}  # « page:sourate » -> true
	var touched := {}
	for d in defs:
		if d.has("grant_surah"):
			var sid := int(d["grant_surah"])
			for pg in surah_pages(sid):
				given["%d:%d" % [pg, sid]] = true
				touched[int(pg)] = true
		elif d.has("part"):
			for pg in d.get("pages", [int(d["page"])]):
				given["%d:%d" % [int(pg), int(d["part"])]] = true
				touched[int(pg)] = true
		else:
			var page := int(d["page"])
			for s in surah_ids_on_page(page):
				given["%d:%d" % [page, s]] = true
			touched[page] = true
	var complete := []
	for page in touched.keys():
		var full := true
		for s in surah_ids_on_page(page):
			if not given.has("%d:%d" % [page, s]):
				full = false
		if full:
			complete.append(page)
	var all: Array = touched.keys()
	all.sort()
	complete.sort()
	return {"touched": all, "complete": complete}


## La sourate commence-t-elle sur cette page (verset 1 présent) ?
func surah_starts_on(page: int, surah_id: int) -> bool:
	for pt in parts_of_page(page):
		if int(pt[0]) == surah_id and int(pt[1]) == 1:
			return true
	return false
