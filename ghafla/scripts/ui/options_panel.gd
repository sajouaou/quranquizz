extends PanelContainer
## Réglages : volume et contrôles tactiles. Utilisé par le menu principal et par la pause.

const P := preload("res://scripts/core/palette.gd")
const UiTheme := preload("res://scripts/ui/ui_theme.gd")
const Sfx := preload("res://scripts/core/sfx.gd")
const QuranText := preload("res://scripts/core/quran_text.gd")
const Gfx := preload("res://scripts/core/gfx.gd")
const I18n := preload("res://scripts/core/i18n.gd")

signal closed
signal touch_changed
signal language_changed

const TOUCH_KEYS := ["options.touch.auto", "options.touch.on", "options.touch.off"]

var save: RefCounted
var _slider: HSlider
var _touch_button: Button
var _back: Button
var _dl_button: Button
var _lang_button: Button
var _quality_button: Button
var show_language: bool = false  # changer de langue reconstruit toute l'interface (voir main.gd)


func setup(save_data: RefCounted) -> void:
	save = save_data


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	custom_minimum_size = Vector2(560, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	add_child(box)

	var title := Label.new()
	title.text = I18n.t("options.title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", P.GOLD)
	box.add_child(title)

	var vol_label := Label.new()
	vol_label.text = I18n.t("options.volume")
	box.add_child(vol_label)
	_slider = HSlider.new()
	_slider.min_value = 0.0
	_slider.max_value = 1.0
	_slider.step = 0.05
	_slider.value = save.volume if save != null else 0.8
	_slider.custom_minimum_size = Vector2(0, 28)
	_slider.value_changed.connect(_on_volume)
	box.add_child(_slider)

	var note := Label.new()
	note.text = I18n.t("options.no_music")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 17)
	note.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	box.add_child(note)

	if show_language and I18n.languages().size() > 1:
		_lang_button = Button.new()
		_lang_button.text = I18n.t("options.language", {"name": I18n.language_name(I18n.lang)})
		_lang_button.pressed.connect(_cycle_language)
		box.add_child(_lang_button)

	_quality_button = Button.new()
	_quality_button.pressed.connect(_cycle_quality)
	box.add_child(_quality_button)
	_refresh_quality()

	_touch_button = Button.new()
	_touch_button.pressed.connect(_cycle_touch)
	box.add_child(_touch_button)
	_refresh_touch()

	_dl_button = Button.new()
	_dl_button.pressed.connect(_download_text)
	box.add_child(_dl_button)
	_refresh_dl()
	if QuranText.inst != null:
		QuranText.inst.progress.connect(func(_d: int, _t: int) -> void: _refresh_dl())

	_back = Button.new()
	_back.text = I18n.t("options.back")
	_back.pressed.connect(func() -> void: closed.emit())
	box.add_child(_back)


func focus_first() -> void:
	if _slider != null:
		_slider.grab_focus()


func _on_volume(v: float) -> void:
	if save == null:
		return
	save.volume = v
	Sfx.set_master(v)
	Sfx.play("page", -8.0, 1.0)
	save.save_file()


func _cycle_language() -> void:
	if save == null:
		return
	save.lang = I18n.next_language(I18n.lang)
	I18n.set_language(save.lang)
	save.save_file()
	language_changed.emit()


## Qualité graphique : automatique -> basse -> moyenne -> haute. S'applique tout de suite.
func _cycle_quality() -> void:
	if save == null:
		return
	save.quality = -1 if save.quality >= Gfx.HIGH else save.quality + 1
	Gfx.apply(save.quality)
	save.save_file()
	_refresh_quality()


func _refresh_quality() -> void:
	var q: int = save.quality if save != null else -1
	var keys := ["options.quality.low", "options.quality.medium", "options.quality.high"]
	if q < 0:
		_quality_button.text = I18n.t("options.quality.auto", {"name": I18n.t(keys[Gfx.level])})
	else:
		_quality_button.text = I18n.t("options.quality", {"name": I18n.t(keys[q])})


func _cycle_touch() -> void:
	if save == null:
		return
	# -1 automatique -> 1 oui -> 0 non -> -1
	match save.touch_controls:
		-1:
			save.touch_controls = 1
		1:
			save.touch_controls = 0
		_:
			save.touch_controls = -1
	save.save_file()
	_refresh_touch()
	touch_changed.emit()


func _refresh_touch() -> void:
	var idx := 0
	if save != null:
		match save.touch_controls:
			1:
				idx = 1
			0:
				idx = 2
	_touch_button.text = I18n.t(TOUCH_KEYS[idx])


func _download_text() -> void:
	if QuranText.inst == null:
		return
	if save != null:
		save.download_text = true
		save.save_file()
	QuranText.inst.prefetch_all()
	_refresh_dl()


func _refresh_dl() -> void:
	if _dl_button == null or not is_instance_valid(_dl_button):
		return
	if QuranText.inst == null:
		_dl_button.visible = false
		return
	var missing: int = QuranText.inst.missing_count()
	_dl_button.text = I18n.t("options.text_complete") if missing == 0 else I18n.t("options.text_missing", {"n": missing})
	_dl_button.disabled = missing == 0
