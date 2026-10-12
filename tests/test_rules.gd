extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	test_start_and_roll()
	test_movement()
	test_capture_and_safe()
	test_turns()
	test_finish()
	test_save()
	test_path()
	test_full_matches()
	print("RULES: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

func check(condition: bool, message: String) -> void:
	checks+=1
	if not condition:
		failures+=1
		push_error(message)

func fresh(quick: bool=false, count: int=2) -> LudoGame:
	var seats: Array=[]
	for i in count:
		seats.append({"name":"Player %d" % (i+1),"color":i,"cpu":true})
	var game := LudoGame.new()
	game.setup(seats,quick)
	game.rng.seed=42
	return game

func test_start_and_roll() -> void:
	var g := fresh()
	check(g.tokens==[[-1,-1,-1,-1],[-1,-1,-1,-1]],"Classic begins with all pawns in the yard")
	check(not g.move_token(0).ok,"Cannot move before rolling")
	check(not g.roll(7).ok,"Invalid forced die is rejected")
	var r := g.roll(4)
	check(r.reason=="no_moves" and g.current==1,"Non-six passes the turn from a full yard")
	g.roll(6)
	check(g.legal_moves()==[0,1,2,3],"Six releases any pawn")
	check(not g.roll(6).ok,"Pending roll cannot be overwritten")
	check(not g.move_token(4).ok,"Invalid token cannot move")
	g.move_token(0)
	check(g.tokens[1][0]==0 and g.current==1,"A pawn enters at start without moving six extra spaces")
	g.roll(2)
	g.move_token(0)
	check(g.tokens[1][0]==2 and g.current==0,"A regular move advances and passes the turn")
	var q := fresh(true)
	check(q.tokens==[[0,-1],[0,-1]],"Quick starts two pawns with one on the board")

func test_movement() -> void:
	var g := fresh()
	g.tokens[0]=[50,51,55,56]
	g.roll(6)
	check(g.legal_moves()==[0],"Overshoots and finished pawns are excluded")
	g.move_token(0)
	check(g.tokens[0][0]==56,"Exact roll from track to finish")
	g.roll(1)
	check(g.legal_moves()==[1,2],"Home lane moves require exact distance")
	g.move_token(2)
	check(g.tokens[0][2]==56 and g.current==0,"Finishing grants an extra turn")

func test_capture_and_safe() -> void:
	var g := fresh()
	g.tokens[0][0]=12
	g.tokens[1][0]=2
	g.tokens[1][1]=2
	g.roll(3)
	var r := g.move_token(0)
	check(r.captured.size()==2,"Every rival sharing a non-safe square is captured")
	check(g.tokens[1][0]==-1 and g.tokens[1][1]==-1,"Captured pawns return to the yard")
	check(g.current==0,"Capture grants another roll")
	g=fresh()
	g.tokens[0][0]=11
	g.tokens[1][0]=0
	g.roll(2)
	r=g.move_token(0)
	check(r.captured.is_empty() and g.tokens[1][0]==0,"Start star is safe")
	g=fresh()
	g.tokens[0][0]=18
	g.tokens[1][0]=8
	g.roll(3)
	r=g.move_token(0)
	check(r.captured.is_empty(),"Neutral star is safe")
	g=fresh()
	g.tokens[0][0]=51
	g.tokens[1][0]=39
	g.roll(1)
	r=g.move_token(0)
	check(r.captured.is_empty(),"Home lanes are private")

func test_turns() -> void:
	var g := fresh()
	g.roll(6)
	g.move_token(0)
	g.roll(6)
	g.move_token(0)
	var r := g.roll(6)
	check(r.reason=="three_sixes" and g.current==1,"Third consecutive six forfeits its roll")
	check(g.tokens[0][0]==6,"First two sixes are not rolled back")
	check(not g.awaiting_move and g.consecutive_sixes==0,"Forfeit clears pending movement and streak")
	g.roll(6)
	g.move_token(0)
	g.roll(1)
	g.move_token(0)
	check(g.current==0 and g.consecutive_sixes==0,"Non-six resets the streak")
	var four := fresh(false,4)
	for i in 4:
		check(four.current==i,"Turns visit each active seat")
		four.roll(1)
	check(four.current==0,"Turn order wraps")

func test_finish() -> void:
	var g := fresh()
	g.tokens[0]=[56,56,56,55]
	g.roll(1)
	var r := g.move_token(3)
	check(r.winner==0 and g.winner==0,"All four home wins classic")
	check(not g.roll().ok and not g.move_token(3).ok,"Won games reject further input")
	var q := fresh(true)
	q.tokens[0]=[56,55]
	q.roll(1)
	q.move_token(1)
	check(q.winner==0,"Both pawns home wins quick")

func test_save() -> void:
	var g := fresh()
	g.roll(6)
	var data: Variant=JSON.parse_string(JSON.stringify(g.to_dict()))
	var restored := LudoGame.new()
	check(restored.restore(data),"JSON save restores")
	check(restored.awaiting_move and restored.die==6 and restored.legal_moves()==[0,1,2,3],"Pending die survives resume without reroll")
	restored.move_token(2)
	check(restored.tokens[0][2]==0,"Restored match is playable")
	var baseline := restored.to_dict()
	for bad in [null,{},[],{"version":99}]:
		check(not restored.restore(bad),"Invalid save rejected")
		check(restored.to_dict()==baseline,"Invalid save leaves current game unchanged")
	for key in ["current","die","winner","consecutive_sixes","turn_count"]:
		var bad: Dictionary=data.duplicate(true)
		bad[key]=1.5
		check(not restored.restore(bad),"Fractional state field rejected: "+key)
	var bad: Dictionary=data.duplicate(true)
	bad.players[1].color=bad.players[0].color
	check(not restored.restore(bad),"Duplicate colors rejected")
	bad=data.duplicate(true)
	bad.tokens[0][0]=999
	check(not restored.restore(bad),"Out-of-range pawn rejected")
	bad=data.duplicate(true)
	bad.winner=0
	check(not restored.restore(bad),"False winner rejected")

func test_path() -> void:
	check(LudoGame.PATH.size()==52,"Track has 52 cells")
	var unique: Dictionary={}
	for cell in LudoGame.PATH: unique[cell]=true
	check(unique.size()==52,"Track does not duplicate cells")
	var g := fresh(false,4)
	for color in 4:
		check(g.global_cell(color,0)==color*13,"Each color has its own starting square")
		check(LudoGame.SAFE.has(g.global_cell(color,0)),"Every starting square is safe")

func test_full_matches() -> void:
	# Complete seeded games expose turn deadlocks and model/AI integration failures.
	for seed_value in 64:
		var g := fresh(seed_value%2==0,2+seed_value%3)
		g.rng.seed=seed_value+1701
		var iterations := 0
		while g.winner<0 and iterations<20000:
			iterations+=1
			if g.awaiting_move:
				var move := g.choose_cpu_move()
				if not g.legal_moves().has(move):
					check(false,"CPU must select a legal move")
					break
				g.move_token(move)
			else:
				g.roll()
			# Exercise restart from JSON repeatedly during real matches.
			if iterations%29==0:
				var snapshot: Variant=JSON.parse_string(JSON.stringify(g.to_dict()))
				check(g.restore(snapshot),"Simulation snapshot must restore")
		check(g.winner>=0,"Seed %d must finish without deadlock" % seed_value)
		check(g.home_count(g.winner)==g.tokens[g.winner].size(),"Winner must have every pawn home")
	print("SIMULATION: 64 complete games across 2–4 seats, Classic and Quick")
