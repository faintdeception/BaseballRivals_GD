extends Node

enum CameraState { BATTER_CAM, FIELDING_CAM }

@export var baseball: RigidBody3D
@export var pitcher: Node
@export var batter_cam: Camera3D
@export var fielding_cam: Camera3D

@export var min_travel_distance: float = 5.0
@export var min_landing_distance: float = 8.0
@export var ground_y: float = 0.0

@export_group("Fielding Follow")
## Horizontal distance the camera trails behind the ball, toward home plate.
@export var follow_distance: float = 12.0
## Base camera height above the ball.
@export var height_offset: float = 4.0
## Extra camera height per meter of ball height.
@export var height_scale: float = 0.6
## Higher = snappier follow, lower = more lag/drag.
@export var smooth_speed: float = 3.0
## Camera never gets closer than this to the ball.
@export var min_distance: float = 6.0
## Camera never gets farther than this from home plate.
@export var max_distance_from_home: float = 60.0
@export var home_position: Vector3 = Vector3.ZERO
## Look at the ball's ground shadow while it falls (ball while rising).
@export var shadow_look_enabled: bool = true
## How fast the look-at target blends between ball and shadow. Higher = snappier.
@export var shadow_transition_speed: float = 4.0
## Print state/ball/camera/target positions at ~10 Hz.
@export var debug_log: bool = false

var state: CameraState = CameraState.BATTER_CAM
var _default_pos: Vector3
var _default_look: Vector3
var _look_target: Vector3
var _log_accum: float = 0.0
# 0 = look at ball, 1 = look at ball's shadow.
var _shadow_blend: float = 0.0


func _ready() -> void:
	if fielding_cam:
		_default_pos = fielding_cam.global_position
		_default_look = _default_pos - fielding_cam.global_transform.basis.z * 30.0
		_look_target = _default_look
	if pitcher:
		pitcher.ball_pitched.connect(_on_ball_pitched)
	_set_state(CameraState.BATTER_CAM)


func _on_ball_pitched(_ball: RigidBody3D) -> void:
	_set_state(CameraState.BATTER_CAM)


func _physics_process(_delta: float) -> void:
	if baseball == null:
		return
	if GameState.play_state == GameState.PlayState.DEAD:
		if state != CameraState.BATTER_CAM:
			_set_state(CameraState.BATTER_CAM)
		return
	if baseball.freeze:
		return
	if state == CameraState.FIELDING_CAM:
		return

	var pos := baseball.global_position
	if Vector2(pos.x, pos.z).length() < min_travel_distance:
		return
	var landing := Ballistics.predict_landing(pos, baseball.linear_velocity,
			Ballistics.gravity_for(baseball), ground_y)
	if landing.z < 0.0:
		return
	if Vector2(landing.x, landing.z).length() > min_landing_distance:
		_set_state(CameraState.FIELDING_CAM)


func _process(delta: float) -> void:
	if fielding_cam == null or baseball == null:
		return
	var want_shadow := shadow_look_enabled and baseball.linear_velocity.y < 0.0
	_shadow_blend = lerpf(_shadow_blend, 1.0 if want_shadow else 0.0,
			1.0 - exp(-shadow_transition_speed * delta))
	var target := _compute_target()
	var target_pos: Vector3 = target[0]
	var target_look: Vector3 = target[1]

	# Frame-rate independent exponential smoothing.
	var t := 1.0 - exp(-smooth_speed * delta)
	fielding_cam.global_position = fielding_cam.global_position.lerp(target_pos, t)
	_look_target = _look_target.lerp(target_look, t)
	_apply_look()

	if debug_log:
		_log_accum += delta
		if _log_accum >= 0.1:
			_log_accum = 0.0
			print("[CamDirector] state=%s ball=%s cam=%s target=%s" % [
				CameraState.keys()[state], baseball.global_position,
				fielding_cam.global_position, target_pos])


# Returns [camera position, look-at point] for the current state.
func _compute_target() -> Array:
	if not (state == CameraState.FIELDING_CAM and not baseball.freeze):
		return [_default_pos, _default_look]
	var ball := baseball.global_position
	var back := home_position - ball
	back.y = 0.0
	back = back.normalized() if back.length() > 0.01 else Vector3(0, 0, -1)
	var height := height_offset + height_scale * maxf(ball.y - ground_y, 0.0)
	var target_pos := ball + back * follow_distance + Vector3.UP * height
	# Keep min_distance from the ball first, then enforce the home-plate leash.
	var from_ball := target_pos - ball
	if from_ball.length() < min_distance:
		target_pos = ball + from_ball.normalized() * min_distance
	var from_home := target_pos - home_position
	if from_home.length() > max_distance_from_home:
		target_pos = home_position + from_home.normalized() * max_distance_from_home
	var shadow := Vector3(ball.x, ground_y, ball.z)
	return [target_pos, ball.lerp(shadow, _shadow_blend)]


func _apply_look() -> void:
	if not fielding_cam.global_position.is_equal_approx(_look_target):
		fielding_cam.look_at(_look_target, Vector3.UP)


func _set_state(new_state: CameraState) -> void:
	state = new_state
	_shadow_blend = 0.0
	if state == CameraState.FIELDING_CAM and fielding_cam and baseball:
		# Snap into place so the cut doesn't show the camera lerping in.
		var target := _compute_target()
		fielding_cam.global_position = target[0]
		_look_target = target[1]
		_apply_look()
	var cam := batter_cam if state == CameraState.BATTER_CAM else fielding_cam
	if cam:
		cam.current = true
