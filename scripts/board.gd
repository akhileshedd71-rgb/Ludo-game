class_name LudoBoard
extends Control

signal token_chosen(index: int)
var game: LudoGame
var can_select := true
var hit_targets: Array = []
var phase := 0.0
var moving_player := -1
var moving_token := -1
var moving_position := Vector2.ZERO
const CELL := 40.0
const ORIGIN := Vector2(20,20)

func _ready() -> void:
	custom_minimum_size = Vector2(640,640)
	size = Vector2(640,640)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _process(delta: float) -> void:
	if moving_player>=0 or (game and can_select and game.awaiting_move):
		phase += delta
		queue_redraw()

func _draw() -> void:
	draw_style_box(LaneUI.box(Color(0,0,0,0.25),30),Rect2(0,8,640,640))
	draw_style_box(LaneUI.box(Color("f6eedf"),30,Color("fff9ef"),2),Rect2(0,0,640,640))
	var corners := [Vector2(0,0),Vector2(9,0),Vector2(9,9),Vector2(0,9)]
	for color in 4:
		var active := false
		if game:
			for p in game.players:
				if int(p.color) == color:
					active = true
		var col: Color = LaneUI.COLORS[color] if active else LaneUI.COLORS[color].lerp(Color("ccc7c2"),0.67)
		var base: Vector2 = ORIGIN + corners[color] * CELL
		draw_style_box(LaneUI.box(col,16),Rect2(base,Vector2(240,240)))
		draw_style_box(LaneUI.box(col.lightened(0.22),12),Rect2(base+Vector2(12,12),Vector2(216,216)))
		draw_style_box(LaneUI.box(Color("fff8ec"),20),Rect2(base+Vector2(37,37),Vector2(166,166)))
		for t in 4:
			var point := yard_position(color,t)
			draw_circle(point,23,col.lightened(0.56),true,-1,true)
			draw_arc(point,23,0,TAU,32,col.lightened(0.25),2,true)
		if game and game.winner < 0 and int(game.players[game.current].color) == color:
			draw_style_box(LaneUI.box(Color.TRANSPARENT,16,Color("fff9e5"),3),Rect2(base+Vector2(4,4),Vector2(232,232)))
	for y in 15:
		for x in 15:
			if not (x in range(6,9) or y in range(6,9)) or (x in range(6,9) and y in range(6,9)):
				continue
			var fill := Color("fffaf0")
			if y==7 and x in range(1,6): fill=LaneUI.COLORS[0].lightened(0.17)
			if x==7 and y in range(1,6): fill=LaneUI.COLORS[1].lightened(0.17)
			if y==7 and x in range(9,14): fill=LaneUI.COLORS[2].lightened(0.17)
			if x==7 and y in range(9,14): fill=LaneUI.COLORS[3].lightened(0.17)
			for c in 4:
				if LudoGame.PATH[c*13] == Vector2i(x,y): fill=LaneUI.COLORS[c]
			draw_style_box(LaneUI.box(fill,3,Color("ded8cf"),1),Rect2(ORIGIN+Vector2(x,y)*CELL+Vector2.ONE,Vector2(38,38)))
	for safe in LudoGame.SAFE:
		var cell: Vector2 = Vector2(LudoGame.PATH[safe])
		var is_start: bool = safe%13==0
		draw_colored_polygon(LaneIcon.star(ORIGIN+(cell+Vector2(0.5,0.5))*CELL,13,6),Color(1,1,1,0.9) if is_start else Color("b9b5b4"))
	var a := ORIGIN+Vector2(6,6)*CELL
	var mid := a+Vector2(60,60)
	var vertices := [a,a+Vector2(120,0),a+Vector2(120,120),a+Vector2(0,120)]
	for c in 4:
		var first: Vector2 = vertices[posmod(c-1,4)]
		var second: Vector2 = vertices[c]
		draw_colored_polygon(PackedVector2Array([mid,first,second]),LaneUI.COLORS[c])
		draw_line(first,mid,Color(1,1,1,0.4),2,true)
	draw_circle(mid,19,Color("fff4d8"),true,-1,true)
	draw_colored_polygon(LaneIcon.star(mid,13,6),Color("c99636"))
	hit_targets.clear()
	if not game:
		return
	var groups: Dictionary = {}
	for p in game.players.size():
		for t in game.tokens[p].size():
			if p==moving_player and t==moving_token:
				continue
			var point := token_position(p,t)
			var key := "%d,%d" % [point.x,point.y]
			if not groups.has(key): groups[key]=[]
			groups[key].append({"player":p,"token":t,"position":point})
	var legal := game.legal_moves()
	for group in groups.values():
		for i in group.size():
			var info: Dictionary = group[i]
			var point: Vector2 = info.position
			var factor := 1.0
			if group.size()>1:
				factor = 0.68 if group.size()>2 else 0.8
				point += Vector2((i%2)*18-9,(i/2 as int)*17-5)
			var selectable: bool = can_select and info.player==game.current and legal.has(info.token)
			_draw_token(point,LaneUI.COLORS[int(game.players[info.player].color)],info.token,selectable,factor)
			if selectable:
				hit_targets.append({"position":point,"token":info.token})
	if moving_player>=0:
		_draw_token(moving_position,LaneUI.COLORS[int(game.players[moving_player].color)],moving_token,false,1.08)

func _draw_token(point: Vector2,col: Color,index: int,selected: bool,factor: float) -> void:
	if selected:
		var r := (25.0+sin(phase*5.0)*2.0)*factor
		draw_circle(point,r,Color(1,0.98,0.86,0.8),true,-1,true)
		draw_arc(point,r,0,TAU,36,Color("8e692a"),2,true)
	var p := point
	draw_set_transform(p,0,Vector2(factor,factor))
	draw_style_box(LaneUI.box(Color(0.12,0.11,0.18,0.2),10),Rect2(-18,8,38,17))
	draw_style_box(LaneUI.box(col.darkened(0.3),10),Rect2(-17,6,34,15))
	draw_style_box(LaneUI.box(col,10),Rect2(-17,3,34,14))
	draw_colored_polygon(PackedVector2Array([Vector2(-13,8),Vector2(-7,-12),Vector2(7,-12),Vector2(13,8)]),col)
	draw_circle(Vector2(0,-13),12,col.darkened(0.18),true,-1,true)
	draw_circle(Vector2(0,-15),11,col.lightened(0.15),true,-1,true)
	draw_circle(Vector2(-3,-19),4,Color(1,1,1,0.42),true,-1,true)
	draw_string(LaneUI.HEAVY,Vector2(-4,10),str(index+1),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("fffbea"))
	draw_set_transform(Vector2.ZERO)

func yard_position(color: int,token: int) -> Vector2:
	var corner: Vector2 = [Vector2(0,0),Vector2(9,0),Vector2(9,9),Vector2(0,9)][color]
	return ORIGIN+(corner+Vector2(2.0+(token%2)*2.0,2.0+(token/2 as int)*2.0))*CELL

func progress_position(player: int,progress: int) -> Vector2:
	var color: int = game.players[player].color
	if progress<=50:
		return ORIGIN+(Vector2(LudoGame.PATH[game.global_cell(player,progress)])+Vector2(0.5,0.5))*CELL
	var depth := progress-50
	var cell: Vector2
	match color:
		0: cell=Vector2(depth,7)
		1: cell=Vector2(7,depth)
		2: cell=Vector2(14-depth,7)
		_: cell=Vector2(7,14-depth)
	return ORIGIN+(cell+Vector2(0.5,0.5))*CELL

func token_position(player: int,token: int) -> Vector2:
	var progress: int = game.tokens[player][token]
	return yard_position(game.players[player].color,token) if progress<0 else progress_position(player,progress)

func animate_move(result: Dictionary) -> void:
	moving_player = result.player
	moving_token = result.token
	moving_position = yard_position(game.players[moving_player].color,moving_token) if result.from<0 else progress_position(moving_player,result.from)
	var start: int = 0 if result.from<0 else result.from+1
	for step in range(start,int(result.to)+1):
		var tween := create_tween()
		tween.tween_property(self,"moving_position",progress_position(moving_player,step),0.11).set_trans(Tween.TRANS_SINE)
		await tween.finished
	moving_player = -1
	moving_token = -1
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed and can_select:
		var best := -1
		var distance := 28.0
		for target in hit_targets:
			var d: float = event.position.distance_to(target.position)
			if d<distance:
				distance=d
				best=target.token
		if best>=0:
			accept_event()
			token_chosen.emit(best)
