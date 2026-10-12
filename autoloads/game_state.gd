extends Node

signal count_changed(balls: int, strikes: int)
signal strikeout

var balls: int = 0
var strikes: int = 0
var outs: int = 0
var current_batter_index: int = 0


func _ready() -> void:
	EventBus.ball_caught.connect(_on_ball_caught)


func _on_ball_caught(_fielder: Node3D, _ball: RigidBody3D) -> void:
	outs += 1
	print("Out ", outs)


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
	current_batter_index += 1


func _strikeout():
	print("Strikeout")
	# Emit before resetting so listeners can tell the at-bat ended.
	strikeout.emit()
	reset_count()
	await get_tree().create_timer(1.5).timeout
	advance_batter()
	get_tree().change_scene_to_file("res://gameplay/ui/transition.tscn")


func _walk():
	print("Walk")
	reset_count()
