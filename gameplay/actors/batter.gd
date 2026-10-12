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


func _ready():
	_box_position = global_position
	data = RosterManager.get_batter(GameState.current_batter_index)
	if data == null:
		push_error("Batter: no BatterData for index %d" % GameState.current_batter_index)
		return
	if data.swing_trigger_z == 0.0:
		push_warning("Batter '%s' has swing_trigger_z = 0; the .tres is probably missing fields." % data.display_name)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = data.body_color
	body_mesh.material_override = mat
	pitcher.ball_pitched.connect(_on_ball_pitched)
	EventBus.ball_hit.connect(_on_ball_hit)
	EventBus.ball_caught.connect(_on_ball_caught)
	bat_pivot.rotation_degrees.y = bat_ready_angle


func _on_ball_pitched(_ball: RigidBody3D):
	has_swung = false
	if swing_tween:
		swing_tween.kill()
	bat_pivot.rotation_degrees.y = bat_ready_angle


func _on_ball_hit(ball: RigidBody3D) -> void:
	if ball != baseball or _has_started_running:
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
	if ball != baseball or not _is_running:
		return
	if run_tween:
		run_tween.kill()
	run_tween = null
	_is_running = false
	global_position = _box_position


func _on_reached_first() -> void:
	run_tween = null
	_is_running = false
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
	if has_swung or baseball.freeze or baseball.in_play:
		return
	if baseball.global_position.z <= data.swing_trigger_z:
		_swing()


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
