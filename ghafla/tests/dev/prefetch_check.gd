extends Node
const QuranText := preload("res://scripts/core/quran_text.gd")
func _ready() -> void:
	var qt := QuranText.new()
	add_child(qt)
	qt.base_url = "http://127.0.0.1:8765/p/"
	var dir := DirAccess.open("user://mushaf_text")
	if dir != null:
		for f in dir.get_files():
			dir.remove(f)
	qt.progress.connect(func(d: int, t: int) -> void:
		if d % 100 == 0 or d == t:
			print("[pf] ", d, "/", t))
	print("[pf] manquantes avant : ", qt.missing_count())
	qt.prefetch_all()
	await get_tree().create_timer(15.0).timeout
	print("[pf] manquantes après : ", qt.missing_count(), " complet=", qt.is_complete())
	get_tree().quit()
