extends Node3D

@export var baseball: RigidBody3D
@export var pitcher: Node3D
## Pitches travel toward -Z, so the swing fires when the ball's Z drops to this value.
@export var swing_trigger_z: float = 3.0
@export var swing_radius_x: float = 0.5
@export var swing_radius_y: float = 0.6
@export var contact_speed: float = 30.0
## Center of the contact box (home plate).
@export var plate_position: Vector3 = Vector3.ZERO

var has_swung: bool = false


func _ready():
	pitcher.ball_pitched.connect(_on_ball_pitched)


func _on_ball_pitched(_ball: RigidBody3D):
	has_swung = false


func _physics_process(_delta):
	if has_swung or baseball.freeze or baseball.in_play:
		return
	if baseball.global_position.z <= swing_trigger_z:
		_swing()


func _swing():
	has_swung = true
	var offset = baseball.global_position - plate_position
	if absf(offset.x) < swing_radius_x and offset.y >= 0.0 and offset.y <= swing_radius_y:
		baseball.launch(Vector3(0, 0.2, 1) * contact_speed)
		EventBus.ball_hit.emit(baseball)
	else:
		GameState.record_strike()
