extends Node3D

signal reached_first

@export var baseball: RigidBody3D
@export var pitcher: Node3D
@export var run_speed_mps: float = 6.5
@export var first_base_target: Node3D
## Center of the contact box (home plate).
@export var plate_position: Vector3 = Vector3.ZERO

## Bat yaw in degrees: cocked back toward the catcher, then swung through the plate toward the pitcher.
@export var bat_ready_angle: float = 90.0
@export var bat_end_angle: float = -70.0
@export var swing_duration: float = 0.15

@onready var bat_pivot: Node3D = $BatPivot
@onready var body_mesh: MeshInstance3D = $MeshInstance3D

var has_swung: bool = false
var swing_tween: Tween
var run_tween: Tween
var data: BatterData
var _box_position: Vector3
var _is_running: bool = false
var _has_started_running: bool = false
var _prev_ball_pos: Vector3 = Vector3.ZERO
var _pitch_in_flight: bool = false
var _swing_evaluated: bool = false
var _plate_evaluated: bool = false


func _ready():
	_box_position = global_position
	data = GameState.lineup[GameState.lineup_index]
	if data == null:
		push_error("Batter: no BatterData for lineup index %d" % GameState.lineup_index)
		return
	if data.swing_trigger_z == 0.0:
		push_warning("Batter '%s' has swing_trigger_z = 0; the .tres is probably missing fields." % data.display_name)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = data.body_color
	body_mesh.material_override = mat
	pitcher.ball_pitched.connect(_on_ball_pitched)
	EventBus.ball_hit.connect(_on_ball_hit)
	EventBus.ball_caught.connect(_on_ball_caught)
	GameState.game_over.connect(_on_game_over)
	bat_pivot.rotation_degrees.y = bat_ready_angle
	if baseball:
		_prev_ball_pos = baseball.global_position


func _on_ball_pitched(_ball: RigidBody3D):
	has_swung = false
	_pitch_in_flight = true
	_swing_evaluated = false
	_plate_evaluated = false
	if baseball:
		_prev_ball_pos = baseball.global_position
	if swing_tween:
		swing_tween.kill()
	bat_pivot.rotation_degrees.y = bat_ready_angle


func _on_ball_hit(ball: RigidBody3D) -> void:
	if ball != baseball:
		return
	_pitch_in_flight = false
	if _has_started_running:
		return
	if first_base_target == null:
		push_error("Batter: first_base_target is not assigned")
		return
	if run_speed_mps <= 0.0:
		push_error("Batter: run_speed_mps must be greater than zero")
		return

	_has_started_running = true
	_is_running = true
	var distance := global_position.distance_to(first_base_target.global_position)
	var duration := distance / run_speed_mps
	run_tween = create_tween()
	run_tween.set_trans(Tween.TRANS_LINEAR)
	run_tween.tween_property(self, "global_position",
			first_base_target.global_position, duration)
	run_tween.tween_callback(_on_reached_first)


func _on_ball_caught(_fielder: Node3D, ball: RigidBody3D) -> void:
	if ball != baseball:
		return
	_pitch_in_flight = false
	if not _is_running:
		return
	if run_tween:
		run_tween.kill()
	run_tween = null
	_is_running = false
	global_position = _box_position



func _on_reached_first() -> void:
	run_tween = null
	_is_running = false
	if data == null:
		push_error("Batter: cannot commit advancement without BatterData")
		return
	GameState.commit_advancement(data)
	body_mesh.visible = false
	bat_pivot.visible = false
	reached_first.emit()
	GameState.end_play()


func _animate_swing():
	if swing_tween:
		swing_tween.kill()
	swing_tween = create_tween()
	swing_tween.tween_property(bat_pivot, "rotation_degrees:y", bat_end_angle, swing_duration)


func _physics_process(_delta):
	if GameState.play_state != GameState.PlayState.IDLE:
		return
	if GameState.is_game_over:
		return
	if baseball == null or baseball.freeze or not _pitch_in_flight:
		return
	if data == null:
		return
	var curr_pos := baseball.global_position

	# 1. Batter swing decision at swing_trigger_z
	if not _swing_evaluated and not has_swung and not baseball.in_play:
		if curr_pos.z <= data.swing_trigger_z:
			_swing_evaluated = true
			if _should_swing():
				_swing()

	# 2. Plate crossing detection at Z=0 (plate_position.z)
	if not _plate_evaluated and not baseball.in_play:
		var target_z := plate_position.z
		if _prev_ball_pos.z > target_z and curr_pos.z <= target_z:
			_plate_evaluated = true
			_pitch_in_flight = false
			if not has_swung:
				var t := (target_z - _prev_ball_pos.z) / (curr_pos.z - _prev_ball_pos.z)
				var crossing_point := _prev_ball_pos.lerp(curr_pos, t)
				crossing_point.z = target_z
				var zone := get_strike_zone()
				if zone.has_point(crossing_point):
					GameState.record_strike()
				else:
					GameState.record_ball()

	_prev_ball_pos = curr_pos


func _should_swing() -> bool:
	if randf() > data.swing_aggression:
		return false
	if data.patient:
		var predicted_crossing := _predict_plate_crossing()
		var zone := get_strike_zone()
		if not zone.has_point(predicted_crossing):
			return false
	return true


func _predict_plate_crossing() -> Vector3:
	return Ballistics.predict_crossing_z(
		baseball.global_position,
		baseball.linear_velocity,
		Ballistics.gravity_for(baseball),
		plate_position.z
	)


func _swing():
	has_swung = true
	_animate_swing()
	var offset = baseball.global_position - plate_position
	if absf(offset.x) < data.swing_radius_x and absf(offset.y - data.contact_center_y) <= data.swing_radius_y:
		var angle := deg_to_rad(data.launch_angle_degrees)
		var dir := Vector3(0.0, sin(angle), cos(angle))
		baseball.launch(dir * data.contact_speed)
		EventBus.ball_hit.emit(baseball)
	else:
		GameState.record_strike()


## Strike zone in world space, anchored to home plate rather than the (possibly running) batter.
func get_strike_zone() -> AABB:
	if data == null:
		return AABB()
	return AABB(
		plate_position + Vector3(-data.zone_half_width, data.zone_bottom_y, -0.1),
		Vector3(data.zone_half_width * 2.0, data.zone_top_y - data.zone_bottom_y, 0.2)
	)


func _on_game_over() -> void:
	disable_input()


func disable_input() -> void:
	set_physics_process(false)
	set_process_unhandled_input(false)
	set_process_input(false)


