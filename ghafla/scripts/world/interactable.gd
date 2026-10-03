extends Node2D
## Objet avec lequel on peut interagir (touche E / bouton tactile) : fouiller un vêtement, toucher une veine de lumière…
## La détection se fait par distance (voir player.gd), sans moteur physique.

const I18n := preload("res://scripts/core/i18n.gd")

signal used(id: String)

var id: String = ""
var prompt_key: String = "world.interact"  # clé de texte (locales/<langue>/world.json) : traduite au moment de l'affichage
var enabled: bool = true
var used_once: bool = true
var draw_kind: String = ""  # "vein" | ""
var focus_dy: float = 0.0
var _done: bool = false
var _save: RefCounted
var _t: float = 0.0


func _ready() -> void:
	add_to_group("interactable")


## Retient dans la sauvegarde qu'on a déjà utilisé cet objet (il ne se réactive pas au rechargement).
func remember_in(save: RefCounted) -> void:
	_save = save
	if save.flag("used_" + id):
		_done = true


func can_interact() -> bool:
	return enabled and not _done


func prompt_text() -> String:
	return I18n.t(prompt_key)


func interact(_player: Node) -> void:
	if _done:
		return
	if used_once:
		_done = true
		if _save != null:
			_save.set_flag("used_" + id)
	used.emit(id)
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	if draw_kind == "vein":
		queue_redraw()


func _draw() -> void:
	if draw_kind == "vein":
		var a := 0.35 + 0.25 * sin(_t * 2.0)
		if _done:
			a = 0.2
		# Une veine de lumière dans la roche : trait irrégulier lumineux
		var pts := PackedVector2Array([Vector2(-6, 50), Vector2(4, 22), Vector2(-4, -6), Vector2(8, -36), Vector2(0, -64)])
		draw_polyline(pts, Color(0.6, 0.9, 1.0, a), 3.0, true)
		draw_polyline(pts, Color(1, 1, 1, a * 0.8), 1.2, true)
