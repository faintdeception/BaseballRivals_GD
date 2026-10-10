extends Node3D

enum State { WAITING, PITCHING, DONE }

@export var release_point: Node3D
@export var wait_time: float = 3.0
@export var pitch_speed: float = 40.0
@export var time_between_pitches: float = 2.0
# World position the pitch should cross: over the middle of home plate, mid strike zone.
@export var target_point: Vector3 = Vector3(0, 0.75, 0)
@export var baseball: RigidBody3D

signal ball_pitched(ball: RigidBody3D)

var state = State.WAITING
var timer = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	timer = wait_time
	GameState.strikeout.connect(_on_strikeout)
	baseball.reset_to(release_point.global_position)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	match state:
		State.WAITING:
			timer -= delta
			if timer <= 0.0:
				_start_pitch()
		State.PITCHING:
			pass #nothing to do yet


func _start_pitch():
	state = State.PITCHING
	# TODO: windup animation
	#var ball = ball_scene.instantiate()
	#get_tree().current_scene.add_child(ball)
	baseball.reset_to(release_point.global_position)
	baseball.launch(_aim_at_target())
	emit_signal("ball_pitched", baseball)

	# Get ready for the next pitch first, because a strikeout below sets DONE.
	timer = time_between_pitches
	state = State.WAITING

	# TODO: every pitch is a strike for now. Once the strike zone/umpire exists,
	# it should call GameState.record_strike() or record_ball() instead of the pitcher.
	GameState.record_strike()


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
