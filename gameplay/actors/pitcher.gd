extends Node3D

enum State { WAITING, WINDUP, PITCHING, DONE }

@export var release_point: Node3D
@export var wait_time: float = 3.0
@export var pitch_speed: float = 40.0
@export var time_between_pitches: float = 2.0
## Delay between windup_started and the ball release.
@export var windup_time: float = 0.7
## How long before the windup the next target is revealed.
@export var reveal_lead_time: float = 1.0
# World position the pitch should cross: over the middle of home plate, mid strike zone.
@export var target_point: Vector3 = Vector3(0, 0.75, 0)
@export var baseball: RigidBody3D
@export var batter: Node3D
## Keeps pitches this far (m) inside the zone edges.
@export var target_margin: float = 0.03

signal windup_started
## The next target is chosen and shown; UI should be at full strength.
signal pitch_ready
signal ball_pitched(ball: RigidBody3D)

var state = State.WAITING
var timer = 0.0
var _target_revealed := true

# Called when the node enters the scene tree for the first time.
func _ready():
	timer = wait_time
	GameState.strikeout.connect(_on_strikeout)
	baseball.reset_to(release_point.global_position)
	# The batter's data isn't loaded until after this _ready, so pick the first target next frame.
	_pick_initial_target.call_deferred()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if GameState.play_state != GameState.PlayState.IDLE:
		return
	match state:
		State.WAITING:
			timer -= delta
			if not _target_revealed and timer <= reveal_lead_time:
				_target_revealed = true
				target_point = _pick_target()
				pitch_ready.emit()
			if timer <= 0.0:
				_start_windup()
		State.WINDUP:
			timer -= delta
			if timer <= 0.0:
				_start_pitch()
		State.PITCHING:
			pass #nothing to do yet


func _start_windup():
	if GameState.play_state != GameState.PlayState.IDLE:
		return
	state = State.WINDUP
	timer = windup_time
	windup_started.emit()


func _start_pitch():
	if GameState.play_state != GameState.PlayState.IDLE:
		return
	state = State.PITCHING
	# TODO: windup animation
	#var ball = ball_scene.instantiate()
	#get_tree().current_scene.add_child(ball)
	baseball.reset_to(release_point.global_position)
	baseball.launch(_aim_at_target())
	emit_signal("ball_pitched", baseball)

	# Get ready for the next pitch first, because a strikeout below sets DONE.
	timer = time_between_pitches
	_target_revealed = false
	state = State.WAITING
	# Strikes are now recorded by the batter (whiff); a strike zone/umpire will handle takes later.


func _on_strikeout():
	state = State.DONE


# Works out the velocity that makes the ball cross target_point, accounting for gravity.
func _aim_at_target() -> Vector3:
	var to_target = target_point - release_point.global_position
	var horizontal = Vector3(to_target.x, 0.0, to_target.z)
	var flight_time = horizontal.length() / pitch_speed
	var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

	var velocity = horizontal.normalized() * pitch_speed
	# The ball falls 0.5 * g * t^2 on the way, so aim that much higher.
	velocity.y = (to_target.y + 0.5 * gravity * flight_time * flight_time) / flight_time
	return velocity

func _pick_initial_target() -> void:
	target_point = _pick_target()


# Random point inside the batter's strike zone, kept target_margin away from the edges.
func _pick_target() -> Vector3:
	if batter == null or not batter.has_method("get_strike_zone") or batter.data == null:
		return target_point
	var zone: AABB = batter.get_strike_zone()
	var center := zone.get_center()
	var half_x := maxf(zone.size.x * 0.5 - target_margin, 0.0)
	var half_y := maxf(zone.size.y * 0.5 - target_margin, 0.0)
	return Vector3(
		center.x + randf_range(-half_x, half_x),
		center.y + randf_range(-half_y, half_y),
		center.z)
