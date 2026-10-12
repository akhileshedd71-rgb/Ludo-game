extends SceneTree
## Run with -- --screenshots under a real display for rendered captures.
## The test runner isolates user://, so player saves are never touched.

var checks := 0
var failures := 0
var app: Control
var screenshots := false

func _initialize() -> void:
	screenshots=OS.get_cmdline_user_args().has("--screenshots")
	call_deferred("run")

func check(condition: bool,message: String) -> void:
	checks+=1
	if not condition:
		failures+=1
		push_error(message)

func settle() -> void:
	await process_frame
	await process_frame
	await process_frame

func capture(name: String) -> void:
	if screenshots:
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://build/screenshots")
		var error := root.get_texture().get_image().save_png("res://build/screenshots/"+name+".png")
		check(error==OK,"Screenshot written: "+name)

func run() -> void:
	LaneStorage.clear_game()
	app=load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await settle()
	app.settings.sound=false
	app.settings.haptics=false
	app.settings.motion=false
	check(app.page=="home","Scene opens to home")
	await capture("01-home")
	app._open_setup(false)
	await settle()
	check(app.page=="setup" and app.count==2,"Local setup defaults to two human players")
	app.count=4
	app.show_setup()
	await settle()
	app.name_fields[0].text="Avery"
	app.name_fields[1].text="Riley"
	app.name_fields[2].text="Jordan"
	app.name_fields[3].text="Sam"
	await capture("02-setup")
	app._start_requested()
	await settle()
	check(app.page=="game" and app.game.players.size()==4,"Setup creates all four seats")
	check(app.game.players[0].name=="Avery","Edited player name reaches the match")
	check(LaneStorage.load_game()!=null,"New match is saved")
	check(not app.roll_button.disabled,"Human can roll")
	await capture("03-board")
	# A real button signal invokes the asynchronous roll handler.
	app.roll_button.pressed.emit()
	await create_timer(1.1).timeout
	check(app.game.turn_count==1,"Roll button makes exactly one roll")
	check(not app.busy,"Roll unlocks the UI")
	# Set up a deterministic move and exercise pawn hit testing.
	app.game.current=0
	app.game.awaiting_move=false
	app.game.consecutive_sixes=0
	app.game.roll(6)
	app._update_game()
	await settle()
	if not screenshots:
		# Dummy rendering does not call _draw; actual display checks use drawn hit regions.
		app.board.hit_targets=[{"position":app.board.yard_position(0,0),"token":0}]
	check(not app.move_buttons[0].disabled,"Legal pawn button is enabled")
	check(app.roll_button.disabled,"Dice is locked while a pawn is pending")
	await capture("04-choose-pawn")
	var click := InputEventMouseButton.new()
	click.button_index=MOUSE_BUTTON_LEFT
	click.pressed=true
	click.position=app.board.yard_position(0,0)
	app.board._gui_input(click)
	await settle()
	check(app.game.tokens[0][0]==0,"Tapping the board moves the chosen pawn")
	check(app.game.current==0,"Six keeps the same player's turn")
	# Save during a pending roll, leave, then resume the same die.
	app.game.roll(3)
	app._save_match()
	app.show_pause()
	await settle()
	check(app.modal,"Pause blocks further play")
	var before: Dictionary=app.game.to_dict()
	app._roll()
	check(before==app.game.to_dict(),"Modal blocks dice input")
	app.show_home()
	app._resume()
	await settle()
	check(app.game.awaiting_move and app.game.die==3,"Resume keeps the rolled die")
	app.move_buttons[0].pressed.emit()
	await settle()
	check(app.game.tokens[0][0]==3,"Numbered button moves the restored pawn")
	app.show_settings()
	await settle()
	await capture("05-settings")
	app._close_modal()
	app.show_rules()
	await settle()
	await capture("06-rules")
	app._close_modal()
	app.show_credits()
	await settle()
	check(app.modal,"Credits and bundled license texts open")
	app._close_modal()
	# Exercise the real CPU scheduler and the animated path.
	app.game.current=1
	app.game.awaiting_move=false
	app.game.tokens[1][0]=4
	app.game.players[1].cpu=true
	app.settings.motion=true
	app.game.roll(2)
	app.ai_delay=0.01
	app._update_game()
	await create_timer(1.0).timeout
	check(app.game.tokens[1][0]==6,"CPU scheduler chooses and animates a legal move")
	check(not app.busy,"Pawn animation unlocks the UI")
	# Finish and ensure save is cleared and statistics are written.
	app.settings.motion=false
	app.game.current=0
	app.game.awaiting_move=false
	app.game.tokens[0]=[56,56,56,55]
	app.game.roll(1)
	app._update_game()
	app._select_token(3)
	await settle()
	check(app.game.winner==0 and app.modal,"Winning move opens victory screen")
	check(LaneStorage.load_game()==null,"Completed game is not resumable")
	check(app.settings.matches>0,"Completed match updates local stats")
	await capture("07-victory")
	app.show_home()
	app.queue_free()
	await settle()
	print("UI: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
