extends MeshInstance3D

@export var baseball: RigidBody3D
@export var fielding_cam: Camera3D

const GROUND_Y := 0.02


func _process(_delta: float) -> void:
	visible = _should_show()
	if not visible:
		return
	var landing := Ballistics.predict_landing(baseball.global_position, baseball.linear_velocity,
			Ballistics.gravity_for(baseball))
	global_position = Vector3(landing.x, GROUND_Y, landing.z)


func _should_show() -> bool:
	if baseball == null or fielding_cam == null:
		return false
	return fielding_cam.current and not baseball.freeze
