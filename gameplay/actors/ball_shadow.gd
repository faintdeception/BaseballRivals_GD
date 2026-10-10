extends MeshInstance3D

@export var baseball: RigidBody3D
@export var ground_y: float = 0.01

func _process(_delta):
	if baseball == null:
		return
	var p = baseball.global_position
	global_position = Vector3(p.x, ground_y, p.z)
