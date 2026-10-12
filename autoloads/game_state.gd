extends Node

signal count_changed(balls: int, strikes: int)
signal strikeout
signal play_state_changed(new_state)

enum PlayState { IDLE, LIVE, DEAD }

var play_state: PlayState = PlayState.IDLE
var balls: int = 0
var strikes: int = 0
var outs: int = 0
const LINEUP_SIZE := 9

var lineup: Array[BatterData] = []
var lineup_index: int = 0


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
	_set_play_state(PlayState.IDLE)


func _set_play_state(new_state: PlayState) -> void:
	if play_state == new_state:
		return
	play_state = new_state
	play_state_changed.emit(new_state)


func _on_play_state_changed(new_state: PlayState) -> void:
	if new_state != PlayState.DEAD:
		return
	await get_tree().create_timer(1.5).timeout
	if play_state != PlayState.DEAD:
		return
	advance_batter()
	var error := get_tree().change_scene_to_file("res://gameplay/ui/transition.tscn")
	if error != OK:
		push_error("Failed to change to transition scene: %s" % error)


func _on_ball_caught(_fielder: Node3D, _ball: RigidBody3D) -> void:
	outs += 1
	print("Out ", outs)
	_set_play_state(PlayState.DEAD)


func reset_count():
	balls = 0
	strikes = 0
	count_changed.emit(balls, strikes)


func record_strike():
	strikes += 1
	print("Strike ", strikes)
	if strikes >= 3:
		_strikeout()
	else:
		count_changed.emit(balls, strikes)


func record_ball():
	balls += 1
	print("Ball ", balls)
	if balls >= 4:
		_walk()
	else:
		count_changed.emit(balls, strikes)


func advance_batter():
	advance_lineup()


func advance_lineup():
	lineup_index = (lineup_index + 1) % lineup.size()


func _strikeout():
	print("Strikeout")
	# Emit before resetting so listeners can tell the at-bat ended.
	strikeout.emit()
	reset_count()


func _walk():
	print("Walk")
	reset_count()
