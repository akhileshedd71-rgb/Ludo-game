class_name LudoGame
extends RefCounted
## Pure game rules. No scene, input, timer or rendering dependencies.
## progress: -1 = yard, 0..50 = shared track, 51..55 = lane, 56 = home.

const FINISH := 56
const SAFE := [0, 8, 13, 21, 26, 34, 39, 47]
const COLOR_NAMES := ["Coral", "Jade", "Gold", "Blue"]
const PATH := [
	Vector2i(1,6), Vector2i(2,6), Vector2i(3,6), Vector2i(4,6), Vector2i(5,6),
	Vector2i(6,5), Vector2i(6,4), Vector2i(6,3), Vector2i(6,2), Vector2i(6,1), Vector2i(6,0),
	Vector2i(7,0), Vector2i(8,0), Vector2i(8,1), Vector2i(8,2), Vector2i(8,3), Vector2i(8,4), Vector2i(8,5),
	Vector2i(9,6), Vector2i(10,6), Vector2i(11,6), Vector2i(12,6), Vector2i(13,6), Vector2i(14,6),
	Vector2i(14,7), Vector2i(14,8), Vector2i(13,8), Vector2i(12,8), Vector2i(11,8), Vector2i(10,8), Vector2i(9,8),
	Vector2i(8,9), Vector2i(8,10), Vector2i(8,11), Vector2i(8,12), Vector2i(8,13), Vector2i(8,14),
	Vector2i(7,14), Vector2i(6,14), Vector2i(6,13), Vector2i(6,12), Vector2i(6,11), Vector2i(6,10), Vector2i(6,9),
	Vector2i(5,8), Vector2i(4,8), Vector2i(3,8), Vector2i(2,8), Vector2i(1,8), Vector2i(0,8), Vector2i(0,7), Vector2i(0,6)
]

var players: Array = []
var tokens: Array = []
var current := 0
var die := 0
var awaiting_move := false
var consecutive_sixes := 0
var winner := -1
var quick := false
var turn_count := 0
var rng := RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()

func setup(seats: Array, is_quick: bool = false) -> void:
	players = seats.duplicate(true)
	quick = is_quick
	tokens.clear()
	for _p in players:
		tokens.append([0, -1] if quick else [-1, -1, -1, -1])
	current = 0
	die = 0
	awaiting_move = false
	consecutive_sixes = 0
	winner = -1
	turn_count = 0

func global_cell(player: int, progress: int) -> int:
	return (int(players[player].color) * 13 + progress) % 52

func legal_moves() -> Array[int]:
	var legal: Array[int] = []
	if not awaiting_move or winner >= 0:
		return legal
	for i in tokens[current].size():
		var p: int = tokens[current][i]
		if (p == -1 and die == 6) or (p >= 0 and p < FINISH and p + die <= FINISH):
			legal.append(i)
	return legal

func roll(forced: int = 0) -> Dictionary:
	if awaiting_move or winner >= 0 or players.is_empty():
		return {"ok": false}
	if forced < 0 or forced > 6:
		return {"ok": false}
	die = forced if forced > 0 else rng.randi_range(1, 6)
	turn_count += 1
	var actor := current
	consecutive_sixes = consecutive_sixes + 1 if die == 6 else 0
	if consecutive_sixes == 3:
		_next_player()
		return {"ok": true, "player": actor, "die": die, "reason": "three_sixes", "moves": []}
	awaiting_move = true
	var moves := legal_moves()
	if moves.is_empty():
		awaiting_move = false
		if die != 6:
			_next_player()
	return {"ok": true, "player": actor, "die": die, "reason": "no_moves" if moves.is_empty() else "choose", "moves": moves}

func move_token(index: int) -> Dictionary:
	if not legal_moves().has(index):
		return {"ok": false}
	var actor := current
	var previous: int = tokens[actor][index]
	var target: int = 0 if previous == -1 else previous + die
	tokens[actor][index] = target
	var captured: Array = []
	if target <= 50:
		var cell := global_cell(actor, target)
		if not SAFE.has(cell):
			for other in players.size():
				if other == actor:
					continue
				for t in tokens[other].size():
					var p: int = tokens[other][t]
					if p >= 0 and p <= 50 and global_cell(other, p) == cell:
						tokens[other][t] = -1
						captured.append([other, t])
	awaiting_move = false
	var all_home := true
	for p in tokens[actor]:
		if p != FINISH:
			all_home = false
	var bonus: bool = die == 6 or not captured.is_empty() or target == FINISH
	if all_home:
		winner = actor
	elif not bonus:
		_next_player()
	return {"ok": true, "player": actor, "token": index, "from": previous, "to": target, "captured": captured, "bonus": bonus, "winner": winner}

func _next_player() -> void:
	current = (current + 1) % players.size()
	awaiting_move = false
	consecutive_sixes = 0

func choose_cpu_move() -> int:
	var best := -1
	var best_score := -INF
	for t in legal_moves():
		var p: int = tokens[current][t]
		var target: int = 0 if p == -1 else p + die
		var score := float(target) * 0.3 + rng.randf() * 3.0
		if p == -1:
			score += 18.0
		if target == FINISH:
			score += 120.0
		elif target > 50:
			score += 25.0
		else:
			var cell := global_cell(current, target)
			if SAFE.has(cell):
				score += 15.0
			else:
				for other in players.size():
					if other == current:
						continue
					for other_p in tokens[other]:
						if other_p < 0 or other_p > 50:
							continue
						var distance := posmod(cell - global_cell(other, other_p), 52)
						if distance == 0:
							score += 65.0
						elif distance <= 6:
							score -= 9.0
		if score > best_score:
			best_score = score
			best = t
	return best

func home_count(player: int) -> int:
	return tokens[player].count(FINISH)

func to_dict() -> Dictionary:
	return {"version": 1, "players": players.duplicate(true), "tokens": tokens.duplicate(true), "current": current, "die": die, "awaiting_move": awaiting_move, "consecutive_sixes": consecutive_sixes, "winner": winner, "quick": quick, "turn_count": turn_count}

func restore(data: Variant) -> bool:
	# Validate the complete payload before mutating state, including JSON number types.
	if not data is Dictionary:
		return false
	for key in ["version", "players", "tokens", "current", "die", "awaiting_move", "consecutive_sixes", "winner", "quick", "turn_count"]:
		if not data.has(key):
			return false
	for key in ["version", "current", "die", "consecutive_sixes", "winner", "turn_count"]:
		if not _integer(data[key]):
			return false
	if data.version != 1 or not data.players is Array or not data.tokens is Array or not data.quick is bool or not data.awaiting_move is bool:
		return false
	var count: int = data.players.size()
	if count < 2 or count > 4 or data.tokens.size() != count or data.current < 0 or data.current >= count or data.die < 0 or data.die > 6 or data.consecutive_sixes < 0 or data.consecutive_sixes > 2 or data.winner < -1 or data.winner >= count or data.turn_count < 0:
		return false
	var colors: Array = []
	var converted: Array = []
	for i in count:
		var seat: Variant = data.players[i]
		if not seat is Dictionary or not seat.get("name") is String or seat.name.is_empty() or seat.name.length() > 20 or not seat.get("cpu") is bool or not _integer(seat.get("color")):
			return false
		if seat.color < 0 or seat.color > 3 or colors.has(int(seat.color)):
			return false
		colors.append(int(seat.color))
		if not data.tokens[i] is Array or data.tokens[i].size() != (2 if data.quick else 4):
			return false
		var row: Array = []
		for p in data.tokens[i]:
			if not _integer(p) or p < -1 or p > FINISH:
				return false
			row.append(int(p))
		converted.append(row)
	if data.awaiting_move and (data.die == 0 or data.winner >= 0):
		return false
	for i in count:
		if (converted[i].count(FINISH) == converted[i].size()) != (int(data.winner) == i):
			return false
	if data.awaiting_move:
		var has_move := false
		for p in converted[int(data.current)]:
			if (p == -1 and data.die == 6) or (p >= 0 and p < FINISH and p + data.die <= FINISH):
				has_move = true
		if not has_move:
			return false
	players = data.players.duplicate(true)
	for seat in players:
		seat.color = int(seat.color)
	tokens = converted
	current = int(data.current)
	die = int(data.die)
	awaiting_move = data.awaiting_move
	consecutive_sixes = int(data.consecutive_sixes)
	winner = int(data.winner)
	quick = data.quick
	turn_count = int(data.turn_count)
	return true

func _integer(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value))
