extends Node

signal balls_changed(new_balls: int)
signal strikes_changed(new_strikes: int)
signal strikeout
signal walk
signal play_state_changed(new_state)
signal bases_changed
signal outs_changed(new_outs: int)
signal inning_changed(inning: int, half: Half)
signal batting_team_changed
signal game_over

enum Half { TOP, BOTTOM }
enum PlayState { IDLE, LIVE, DEAD }

var play_state: PlayState = PlayState.IDLE
var balls: int = 0
var strikes: int = 0
var outs: int = 0
var inning: int = 1
var half: Half = Half.TOP
var home_team_name: String = "HOME"
var away_team_name: String = "AWAY"
var is_home_batting: bool = false
const LINEUP_SIZE := 9

var lineup: Array[BatterData] = []
var lineup_index: int = 0
var bases: Array[BatterData] = [null, null, null]
var home_score: int = 0
var away_score: int = 0

var score_home: int:
	get:
		return home_score
	set(value):
		home_score = value

var score_away: int:
	get:
		return away_score
	set(value):
		away_score = value

var is_game_over: bool = false
var fast_mode: bool = false
var _inning_reset_pending: bool = false
var _lineup_advanced: bool = false



func _ready() -> void:
	for i in LINEUP_SIZE:
		lineup.append(RosterManager.get_batter(i))
	EventBus.ball_hit.connect(_on_ball_hit)
	EventBus.ball_caught.connect(_on_ball_caught)
	strikeout.connect(_on_strikeout)
	play_state_changed.connect(_on_play_state_changed)


func _on_ball_hit(_ball: RigidBody3D) -> void:
	_set_play_state(PlayState.LIVE)


func _on_strikeout() -> void:
	_set_play_state(PlayState.DEAD)


func end_play() -> void:
	_set_play_state(PlayState.DEAD)


func start_at_bat() -> void:
	_lineup_advanced = false
	_set_play_state(PlayState.IDLE)
	if _inning_reset_pending:
		outs = 0
		_inning_reset_pending = false
		outs_changed.emit(outs)


func _set_play_state(new_state: PlayState) -> void:
	if play_state == new_state:
		return
	play_state = new_state
	play_state_changed.emit(new_state)


func _on_play_state_changed(new_state: PlayState) -> void:
	if new_state != PlayState.DEAD:
		return
	var delay := 0.2 if fast_mode else 1.5
	await get_tree().create_timer(delay).timeout
	if play_state != PlayState.DEAD:
		return
	if is_game_over:
		return
	advance_batter()
	var error := get_tree().change_scene_to_file("res://gameplay/ui/transition.tscn")
	if error != OK:
		push_error("Failed to change to transition scene: %s" % error)



func _on_ball_caught(_fielder: Node3D, _ball: RigidBody3D) -> void:
	_record_out()
	reset_count()
	_set_play_state(PlayState.DEAD)


func reset_count():
	balls = 0
	strikes = 0
	balls_changed.emit(balls)
	strikes_changed.emit(strikes)


func record_strike():
	strikes += 1
	print("Strike ", strikes)
	strikes_changed.emit(strikes)
	if strikes >= 3:
		_strikeout()


func record_ball():
	balls += 1
	print("Ball ", balls)
	balls_changed.emit(balls)
	if balls >= 4:
		_walk()


func advance_batter():
	if not _lineup_advanced:
		advance_lineup()


func advance_lineup():
	lineup_index = (lineup_index + 1) % lineup.size()
	_lineup_advanced = true


func commit_advancement(batter: BatterData) -> void:

	if batter == null:
		push_error("GameState: cannot commit advancement without BatterData")
		return

	if bases[2] != null:
		if is_home_batting:
			home_score += 1
		else:
			away_score += 1
	bases[2] = bases[1]
	bases[1] = bases[0]
	bases[0] = batter
	print("[BaseState] bases: %s %s %s score: %d" % [
		_format_base_entry(bases[0]),
		_format_base_entry(bases[1]),
		_format_base_entry(bases[2]),
		current_team_score(),
	])
	bases_changed.emit()


func current_team_name() -> String:
	return home_team_name if is_home_batting else away_team_name


func current_team_score() -> int:
	return home_score if is_home_batting else away_score


func _format_base_entry(batter: BatterData) -> String:
	if batter == null:
		return "[]"
	return "[BatterData %s]" % batter.display_name


func _strikeout():
	print("Strikeout")
	_record_out()
	# Emit before resetting so listeners can tell the at-bat ended.
	strikeout.emit()
	reset_count()


func _record_out() -> void:
	outs += 1
	print("Out ", outs)
	outs_changed.emit(outs)
	if outs == 3:
		end_half_inning()


func end_half_inning() -> void:
	print("Half-inning ended")
	bases = [null, null, null]
	bases_changed.emit()
	_inning_reset_pending = true

	if _check_game_over():
		is_game_over = true
		game_over.emit()
		return

	if half == Half.TOP:
		half = Half.BOTTOM
	else:
		half = Half.TOP
		inning += 1

	is_home_batting = (half == Half.BOTTOM)
	batting_team_changed.emit()
	inning_changed.emit(inning, half)


func _end_half_inning() -> void:
	end_half_inning()


func _check_game_over() -> bool:
	if inning < 9:
		return false
	if half == Half.TOP:
		return score_home > score_away
	else:
		return score_home != score_away  # tie → extra innings


func check_game_over() -> bool:
	return _check_game_over()


func get_game_over_text() -> String:
	if score_home > score_away:
		return "%s WINS %d-%d" % [home_team_name, score_home, score_away]
	elif score_away > score_home:
		return "%s WINS %d-%d" % [away_team_name, score_away, score_home]
	else:
		return "TIE GAME %d-%d" % [score_home, score_away]


func reset() -> void:
	play_state = PlayState.IDLE
	balls = 0
	strikes = 0
	outs = 0
	inning = 1
	half = Half.TOP
	is_home_batting = false
	lineup_index = 0
	bases = [null, null, null]
	home_score = 0
	away_score = 0
	is_game_over = false
	_inning_reset_pending = false
	_lineup_advanced = false
	balls_changed.emit(balls)
	strikes_changed.emit(strikes)
	outs_changed.emit(outs)
	bases_changed.emit()
	batting_team_changed.emit()
	inning_changed.emit(inning, half)


func _walk():
	print("Walk")
	var batter_data: BatterData = lineup[lineup_index] if lineup_index >= 0 and lineup_index < lineup.size() else null
	if batter_data != null:
		commit_advancement(batter_data)
	reset_count()
	advance_lineup()
	walk.emit()
	end_play()

