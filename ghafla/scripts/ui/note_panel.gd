extends Control
## Note de départ : cette histoire est une fiction symbolique. Elle est affichée avant la première partie
## et reste consultable depuis le menu (« À propos »).

const P := preload("res://scripts/core/palette.gd")
const UiTheme := preload("res://scripts/ui/ui_theme.gd")

signal accepted

const TITLE := "Une histoire imaginée"
const PARAGRAPHS := [
	"Ghafla est une fiction. Le personnage, son rêve, le monde qu'il traverse et les lieux où il retrouve les pages sont inventés, pour illustrer une idée : la négligence (ghafla) peut nous gagner sans bruit, et il n'est jamais trop tard pour revenir.",
	"Ce n'est ni un enseignement religieux, ni un avis sur la façon dont d'autres personnes pratiquent. Le jeu ne juge personne et ne se moque de rien : pour apprendre la religion, on s'adresse à des gens de science et on lit le Coran lui-même.",
	"Le texte du Coran n'est jamais écrit à la main dans le jeu : les pages sont affichées à partir d'une source de texte reconnue, ou seulement suggérées par des traits si le texte n'est pas disponible. Les citations en français sont marquées « sens approximatif » : ce sont des résumés, pas une traduction du Coran.",
	"Volontairement, il n'y a ni visage, ni statue, ni image de personne, et pas de musique.",
]
const DOWNLOAD_TEXT := "Téléchargement : pendant la cinématique d'ouverture, le jeu peut télécharger le texte de tout le Mushaf (604 pages, environ 2 Mo, une seule fois, connexion Internet nécessaire). Il est gardé sur l'appareil ; sans lui, les pages du livre affichent seulement des traits."

var offer_download: bool = false  # première partie : on prévient du téléchargement du texte du Mushaf et on demande
var download: bool = true
var _button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.07, 0.94)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(880, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	var title := Label.new()
	title.text = TITLE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", P.GOLD)
	box.add_child(title)
	for text in PARAGRAPHS:
		var l := Label.new()
		l.text = text
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_font_size_override("font_size", 19 if offer_download else 21)
		box.add_child(l)
	if offer_download:
		var d := Label.new()
		d.text = DOWNLOAD_TEXT
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.add_theme_font_size_override("font_size", 19)
		d.add_theme_color_override("font_color", Color(1.0, 0.93, 0.72))
		box.add_child(d)
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 16)
		box.add_child(row)
		_button = _choice(row, "Télécharger (recommandé)", true)
		_choice(row, "Plus tard, je joue hors ligne", false)
	else:
		_button = Button.new()
		_button.text = "J'ai compris"
		_button.custom_minimum_size = Vector2(260, 0)
		_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_button.pressed.connect(func() -> void: accepted.emit())
		box.add_child(_button)
	_button.grab_focus()


func _choice(row: Control, label: String, value: bool) -> Button:
	var b := Button.new()
	b.text = label
	b.pressed.connect(func() -> void:
		download = value
		accepted.emit())
	row.add_child(b)
	return b
