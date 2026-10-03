extends Node
## Aperçu de développement : lance la cinématique seule.

const Inputs := preload("res://scripts/core/inputs.gd")
const Sfx := preload("res://scripts/core/sfx.gd")
const Cinematic := preload("res://scripts/cinematic/cinematic2.gd")

var cin: Node2D


func _ready() -> void:
	Inputs.ensure_actions()
	add_child(Sfx.new())
	cin = Cinematic.new()
	cin.name = "Cinematic"
	add_child(cin)
	cin.finished.connect(func(): print("[state] cinematic finished skipped=", cin.skipped))
	cin.run()


func speed(x: float) -> void:
	Engine.time_scale = x


func sleep_scene() -> void:
	cin.skipped = true  # arrête le déroulé
	await get_tree().create_timer(0.2).timeout
	cin.skipped = false
	cin.room.warm = 0.15
	cin.room.lamp = 0.0
	cin.room.book_on_stand = true
	cin.room.night = 0.35
	cin.room.dawn = 1.0
	cin.room.ray = 1.0
	cin.blanket.visible = true
	cin.blanket.amount = 1.0
	cin.blanket.color = Color("a03f55")
	cin._fade.color = Color(0, 0, 0, 0)
	cin.closeup.bg = 0.0
	cin.rig_a.position.x = 1600.0
	cin.rig_b.position = Vector2(300.0, 560.0)
	cin.rig_b.facing = 1
	cin.rig_b.pose(cin.LIE, 0.01)
	cin.cam.zoom = Vector2.ONE
