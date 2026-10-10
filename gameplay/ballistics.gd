class_name Ballistics
extends RefCounted

## Ballistic landing point on the plane y = ground_y. Ignores spin/Magnus, drag and bounce.
## `gravity` is the effective downward acceleration (positive), e.g. default_gravity * gravity_scale.
static func predict_landing(pos: Vector3, vel: Vector3, gravity: float, ground_y: float = 0.0) -> Vector3:
	var height := maxf(pos.y - ground_y, 0.0)
	var disc := vel.y * vel.y + 2.0 * gravity * height
	var t := 0.0
	if gravity > 0.0 and disc >= 0.0:
		t = (vel.y + sqrt(disc)) / gravity
	return Vector3(pos.x + vel.x * t, ground_y, pos.z + vel.z * t)


## Effective gravity for a RigidBody3D.
static func gravity_for(body: RigidBody3D) -> float:
	return ProjectSettings.get_setting("physics/3d/default_gravity") * body.gravity_scale
