extends Node
## Bruitages du jeu. Choix de conception : uniquement des sons naturels et d'objets (pas, papier, vent,
## gouttes d'eau), jamais de musique. Les sons sont générés par tools/gen_sfx.py.

const Assets := preload("res://scripts/core/assets.gd")

static var inst: Node

var _pool: Array[AudioStreamPlayer] = []
var _loops: Dictionary = {}
var _next: int = 0


func _ready() -> void:
	inst = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(10):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_pool.append(p)


static func play(sound_name: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if inst == null:
		return
	inst._play(sound_name, volume_db, pitch)


func _play(sound_name: String, volume_db: float, pitch: float) -> void:
	var stream := Assets.sound(sound_name)
	if stream == null or _pool.is_empty():
		return
	var p := _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()


## Ambiance en boucle (vent, gouttes de la grotte). Une seule instance par nom.
static func loop(sound_name: String, volume_db: float = -14.0) -> void:
	if inst == null:
		return
	inst._loop(sound_name, volume_db)


func _loop(sound_name: String, volume_db: float) -> void:
	if _loops.has(sound_name):
		var existing: AudioStreamPlayer = _loops[sound_name]
		create_tween().tween_property(existing, "volume_db", volume_db, 1.5)
		return
	var stream := Assets.sound(sound_name)
	if stream == null:
		return
	var s := stream.duplicate() as AudioStreamWAV
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = s.data.size() / 2 if not s.stereo else s.data.size() / 4
	var p := AudioStreamPlayer.new()
	p.stream = s
	p.volume_db = -60.0
	add_child(p)
	p.play()
	create_tween().tween_property(p, "volume_db", volume_db, 2.0)
	_loops[sound_name] = p


static func fade_loop(sound_name: String, volume_db: float, seconds: float = 1.5) -> void:
	if inst == null or not inst._loops.has(sound_name):
		return
	var p: AudioStreamPlayer = inst._loops[sound_name]
	inst.create_tween().tween_property(p, "volume_db", volume_db, seconds)


static func stop_all_loops() -> void:
	if inst == null:
		return
	for k in inst._loops.keys():
		var p: AudioStreamPlayer = inst._loops[k]
		p.queue_free()
	inst._loops.clear()


static func set_master(linear: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(clampf(linear, 0.0001, 1.0)))
