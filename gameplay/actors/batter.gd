extends Node3D

@export var baseball: RigidBody3D
@export var pitcher: Node3D
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
var data: BatterData


func _ready():
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
	bat_pivot.rotation_degrees.y = bat_ready_angle


func _on_ball_pitched(_ball: RigidBody3D):
	has_swung = false
	if swing_tween:
		swing_tween.kill()
	bat_pivot.rotation_degrees.y = bat_ready_angle


func _animate_swing():
	if swing_tween:
		swing_tween.kill()
	swing_tween = create_tween()
	swing_tween.tween_property(bat_pivot, "rotation_degrees:y", bat_end_angle, swing_duration)


func _physics_process(_delta):
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
