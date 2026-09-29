extends Node
## Aperçu de développement : lance la cinématique seule.

const Inputs := preload("res://scripts/core/inputs.gd")
const Sfx := preload("res://scripts/core/sfx.gd")
const Cinematic := preload("res://scripts/cinematic/cinematic.gd")

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
