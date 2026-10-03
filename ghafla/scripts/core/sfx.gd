extends Node
## Bruitages du jeu. Choix de conception : uniquement des sons naturels et d'objets (pas, papier, vent,
## gouttes d'eau, grillons), jamais de musique. Les sons sont générés par tools/gen_sfx.py.
##
## Son « 2.5D » : les bruits du monde passent par un bus « World » avec réverbération (la grotte résonne, la chambre est
## étouffée, le sommet a de l'écho) ; le vent passe en plus par un bus « Wind » étouffé à l'intérieur de la maison ;
## les sources fixes (gouttes, lampes, linge, pages) sont des émetteurs positionnels : on les entend plus fort et
## de plus en plus à gauche ou à droite à mesure qu'on s'en approche. Les pas changent avec le sol.

const Assets := preload("res://scripts/core/assets.gd")

static var inst: Node

## Ambiances par zone : réverbération (taille de la pièce, amortissement, part de signal réverbéré) et coupure du vent.
const ENVIRONMENTS := {
	"default": {"room": 0.15, "damp": 0.6, "wet": 0.05, "wind_hz": 20000.0},
	"house": {"room": 0.30, "damp": 0.7, "wet": 0.10, "wind_hz": 700.0},
	"home": {"room": 0.30, "damp": 0.7, "wet": 0.10, "wind_hz": 700.0},
	"bridge": {"room": 0.45, "damp": 0.4, "wet": 0.10, "wind_hz": 20000.0},
	"market": {"room": 0.30, "damp": 0.6, "wet": 0.08, "wind_hz": 20000.0},
	"cave": {"room": 0.70, "damp": 0.65, "wet": 0.16, "wind_hz": 1200.0},
	"peak": {"room": 0.70, "damp": 0.30, "wet": 0.18, "wind_hz": 20000.0},
	"graves": {"room": 0.55, "damp": 0.45, "wet": 0.12, "wind_hz": 20000.0},
	"spirits": {"room": 0.35, "damp": 0.55, "wet": 0.09, "wind_hz": 20000.0},
}

## Matière du sol selon la zone, pour les pas.
const SURFACES := {
	"house": "wood", "home": "wood",
	"street": "grass", "love": "grass", "graves": "grass", "peak": "stone",
	"bridge": "stone", "cave": "stone",
}

var _pool: Array[AudioStreamPlayer] = []
var _loops: Dictionary = {}
var _next: int = 0
var _reverb: AudioEffectReverb
var _wind_filter: AudioEffectLowPassFilter
var _env_tween: Tween
var _world_bus: int = 0
var _wind_bus: int = 0


func _ready() -> void:
	inst = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_buses()
	for i in range(10):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_pool.append(p)


## Bus « World » (réverbération) et « Wind » (vent filtré, qui passe ensuite par « World »).
func _build_buses() -> void:
	_world_bus = _ensure_bus("World", "Master")
	_wind_bus = _ensure_bus("Wind", "World")
	if AudioServer.get_bus_effect_count(_world_bus) > 0:  # déjà construits (deuxième instance, tests)
		_reverb = AudioServer.get_bus_effect(_world_bus, 0)
		_wind_filter = AudioServer.get_bus_effect(_wind_bus, 0)
		return
	_reverb = AudioEffectReverb.new()
	_reverb.room_size = 0.15
	_reverb.damping = 0.6
	_reverb.wet = 0.05
	_reverb.dry = 1.0
	_reverb.spread = 0.9
	AudioServer.add_bus_effect(_world_bus, _reverb)
	_wind_filter = AudioEffectLowPassFilter.new()
	_wind_filter.cutoff_hz = 20000.0
	AudioServer.add_bus_effect(_wind_bus, _wind_filter)


func _ensure_bus(bus_name: String, send: String) -> int:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		AudioServer.add_bus()
		idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, send)
	return idx


## Sons de l'interface et des cinématiques : droit sur le bus principal, sans réverbération.
static func play(sound_name: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if inst == null:
		return
	inst._play(sound_name, volume_db, pitch, "Master")


## Son du monde (réverbéré selon la zone).
static func play_world(sound_name: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if inst == null:
		return
	inst._play(sound_name, volume_db, pitch, "World")


## Un pas : la matière dépend de la zone (plancher, pierre, herbe), avec un peu de hasard pour ne pas se répéter.
static func footstep(zone_id: String, running: bool = false) -> void:
	if inst == null:
		return
	var kind: String = SURFACES.get(zone_id, "")
	var sound := "step" if kind == "" else "step_" + kind
	var vol := -12.0 + randf_range(-1.5, 1.0) + (3.0 if running else 0.0)
	inst._play(sound, vol, randf_range(0.9, 1.1) * (1.08 if running else 1.0), "World")


func _play(sound_name: String, volume_db: float, pitch: float, bus: String) -> void:
	var stream := Assets.sound(sound_name)
	if stream == null or _pool.is_empty():
		return
	var p := _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = stream
	p.bus = bus
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()


# --------------------------------------------------------------------------------------------- ambiances

## Ambiance en boucle (vent, gouttes de la grotte, grillons). Une seule instance par nom.
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
	var p := AudioStreamPlayer.new()
	p.stream = _looping(stream)
	p.bus = "Wind" if sound_name == "air" else "World"
	p.volume_db = -60.0
	add_child(p)
	p.play()
	create_tween().tween_property(p, "volume_db", volume_db, 2.0)
	_loops[sound_name] = p


static func _looping(stream: AudioStreamWAV) -> AudioStreamWAV:
	var s := stream.duplicate() as AudioStreamWAV
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = s.data.size() / 2 if not s.stereo else s.data.size() / 4
	return s


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


## Réverbération et étouffement du vent pour une zone du monde ; la transition dure un instant (on passe une porte, on entre dans la grotte).
static func set_environment(zone_id: String, seconds: float = 1.5) -> void:
	if inst == null:
		return
	inst._set_environment(ENVIRONMENTS.get(zone_id, ENVIRONMENTS["default"]), seconds)


func _set_environment(preset: Dictionary, seconds: float) -> void:
	if _env_tween != null and _env_tween.is_valid():
		_env_tween.kill()
	_env_tween = create_tween().set_parallel(true)
	_env_tween.tween_property(_reverb, "room_size", float(preset["room"]), seconds)
	_env_tween.tween_property(_reverb, "damping", float(preset["damp"]), seconds)
	_env_tween.tween_property(_reverb, "wet", float(preset["wet"]), seconds)
	_env_tween.tween_property(_wind_filter, "cutoff_hz", float(preset["wind_hz"]), seconds)


## Ouvre ou ferme le vent d'extérieur (la porte de la maison qui s'ouvre laisse entrer l'air du dehors).
static func open_outside(amount: float, seconds: float = 1.2) -> void:
	if inst == null:
		return
	var hz := lerpf(700.0, 20000.0, clampf(amount, 0.0, 1.0))
	inst.create_tween().tween_property(inst._wind_filter, "cutoff_hz", hz, seconds)


# --------------------------------------------------------------------------------------- sources positionnelles

## Source sonore fixe dans le monde : plus on s'approche, plus on l'entend, avec un décalage gauche-droite.
## `parent` la porte (elle disparaît avec lui), `pos` est une position dans le monde. Boucle par défaut.
static func emitter(parent: Node, sound_name: String, pos: Vector2, volume_db: float = -18.0, max_distance: float = 500.0, pitch: float = 1.0) -> AudioStreamPlayer2D:
	var stream := Assets.sound(sound_name)
	if stream == null or parent == null:
		return null
	var p := AudioStreamPlayer2D.new()
	p.stream = _looping(stream)
	p.bus = "World"
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.max_distance = max_distance
	p.attenuation = 1.6
	p.panning_strength = 1.0
	p.process_mode = Node.PROCESS_MODE_PAUSABLE
	p.position = pos
	parent.add_child(p)
	p.play(randf() * maxf(stream.get_length() - 0.1, 0.0))  # départ au hasard : deux sources identiques ne sonnent pas en phase
	return p


static func set_master(linear: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(clampf(linear, 0.0001, 1.0)))
