extends RefCounted
## Ressources chargées sans passer par l'import de l'éditeur : polices et sons sont lus comme
## des fichiers bruts (extensions .fontbin et .sfx, exportés via include_filter).
## Ainsi le jeu démarre tel quel depuis un simple clone du dépôt.

static var _fonts: Dictionary = {}
static var _sounds: Dictionary = {}


static func font_arabic() -> FontFile:
	return _font("ar", "res://assets/fonts/Amiri-arabic.fontbin", [])


## Police « livre » : latin Amiri avec repli sur l'arabe pour les noms de sourates et le texte.
static func font_book() -> FontFile:
	return _font("book", "res://assets/fonts/Amiri-latin.fontbin", [font_arabic(), _font("ext", "res://assets/fonts/Amiri-latin-ext.fontbin", [])])


static func _font(key: String, path: String, fallbacks: Array) -> FontFile:
	if _fonts.has(key):
		return _fonts[key]
	var f := FontFile.new()
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		push_warning("Police introuvable : %s" % path)
	else:
		f.data = bytes
	f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
	var fb: Array[Font] = []
	for x in fallbacks:
		fb.append(x)
	f.fallbacks = fb
	_fonts[key] = f
	return f


## Charge un son PCM 16 bits (.sfx = conteneur WAV). Retourne null s'il est absent.
static func sound(name: String) -> AudioStreamWAV:
	if _sounds.has(name):
		return _sounds[name]
	var path := "res://assets/audio/%s.sfx" % name
	var b := FileAccess.get_file_as_bytes(path)
	var stream: AudioStreamWAV = null
	if b.size() > 44:
		stream = _parse_wav(b)
	_sounds[name] = stream
	return stream


static func _parse_wav(b: PackedByteArray) -> AudioStreamWAV:
	var pos := 12
	var rate := 22050
	var channels := 1
	var data := PackedByteArray()
	while pos + 8 <= b.size():
		var id := b.slice(pos, pos + 4).get_string_from_ascii()
		var size := b.decode_u32(pos + 4)
		var body := pos + 8
		if id == "fmt ":
			channels = b.decode_u16(body + 2)
			rate = b.decode_u32(body + 4)
		elif id == "data":
			data = b.slice(body, mini(body + size, b.size()))
		pos = body + size + (size & 1)
	if data.is_empty():
		return null
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = rate
	s.stereo = channels == 2
	s.data = data
	return s
