extends Control
## The screen uses a 720 x 1280 portrait canvas with generous touch targets.

const HERO = preload("res://assets/art/hero.png")
const RULES := "01   ROLL A SIX\nBring a pawn out of its yard. A six also earns another roll. Three sixes in a row forfeit the third roll.\n\n02   MAKE YOUR MOVE\nTap a glowing pawn, or its numbered button. Move clockwise along the track.\n\n03   SEND THEM HOME\nLand on a rival to send their pawn back to its yard. Star squares protect every pawn on them. Pawns may share squares; there are no blockades.\n\n04   RACE TO THE CENTER\nEnter your own colored lane and roll the exact number to finish. A capture or a finished pawn earns another roll.\n\n05   TAKE THE CROWN\nBring all four pawns home first. In Quick, race just two pawns, with one already on the board."

var canvas: Control
var screen: Control
var overlay: Control
var page := "home"
var game: LudoGame
var board: LudoBoard
var saved_game: LudoGame
var settings := LaneStorage.settings()
var busy := false
var modal := false
var ai_delay := 1.0
var count := 2
var quick := false
var seats: Array = []
var name_fields: Array[LineEdit] = []
var mode_computer := false
var roll_button: Button
var die_icon: LaneIcon
var turn_label: Label
var status_label: Label
var hint_label: Label
var player_panels: Array[Panel] = []
var progress_labels: Array[Label] = []
var move_buttons: Array[Button] = []
var pause_button: Button
var sound_player: AudioStreamPlayer
var save_warning := false
var screen_revision := 0

func _ready() -> void:
	get_tree().auto_accept_quit = false
	get_tree().quit_on_go_back = false
	var background := ColorRect.new()
	background.color = LaneUI.BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(background)
	canvas = Control.new()
	canvas.size = Vector2(720,1280)
	add_child(canvas)
	resized.connect(_layout)
	_layout()
	sound_player=AudioStreamPlayer.new()
	sound_player.volume_db=-9
	add_child(sound_player)
	saved_game=LaneStorage.load_game()
	show_home()

func _layout() -> void:
	if canvas:
		canvas.position=(size-Vector2(720,1280))*0.5

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_PAUSED or what==NOTIFICATION_WM_CLOSE_REQUEST:
		_save_match()
		if what==NOTIFICATION_WM_CLOSE_REQUEST: get_tree().quit()
	elif what==NOTIFICATION_WM_GO_BACK_REQUEST:
		_back()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_back()
		get_viewport().set_input_as_handled()
	elif page=="game" and not modal and not busy and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_SPACE: _roll()
		elif event.keycode>=KEY_1 and event.keycode<=KEY_4: _select_token(event.keycode-KEY_1)

func _process(delta: float) -> void:
	if page!="game" or game==null or busy or modal or game.winner>=0:
		return
	if game.players[game.current].cpu:
		ai_delay-=delta
		if ai_delay<=0:
			ai_delay=0.85
			if game.awaiting_move: _perform_move(game.choose_cpu_move())
			else: _roll(true)

func _fresh(next: String) -> void:
	screen_revision+=1
	if is_instance_valid(overlay):
		canvas.remove_child(overlay)
		overlay.queue_free()
	overlay=null
	if is_instance_valid(screen):
		canvas.remove_child(screen)
		screen.queue_free()
	modal=false
	page=next
	screen=Control.new()
	screen.size=Vector2(720,1280)
	canvas.add_child(screen)
	name_fields.clear()

func _icon(parent: Node, kind: String, pos: Vector2, width: float=40, tint: Color=LaneUI.INK) -> LaneIcon:
	var icon := LaneIcon.new()
	icon.kind=kind
	icon.position=pos
	icon.size=Vector2(width,width)
	icon.tint=tint
	parent.add_child(icon)
	return icon

func _icon_button(parent: Node, kind: String, pos: Vector2, callback: Callable) -> Button:
	var button := LaneUI.button(parent,"",Rect2(pos,Vector2(60,60)),callback)
	_icon(button,kind,Vector2(10,10))
	button.tooltip_text=kind.capitalize()
	return button

func _eyebrow(parent: Node, text: String, y: float) -> void:
	LaneUI.label(parent,text,Rect2(40,y,640,28),16,LaneUI.MUTED,true,HORIZONTAL_ALIGNMENT_CENTER)

func show_home() -> void:
	_fresh("home")
	busy=false
	saved_game=LaneStorage.load_game()
	_icon(screen,"dice",Vector2(40,48),44,LaneUI.GOLD)
	LaneUI.label(screen,"LUDO LANE",Rect2(96,42,470,56),36,LaneUI.INK,true)
	_icon_button(screen,"settings",Vector2(620,40),show_settings)
	LaneUI.label(screen,"A LITTLE FRIENDLY RIVALRY",Rect2(42,104,530,30),16,LaneUI.MUTED,true)
	var art := TextureRect.new()
	art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	art.texture=HERO
	art.position=Vector2(0,148)
	art.size=Vector2(720,480)
	art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter=MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code="shader_type canvas_item; void fragment(){ vec4 c=texture(TEXTURE,UV); float edge=smoothstep(0.0,0.15,UV.x)*smoothstep(0.0,0.15,1.0-UV.x)*smoothstep(0.0,0.16,UV.y)*smoothstep(0.0,0.15,1.0-UV.y); COLOR=vec4(c.rgb,c.a*edge); }"
	var material := ShaderMaterial.new()
	material.shader=shader
	art.material=material
	screen.add_child(art)
	LaneUI.label(screen,"Good company. Great rivalries.",Rect2(24,587,672,54),29,LaneUI.INK,true,HORIZONTAL_ALIGNMENT_CENTER)
	LaneUI.label(screen,"One board. Your favorite people.",Rect2(40,644,640,38),21,LaneUI.MUTED,false,HORIZONTAL_ALIGNMENT_CENTER)
	var friends := LaneUI.button(screen,"",Rect2(40,720,640,96),func(): _open_setup(false),true)
	_icon(friends,"person",Vector2(28,24),44,LaneUI.BG)
	LaneUI.label(friends,"Play with friends",Rect2(92,11,485,42),28,LaneUI.BG,true)
	LaneUI.label(friends,"PASS & PLAY  ·  2–4 PLAYERS",Rect2(94,53,480,28),15,Color("725731"),true)
	LaneUI.label(friends,"→",Rect2(567,18,48,55),34,LaneUI.BG)
	var cpu := LaneUI.button(screen,"",Rect2(40,840,640,96),func(): _open_setup(true))
	_icon(cpu,"robot",Vector2(28,24),44,Color("b5a4f5"))
	LaneUI.label(cpu,"Challenge the computer",Rect2(92,11,520,42),26,LaneUI.INK,true)
	LaneUI.label(cpu,"YOUR NEXT RIVAL IS ALWAYS READY",Rect2(94,53,500,28),14,LaneUI.MUTED,true)
	if saved_game:
		LaneUI.button(screen,"Continue your match   →",Rect2(40,961,640,65),_resume,false,Color("2b3443"))
	else:
		LaneUI.panel(screen,Rect2(40,968,307,98),LaneUI.PANEL.darkened(0.16),22)
		LaneUI.panel(screen,Rect2(365,968,315,98),LaneUI.PANEL.darkened(0.16),22)
		_icon(screen,"star",Vector2(58,996),34,LaneUI.GOLD)
		LaneUI.label(screen,"Classic & Quick",Rect2(105,984,232,38),20,LaneUI.INK,true)
		LaneUI.label(screen,"Your pace. Your game.",Rect2(105,1022,240,25),14,LaneUI.MUTED)
		_icon(screen,"trophy",Vector2(383,996),34,Color("9ce0c9"))
		LaneUI.label(screen,"%d games played" % settings.matches,Rect2(427,984,243,38),20,LaneUI.INK,true)
		LaneUI.label(screen,"Make it a game night.",Rect2(427,1022,244,25),14,LaneUI.MUTED)
	LaneUI.button(screen,"How to play",Rect2(218,1102,284,58),show_rules,false,LaneUI.BG)
	_eyebrow(screen,"OFFLINE ALWAYS  •  NO ADS  •  JUST PLAY",1210)

func _open_setup(computer: bool) -> void:
	_sound("tap")
	mode_computer=computer
	count=2
	quick=false
	seats=[]
	for i in 4:
		seats.append({"name":"You" if computer and i==0 else ("Computer %d" % i if computer else "Player %d" % (i+1)),"cpu":computer and i>0,"color":i})
	show_setup()

func _capture_names() -> void:
	for i in name_fields.size():
		if is_instance_valid(name_fields[i]):
			var text := name_fields[i].text.strip_edges()
			seats[i].name=text if not text.is_empty() else "Player %d" % (i+1)

func show_setup() -> void:
	_capture_names()
	_fresh("setup")
	_icon_button(screen,"back",Vector2(40,40),show_home)
	LaneUI.label(screen,"Make it your game",Rect2(120,44,540,54),32,LaneUI.INK,true)
	LaneUI.label(screen,"Gather around. Pick your seats.",Rect2(40,123,640,43),23,LaneUI.MUTED)
	LaneUI.label(screen,"PLAYERS",Rect2(40,200,640,28),16,LaneUI.MUTED,true)
	for n in range(2,5):
		var button := LaneUI.button(screen,"%d players" % n,Rect2(40+(n-2)*220,243,200,66),func(): count=n; show_setup(),count==n)
		button.add_theme_font_size_override("font_size",22)
	LaneUI.label(screen,"THE LINEUP",Rect2(40,350,390,28),16,LaneUI.MUTED,true)
	LaneUI.label(screen,"Tap a seat to switch",Rect2(410,350,270,28),16,LaneUI.MUTED,false,HORIZONTAL_ALIGNMENT_RIGHT)
	var palette: Array = [0,2] if count==2 else ([0,1,2] if count==3 else [0,1,2,3])
	for i in count:
		seats[i].color=palette[i]
		var y := 402+i*111
		var col: Color = LaneUI.COLORS[palette[i]]
		LaneUI.panel(screen,Rect2(40,y,640,94),LaneUI.PANEL,22,col.darkened(0.55))
		LaneUI.panel(screen,Rect2(58,y+16,62,62),col.darkened(0.74),18)
		_icon(screen,"robot" if seats[i].cpu else "person",Vector2(69,y+27),40,col)
		var edit := LineEdit.new()
		edit.position=Vector2(137,y+12)
		edit.size=Vector2(290,43)
		edit.text=seats[i].name
		edit.max_length=14
		edit.placeholder_text="Player %d" % (i+1)
		edit.add_theme_font_override("font",LaneUI.MEDIUM)
		edit.add_theme_font_size_override("font_size",23)
		edit.add_theme_color_override("font_color",LaneUI.INK)
		edit.add_theme_stylebox_override("normal",LaneUI.box(Color.TRANSPARENT,8))
		edit.add_theme_stylebox_override("focus",LaneUI.box(LaneUI.BG,8,col,1))
		screen.add_child(edit)
		name_fields.append(edit)
		LaneUI.label(screen,LudoGame.COLOR_NAMES[palette[i]],Rect2(155,y+53,255,27),15,col)
		var button := LaneUI.button(screen,"Computer" if seats[i].cpu else "Human",Rect2(466,y+19,194,56),func(): _toggle_seat(i),false,LaneUI.BG)
		button.add_theme_font_size_override("font_size",18)
	if count==2:
		LaneUI.panel(screen,Rect2(40,651,640,165),Color("1a2137"),24)
		_icon(screen,"dice",Vector2(67,700),52,Color("97d9c4"))
		LaneUI.label(screen,"Same screen. Shared laughs.",Rect2(145,674,505,41),24,LaneUI.INK,true)
		var tip := LaneUI.label(screen,"Pass the phone on your turn, or switch a seat to Computer for a ready-to-play rival.",Rect2(145,723,500,65),18,LaneUI.MUTED)
		tip.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	LaneUI.label(screen,"PICK YOUR PACE",Rect2(40,869,600,26),16,LaneUI.MUTED,true)
	var classic := LaneUI.button(screen,"",Rect2(40,916,310,104),func(): quick=false; show_setup(),not quick)
	LaneUI.label(classic,"Classic",Rect2(24,13,255,38),25,LaneUI.BG if not quick else LaneUI.INK,true)
	LaneUI.label(classic,"4 pawns · the full rivalry",Rect2(24,55,269,29),16,Color("725731") if not quick else LaneUI.MUTED)
	var fast := LaneUI.button(screen,"",Rect2(370,916,310,104),func(): quick=true; show_setup(),quick)
	LaneUI.label(fast,"Quick",Rect2(24,13,260,38),25,LaneUI.BG if quick else LaneUI.INK,true)
	LaneUI.label(fast,"2 pawns · straight to it",Rect2(24,55,269,29),16,Color("725731") if quick else LaneUI.MUTED)
	LaneUI.button(screen,"Let's play   →",Rect2(40,1070,640,88),_start_requested,true)
	_eyebrow(screen,"ONE DEVICE. EVERYONE'S INVITED.",1205)

func _toggle_seat(i: int) -> void:
	_capture_names()
	seats[i].cpu=not seats[i].cpu
	show_setup()

func _start_requested() -> void:
	_capture_names()
	if LaneStorage.load_game():
		var content := _modal_box("Start a fresh match?",470)
		LaneUI.label(content,"Your saved match will be replaced.",Rect2(28,100,584,72),23,LaneUI.MUTED,false,HORIZONTAL_ALIGNMENT_CENTER)
		LaneUI.button(content,"Start new match",Rect2(35,219,570,78),_start_match,true)
		LaneUI.button(content,"Keep my match",Rect2(35,321,570,70),_close_modal)
	else:
		_start_match()

func _start_match() -> void:
	game=LudoGame.new()
	game.setup(seats.slice(0,count),quick)
	_save_match()
	show_game()
	_sound("start")

func _resume() -> void:
	game=LaneStorage.load_game()
	if game:
		show_game()
	else:
		show_home()

func show_game() -> void:
	_fresh("game")
	busy=false
	ai_delay=1.0
	pause_button=_icon_button(screen,"pause",Vector2(40,38),show_pause)
	LaneUI.label(screen,"LUDO LANE",Rect2(120,39,460,56),30,LaneUI.INK,true,HORIZONTAL_ALIGNMENT_CENTER)
	_icon_button(screen,"settings",Vector2(620,38),show_settings)
	_eyebrow(screen,("QUICK" if game.quick else "CLASSIC")+"  /  %d PLAYERS  /  OFFLINE" % game.players.size(),111)
	board=LudoBoard.new()
	board.game=game
	board.position=Vector2(40,250)
	board.token_chosen.connect(_select_token)
	screen.add_child(board)
	player_panels.clear()
	progress_labels.clear()
	for p in game.players.size():
		var color: int = game.players[p].color
		var pos: Vector2 = [Vector2(40,159),Vector2(380,159),Vector2(380,916),Vector2(40,916)][color]
		var col: Color = LaneUI.COLORS[color]
		var card := LaneUI.panel(screen,Rect2(pos,Vector2(300,74)),LaneUI.PANEL,20)
		player_panels.append(card)
		_icon(card,"robot" if game.players[p].cpu else "person",Vector2(15,15),40,col)
		var name_label := LaneUI.label(card,game.players[p].name,Rect2(68,6,221,36),21,LaneUI.INK,true)
		name_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		progress_labels.append(LaneUI.label(card,"",Rect2(68,42,221,25),14,col))
	hint_label=LaneUI.label(screen,"",Rect2(35,1001,650,37),20,LaneUI.MUTED,false,HORIZONTAL_ALIGNMENT_CENTER)
	LaneUI.panel(screen,Rect2(40,1057,640,159),LaneUI.PANEL,27,Color("353954"))
	turn_label=LaneUI.label(screen,"",Rect2(65,1073,430,45),26,LaneUI.INK,true)
	status_label=LaneUI.label(screen,"",Rect2(65,1125,415,66),18,LaneUI.MUTED)
	status_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	roll_button=LaneUI.button(screen,"",Rect2(537,1077,122,116),_roll,true)
	die_icon=_icon(roll_button,"dice",Vector2(23,11),76,LaneUI.INK)
	LaneUI.label(roll_button,"ROLL",Rect2(4,83,114,26),14,LaneUI.BG,true,HORIZONTAL_ALIGNMENT_CENTER)
	move_buttons.clear()
	for t in game.tokens[0].size():
		var b := LaneUI.button(screen,str(t+1),Rect2(65+t*102,1120,90,88),func(): _select_token(t),false,Color("39355c"))
		b.tooltip_text="Move pawn %d" % (t+1)
		b.visible=false
		move_buttons.append(b)
	_eyebrow(screen,"STAR SQUARES ARE SAFE  ·  EXACT ROLL TO FINISH",1236)
	_update_game()

func _update_game(message: String="") -> void:
	if page!="game" or not is_instance_valid(board): return
	var actor: Dictionary=game.players[game.current]
	var color: Color=LaneUI.COLORS[int(actor.color)]
	turn_label.text=actor.name+"'s turn"
	turn_label.add_theme_color_override("font_color",color)
	var is_cpu: bool=actor.cpu
	var choosing: bool=game.awaiting_move and not is_cpu and not busy
	var legal := game.legal_moves()
	for i in move_buttons.size():
		move_buttons[i].visible=choosing
		move_buttons[i].disabled=not legal.has(i)
	status_label.visible=not choosing
	status_label.text=message if not message.is_empty() else ("Thinking of the next move…" if is_cpu else "Tap the dice to roll.")
	if game.awaiting_move and not busy:
		hint_label.text="Choose a glowing pawn to move %d" % game.die if not is_cpu else actor.name+" is choosing a pawn…"
	else:
		hint_label.text=message if not message.is_empty() else ("Pass the device to "+actor.name if not is_cpu else "A little strategy. A little luck.")
	if save_warning: hint_label.text="Storage unavailable. Keep the game open."
	roll_button.disabled=busy or game.awaiting_move or is_cpu or game.winner>=0
	pause_button.disabled=busy
	board.can_select=choosing and not modal
	die_icon.value=game.die if game.die>0 else 5
	die_icon.queue_redraw()
	for p in game.players.size():
		var col: Color=LaneUI.COLORS[int(game.players[p].color)]
		var active: bool=p==game.current
		player_panels[p].add_theme_stylebox_override("panel",LaneUI.box(col.darkened(0.77) if active else LaneUI.PANEL,20,col if active else Color("353954"),2 if active else 1))
		progress_labels[p].text=("PLAYING  ·  " if active else "")+"%d/%d HOME" % [game.home_count(p),game.tokens[p].size()]
	board.queue_redraw()

func _roll(by_cpu: bool=false) -> void:
	if page!="game" or busy or modal or game.awaiting_move or game.winner>=0: return
	if game.players[game.current].cpu and not by_cpu: return
	busy=true
	var result := game.roll()
	_save_match()
	_update_game("Rolling…")
	_sound("roll")
	if settings.haptics: Input.vibrate_handheld(35)
	var revision := screen_revision
	if settings.motion:
		for i in 9:
			die_icon.value=(i%6)+1
			die_icon.rotation=sin(i*1.9)*0.12
			die_icon.pivot_offset=die_icon.size*0.5
			die_icon.queue_redraw()
			await get_tree().create_timer(0.055+i*0.006).timeout
			if revision!=screen_revision: return
		die_icon.rotation=0
	die_icon.value=result.die
	die_icon.queue_redraw()
	var message := "Rolled %d" % result.die
	if result.reason=="three_sixes": message="Three sixes! The turn passes."
	elif result.reason=="no_moves": message="No move this time. Turn passes." if result.die!=6 else "No move. Six earns another roll."
	if result.reason!="choose":
		hint_label.text=message
		await get_tree().create_timer(0.85).timeout
		if revision!=screen_revision: return
	busy=false
	ai_delay=0.8
	_update_game(message)

func _select_token(index: int) -> void:
	if page!="game" or modal or busy or game.players[game.current].cpu: return
	_perform_move(index)

func _perform_move(index: int) -> void:
	if busy or modal or not game.legal_moves().has(index): return
	busy=true
	var result := game.move_token(index)
	_save_match()
	_update_game("On the move…")
	_sound("move")
	var revision := screen_revision
	if settings.motion:
		await board.animate_move(result)
		if revision!=screen_revision: return
	var message := "Nice move."
	if not result.captured.is_empty():
		message="Captured! Take another roll."
		_sound("capture")
		if settings.haptics: Input.vibrate_handheld(80)
	elif result.to==LudoGame.FINISH:
		message="Home sweet home! Roll again."
		_sound("home")
	elif result.bonus: message="A six! Take another roll."
	busy=false
	ai_delay=0.9
	_update_game(message)
	if result.winner>=0: _celebrate()

func _save_match() -> void:
	if game and game.winner<0:
		save_warning=not LaneStorage.write_json(LaneStorage.MATCH_PATH,game.to_dict())

func _save_settings() -> void:
	LaneStorage.write_json(LaneStorage.SETTINGS_PATH,settings)

func _sound(kind: String) -> void:
	if settings.sound and is_instance_valid(sound_player):
		var path := "res://assets/audio/"+kind+".wav"
		if ResourceLoader.exists(path):
			sound_player.stream=load(path)
			sound_player.play()

func _modal_box(title: String, height: float) -> Control:
	if is_instance_valid(overlay):
		canvas.remove_child(overlay)
		overlay.queue_free()
	modal=true
	if is_instance_valid(board) and page=="game": board.can_select=false
	overlay=Control.new()
	overlay.size=Vector2(720,1280)
	canvas.add_child(overlay)
	var shade := ColorRect.new()
	shade.color=Color(0.025,0.03,0.08,0.86)
	shade.size=Vector2(720,1280)
	overlay.add_child(shade)
	var content := Control.new()
	content.position=Vector2(40,(1280-height)*0.5)
	content.size=Vector2(640,height)
	overlay.add_child(content)
	LaneUI.panel(content,Rect2(Vector2.ZERO,content.size),LaneUI.PANEL,32,Color("424663"))
	LaneUI.label(content,title,Rect2(25,27,590,60),30,LaneUI.INK,true,HORIZONTAL_ALIGNMENT_CENTER)
	return content

func _close_modal() -> void:
	if is_instance_valid(overlay):
		canvas.remove_child(overlay)
		overlay.queue_free()
	overlay=null
	modal=false
	ai_delay=0.7
	if page=="game": _update_game()

func show_pause() -> void:
	if busy: return
	_sound("tap")
	_save_match()
	var content := _modal_box("Take a breather",520)
	LaneUI.label(content,"Your board will be right here.",Rect2(30,93,580,52),22,LaneUI.MUTED,false,HORIZONTAL_ALIGNMENT_CENTER)
	LaneUI.button(content,"Back to the board",Rect2(35,183,570,78),_close_modal,true)
	LaneUI.button(content,"How to play",Rect2(35,286,570,70),show_rules)
	LaneUI.button(content,"Save & leave",Rect2(35,388,570,70),func(): _save_match(); show_home())

func show_rules() -> void:
	var content := _modal_box("A classic, for a reason",1060)
	var rules := LaneUI.label(content,RULES,Rect2(38,108,564,818),22,LaneUI.INK)
	rules.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	rules.vertical_alignment=VERTICAL_ALIGNMENT_TOP
	LaneUI.button(content,"Got it. Let's play.",Rect2(35,952,570,75),_close_modal,true)

func show_settings() -> void:
	if busy: return
	var content := _modal_box("The little details",738)
	LaneUI.label(content,"Set the mood for your next move.",Rect2(30,100,580,40),21,LaneUI.MUTED,false,HORIZONTAL_ALIGNMENT_CENTER)
	var keys := ["sound","haptics","motion"]
	var titles := ["Game sounds","Touch vibration","Animations"]
	var subtitles := ["A satisfying roll, every time","A little nudge on your phone","Dice tumbles and pawn hops"]
	for i in 3:
		LaneUI.label(content,titles[i],Rect2(35,176+i*105,380,40),24,LaneUI.INK,true)
		LaneUI.label(content,subtitles[i],Rect2(35,216+i*105,400,32),16,LaneUI.MUTED)
		var key: String=keys[i]
		LaneUI.button(content,"ON" if settings[key] else "OFF",Rect2(474,182+i*105,130,62),func(): settings[key]=not settings[key]; _save_settings(); show_settings(),settings[key])
	LaneUI.button(content,"All set",Rect2(35,528,570,77),_close_modal,true)
	LaneUI.button(content,"Made with care · Credits",Rect2(100,640,440,55),show_credits,false,LaneUI.PANEL)

func show_credits() -> void:
	var content := _modal_box("Made with care",980)
	var scroll := ScrollContainer.new()
	scroll.position=Vector2(35,110)
	scroll.size=Vector2(570,700)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var copy := Label.new()
	copy.custom_minimum_size.x=542
	copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	copy.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	copy.add_theme_font_override("font",LaneUI.BODY)
	copy.add_theme_font_size_override("font_size",18)
	copy.text="LUDO LANE\nAn original offline game.\n\nHero artwork: generated for this project.\nBoard, pawns, icons and sounds: original procedural assets.\n\nMade with Godot 4.6.3.\nTypography: Open Sans, © Google Corporation.\n\n"+FileAccess.get_file_as_string("res://assets/licenses/GODOT_LICENSE.txt")+"\n\n"+FileAccess.get_file_as_string("res://assets/fonts/LICENSE.txt")+"\n\n"+FileAccess.get_file_as_string("res://assets/licenses/APACHE-2.0.txt")
	scroll.add_child(copy)
	LaneUI.button(content,"Back to the game",Rect2(35,853,570,77),_close_modal,true)

func _celebrate() -> void:
	LaneStorage.clear_game()
	settings.matches+=1
	if not game.players[game.winner].cpu: settings.wins+=1
	_save_settings()
	_sound("win")
	var content := _modal_box("A little victory. A big smile.",685)
	_icon(content,"trophy",Vector2(255,120),130,LaneUI.GOLD)
	LaneUI.label(content,game.players[game.winner].name+" wins!",Rect2(30,272,580,65),36,LaneUI.COLORS[int(game.players[game.winner].color)],true,HORIZONTAL_ALIGNMENT_CENTER)
	LaneUI.label(content,"All pawns home. Bragging rights earned.",Rect2(20,350,600,43),21,LaneUI.MUTED,false,HORIZONTAL_ALIGNMENT_CENTER)
	LaneUI.button(content,"One more round",Rect2(35,451,570,80),func(): seats=game.players.duplicate(true); count=seats.size(); quick=game.quick; _start_match(),true)
	LaneUI.button(content,"Back to the lounge",Rect2(35,561,570,72),show_home)
	if settings.motion:
		for i in 36:
			var confetti := ColorRect.new()
			confetti.color=LaneUI.COLORS[i%4]
			confetti.position=Vector2(45+(i*97)%630,-30-(i*37)%270)
			confetti.size=Vector2(7+(i%3)*3,14)
			confetti.mouse_filter=MOUSE_FILTER_IGNORE
			overlay.add_child(confetti)
			var tween := confetti.create_tween().set_parallel(true)
			tween.tween_property(confetti,"position:y",1350,3.2+(i%7)*0.22)
			tween.tween_property(confetti,"rotation",float(i%9),3.5)
			tween.chain().tween_callback(confetti.queue_free)

func _back() -> void:
	if busy: return
	if modal:
		if game and game.winner>=0 and page=="game": show_home()
		else: _close_modal()
	elif page=="game": show_pause()
	elif page=="setup": show_home()
	elif page=="home":
		var content := _modal_box("See you next round?",410)
		LaneUI.button(content,"Keep playing",Rect2(35,145,570,78),_close_modal,true)
		LaneUI.button(content,"Exit game",Rect2(35,256,570,70),func(): get_tree().quit())
