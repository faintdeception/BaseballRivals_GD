extends Node

@export var baseball: RigidBody3D
@export var launch_position: Vector3 = Vector3(0, 0.8, 0)

@export_group("Dribbler (1)")
@export var dribbler_speed: float = 15.0
@export var dribbler_angle: float = -5.0

@export_group("Line Drive (2)")
@export var line_drive_speed: float = 35.0
@export var line_drive_angle: float = 12.0

@export_group("Fly Ball (3)")
@export var fly_ball_speed: float = 35.0
@export var fly_ball_angle: float = 35.0

@export_group("Home Run (4)")
@export var home_run_speed: float = 45.0
@export var home_run_angle: float = 28.0


func _unhandled_input(event: InputEvent) -> void:
	if GameState.is_game_over:
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.physical_keycode:
		KEY_1: _hit(dribbler_speed, dribbler_angle)
		KEY_2: _hit(line_drive_speed, line_drive_angle)
		KEY_3: _hit(fly_ball_speed, fly_ball_angle)
		KEY_4: _hit(home_run_speed, home_run_angle)


func _hit(speed: float, angle_deg: float) -> void:
	if baseball == null:
		push_warning("DebugHit: baseball not assigned")
		return
	var a := deg_to_rad(angle_deg)
	baseball.reset_to(launch_position)
	# The freeze only takes effect on the physics server after a physics frame,
	# and until then the server overwrites the teleport. Wait, then re-place
	# the (now frozen) ball before launching.
	await get_tree().physics_frame
	baseball.reset_to(launch_position)
	await get_tree().physics_frame
	baseball.launch(Vector3(0, speed * sin(a), speed * cos(a)))
	baseball.sleeping = false
	EventBus.ball_hit.emit(baseball)
	# for i in 4:
	# 	await get_tree().create_timer(0.25).timeout
	# 	print("t=", (i + 1) * 0.25, " pos=", baseball.global_position)
