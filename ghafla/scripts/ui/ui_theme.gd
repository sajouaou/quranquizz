extends RefCounted
## Thème de l'interface : encre et parchemin, filets dorés. Tout est dessiné avec des StyleBox (aucune image).

const P := preload("res://scripts/core/palette.gd")
const Assets := preload("res://scripts/core/assets.gd")


static func panel_style(bg: Color = Color(0.04, 0.035, 0.11, 0.86), border: Color = Color(0.91, 0.77, 0.42, 0.9), radius: int = 16, border_w: int = 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.anti_aliasing = true
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	return sb


static func build() -> Theme:
	var theme := Theme.new()
	var font := Assets.font_book()
	theme.default_font = font
	theme.default_font_size = 22

	theme.set_color("font_color", "Label", P.PARCHMENT)
	theme.set_font_size("font_size", "Label", 22)

	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var bg := Color(0.09, 0.08, 0.2, 0.92)
		var border := Color(0.91, 0.77, 0.42, 0.55)
		match state:
			"hover":
				bg = Color(0.16, 0.14, 0.32, 0.96)
				border = Color(0.95, 0.82, 0.5, 0.95)
			"pressed":
				bg = Color(0.25, 0.2, 0.42, 1.0)
				border = P.GOLD
			"focus":
				bg = Color(0.14, 0.12, 0.3, 0.96)
				border = P.GOLD
			"disabled":
				bg = Color(0.09, 0.08, 0.2, 0.5)
				border = Color(0.6, 0.55, 0.4, 0.25)
		var sb := panel_style(bg, border, 12, 2)
		sb.content_margin_top = 10
		sb.content_margin_bottom = 10
		theme.set_stylebox(state, "Button", sb)
	theme.set_color("font_color", "Button", P.PARCHMENT)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.4))
	theme.set_font_size("font_size", "Button", 24)

	var slider_bg := StyleBoxFlat.new()
	slider_bg.bg_color = Color(1, 1, 1, 0.18)
	slider_bg.set_corner_radius_all(4)
	slider_bg.content_margin_top = 4
	slider_bg.content_margin_bottom = 4
	var slider_fill := StyleBoxFlat.new()
	slider_fill.bg_color = P.GOLD
	slider_fill.set_corner_radius_all(4)
	theme.set_stylebox("slider", "HSlider", slider_bg)
	theme.set_stylebox("grabber_area", "HSlider", slider_fill)
	theme.set_stylebox("grabber_area_highlight", "HSlider", slider_fill)

	theme.set_stylebox("panel", "PanelContainer", panel_style())
	theme.set_stylebox("panel", "Panel", panel_style())
	theme.set_color("font_color", "CheckButton", P.PARCHMENT)
	return theme
