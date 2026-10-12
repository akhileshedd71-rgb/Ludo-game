class_name LaneIcon
extends Control

var kind := "dice"
var tint := LaneUI.INK
var value := 5

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE

func _draw() -> void:
	var s := size.x / 48.0
	draw_set_transform(Vector2.ZERO, 0, Vector2(s,s))
	match kind:
		"dice":
			draw_style_box(LaneUI.box(tint, 10), Rect2(3,3,42,42))
			var points: Array = []
			match value:
				1: points = [Vector2(24,24)]
				2: points = [Vector2(14,14), Vector2(34,34)]
				3: points = [Vector2(14,14), Vector2(24,24), Vector2(34,34)]
				4: points = [Vector2(14,14), Vector2(34,14), Vector2(14,34), Vector2(34,34)]
				5: points = [Vector2(14,14), Vector2(34,14), Vector2(24,24), Vector2(14,34), Vector2(34,34)]
				6: points = [Vector2(14,13), Vector2(34,13), Vector2(14,24), Vector2(34,24), Vector2(14,35), Vector2(34,35)]
			for p in points:
				draw_circle(p, 3.7, LaneUI.BG, true, -1, true)
		"back":
			draw_polyline(PackedVector2Array([Vector2(28,11),Vector2(15,24),Vector2(28,37)]),tint,3.5,true)
		"close":
			draw_line(Vector2(13,13),Vector2(35,35),tint,3.5,true)
			draw_line(Vector2(35,13),Vector2(13,35),tint,3.5,true)
		"pause":
			draw_style_box(LaneUI.box(tint,2),Rect2(14,12,6,24))
			draw_style_box(LaneUI.box(tint,2),Rect2(28,12,6,24))
		"settings":
			for i in 8:
				var v := Vector2.from_angle(i * TAU / 8.0)
				draw_line(Vector2(24,24)+v*13,Vector2(24,24)+v*18,tint,6,true)
			draw_arc(Vector2(24,24),12,0,TAU,32,tint,5,true)
			draw_circle(Vector2(24,24),4,tint,true,-1,true)
		"person":
			draw_circle(Vector2(24,15),8,tint,true,-1,true)
			draw_style_box(LaneUI.box(tint,10),Rect2(10,26,28,15))
		"robot":
			draw_line(Vector2(24,6),Vector2(24,13),tint,3,true)
			draw_circle(Vector2(24,5),3,tint,true,-1,true)
			draw_style_box(LaneUI.box(tint,8),Rect2(7,13,34,27))
			draw_circle(Vector2(17,25),3,LaneUI.BG,true,-1,true)
			draw_circle(Vector2(31,25),3,LaneUI.BG,true,-1,true)
			draw_line(Vector2(18,33),Vector2(30,33),LaneUI.BG,2,true)
		"star":
			draw_colored_polygon(star(Vector2(24,24),20,9),tint)
		"sound":
			draw_colored_polygon(PackedVector2Array([Vector2(8,19),Vector2(16,19),Vector2(26,10),Vector2(26,38),Vector2(16,29),Vector2(8,29)]),tint)
			draw_arc(Vector2(24,24),15,-PI/3,PI/3,16,tint,3,true)
		"check":
			draw_polyline(PackedVector2Array([Vector2(10,24),Vector2(21,34),Vector2(38,14)]),tint,4,true)
		"trophy":
			draw_style_box(LaneUI.box(tint,9),Rect2(13,7,22,24))
			draw_arc(Vector2(12,16),7,PI/2,PI*1.5,16,tint,3,true)
			draw_arc(Vector2(36,16),7,-PI/2,PI/2,16,tint,3,true)
			draw_line(Vector2(24,29),Vector2(24,38),tint,4,true)
			draw_line(Vector2(16,40),Vector2(32,40),tint,4,true)

static func star(center: Vector2, outer: float, inner: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 10:
		points.append(center + Vector2.from_angle(-PI/2+i*PI/5) * (outer if i%2==0 else inner))
	return points
