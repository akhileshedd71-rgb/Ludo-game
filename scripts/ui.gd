class_name LaneUI
extends RefCounted

const BG := Color("11152e")
const PANEL := Color("202440")
const INK := Color("faf5e8")
const MUTED := Color("a8aecb")
const GOLD := Color("ffd074")
const COLORS := [Color("f46878"), Color("34c99c"), Color("f6c75a"), Color("619cff")]
const BODY = preload("res://assets/fonts/Body.ttf")
const HEAVY = preload("res://assets/fonts/Display.ttf")
const MEDIUM = preload("res://assets/fonts/Semibold.ttf")

static func box(color: Color, radius: int = 24, border: Color = Color.TRANSPARENT, width: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.border_color = border
	s.set_border_width_all(width)
	s.content_margin_left = 20
	s.content_margin_right = 20
	return s

static func panel(parent: Node, rect: Rect2, color: Color = PANEL, radius: int = 24, border: Color = Color.TRANSPARENT) -> Panel:
	var node := Panel.new()
	node.position = rect.position
	node.size = rect.size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_theme_stylebox_override("panel", box(color, radius, border, 1 if border.a > 0 else 0))
	parent.add_child(node)
	return node

static func label(parent: Node, content: String, rect: Rect2, font_size: int = 24, color: Color = INK, bold: bool = false, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var node := Label.new()
	node.clip_text = true
	node.text = content
	node.position = rect.position
	node.size = rect.size
	node.add_theme_font_override("font", HEAVY if bold else BODY)
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.horizontal_alignment = align
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

static func button(parent: Node, text: String, rect: Rect2, callback: Callable, primary: bool = false, color: Color = PANEL) -> Button:
	var b := Button.new()
	b.text = text
	b.position = rect.position
	b.size = rect.size
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_override("font", MEDIUM)
	b.add_theme_font_size_override("font_size", 24)
	b.add_theme_color_override("font_color", BG if primary else INK)
	b.add_theme_color_override("font_hover_color", BG if primary else INK)
	b.add_theme_color_override("font_pressed_color", BG if primary else INK)
	b.add_theme_color_override("font_disabled_color", MUTED.darkened(0.25))
	var fill := GOLD if primary else color
	var normal := box(fill, 23, fill.lightened(0.14), 1)
	normal.shadow_color = Color(0, 0, 0, 0.19)
	normal.shadow_size = 0
	normal.shadow_offset = Vector2(0, 5)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", box(fill.lightened(0.09), 23))
	b.add_theme_stylebox_override("pressed", box(fill.darkened(0.12), 23))
	b.add_theme_stylebox_override("disabled", box(PANEL.darkened(0.12), 23))
	b.add_theme_stylebox_override("focus", box(Color.TRANSPARENT, 23, INK, 2))
	b.pressed.connect(callback)
	parent.add_child(b)
	return b
