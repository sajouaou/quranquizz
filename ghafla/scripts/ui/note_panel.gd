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
		l.add_theme_font_size_override("font_size", 21)
		box.add_child(l)
	_button = Button.new()
	_button.text = "J'ai compris"
	_button.custom_minimum_size = Vector2(260, 0)
	_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_button.pressed.connect(func() -> void: accepted.emit())
	box.add_child(_button)
	_button.grab_focus()
