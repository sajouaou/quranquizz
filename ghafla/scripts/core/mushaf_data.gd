extends RefCounted
## Structure du mushaf de Médine : sourates, juz et pages.
## Les données viennent de data/surahs.json. Aucun texte coranique n'est écrit dans le code.
##
## Le mushaf de Médine (Hafs 'an 'Asim, Complexe du Roi Fahd) compte 604 pages numérotées de 1 à 604.
## Le nombre total est lu dans le fichier de données : c'est la seule valeur à changer si l'on
## souhaite suivre un autre mushaf.

const PATH := "res://data/surahs.json"

static var _inst: RefCounted

var total_pages: int = 604
var juz_starts: Array = []
var surahs: Array = []
var loaded: bool = false


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
	return loaded


func surah(id: int) -> Dictionary:
	return surahs[id - 1] if id >= 1 and id <= surahs.size() else {}


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
		names.append(s["name_ar"] if arabic else s["name_fr"])
	return (" · " if not arabic else " ، ").join(names)


func is_valid_page(page: int) -> bool:
	return page >= 1 and page <= total_pages
