class_name Fielder
extends CharacterBody3D

signal ball_caught(fielder: Fielder, ball: RigidBody3D)
## Ball taken in flight (before it reaches the ground) - this is an out.
## Ball picked up off the ground - play stays live, no out.
signal ball_fielded(fielder: Fielder, ball: RigidBody3D)
signal ball_thrown(fielder: Fielder, ball: RigidBody3D, target: Node3D)

@export var move_speed: float = 8.0
@export var is_player_controlled: bool = false
## Playable area; the fielder's x/z are clamped to it (y is ignored).
@export var field_bounds: AABB = AABB(Vector3(-100, 0, -20), Vector3(200, 10, 160))
## World direction treated as "up" on the stick/WASD. Default is away from home plate,
## matching the fielding camera that trails behind the ball.
@export var control_forward: Vector3 = Vector3.BACK

@export_group("Debug")
@export var debug_logging: bool = true
## Only log catch checks when the ball is within this distance of the fielder.
@export var debug_log_range: float = 15.0
@export var debug_log_interval: float = 0.2

@export_group("Ball")
@export var baseball: RigidBody3D
@export var catch_radius: float = 1.5
## Balls at or below this height count as ground balls and can be fielded even if vy >= 0.
@export var ground_ball_max_height: float = 0.5
@export var hold_height: float = 1.2
## Height of the body center above the feet; catch distance is measured from here.
@export var body_center_height: float = 0.9
## Seconds after a throw before this fielder can catch again.
@export var recatch_cooldown: float = 0.5

@export_group("Throw")
@export var throw_speed: float = 30.0
@export var throw_arc_degrees: float = 10.0
## Candidates for the cutoff man. The one nearest this fielder is chosen.
@export var throw_targets: Array[Node3D] = []
## Debug alternative to holding LB on a controller.
@export var throw_modifier_key: Key = KEY_SHIFT
@export var throw_key: Key = KEY_SPACE
## Base targets for Space (Home) and keys 1-4. Unset ones fall back to the sibling
## fielder with the matching name (FirstBase, SecondBase, ThirdBase, Catcher for home).
@export var first_base: Node3D
@export var second_base: Node3D
@export var third_base: Node3D
@export var home_plate: Node3D

var has_ball: bool = false
var _cooldown: float = 0.0
var _log_timer: float = 0.0


## Throttled so physics-frame checks don't flood the output. Pass force to bypass.
func _log(msg: String, force: bool = false) -> void:
	if not debug_logging or (_log_timer > 0.0 and not force):
		return
	if not force and baseball != null and baseball.global_position.distance_to(global_position) > debug_log_range:
		return
	_log_timer = debug_log_interval
	print("[Fielder %s] %s" % [name, msg])

func _ready() -> void:
	add_to_group("fielders")


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	_log_timer = maxf(_log_timer - delta, 0.0)
	_move()
	if has_ball:
		baseball.global_position = global_position + Vector3.UP * hold_height
	else:
		_try_catch()


func _unhandled_input(event: InputEvent) -> void:
	if not (is_player_controlled and has_ball):
		return
	var target: Node3D = null
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_1: target = _base_target(first_base, "FirstBase")
			KEY_2: target = _base_target(second_base, "SecondBase")
			KEY_3: target = _base_target(third_base, "ThirdBase")
			KEY_4: target = _base_target(home_plate, "Catcher")
			throw_key:
				if Input.is_physical_key_pressed(throw_modifier_key):
					throw_ball()
					return
				target = _base_target(home_plate, "Catcher")
	elif event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A:
		if Input.is_joy_button_pressed(event.device, JOY_BUTTON_LEFT_SHOULDER):
			throw_ball()
			return
		target = _base_target(home_plate, "Catcher")
	if target != null:
		throw_ball(target)


func _move() -> void:
	var input := Vector2.ZERO
	if is_player_controlled:
		input.x = _axis(KEY_D, KEY_RIGHT, KEY_A, KEY_LEFT)
		input.y = _axis(KEY_W, KEY_UP, KEY_S, KEY_DOWN)
		input = input.limit_length(1.0)
	var forward := Vector3(control_forward.x, 0.0, control_forward.z).normalized()
	var right := forward.cross(Vector3.UP)
	velocity = (right * input.x + forward * input.y) * move_speed
	move_and_slide()

	var p := global_position
	p.x = clampf(p.x, field_bounds.position.x, field_bounds.end.x)
	p.z = clampf(p.z, field_bounds.position.z, field_bounds.end.z)
	global_position = p


func _axis(pos_a: Key, pos_b: Key, neg_a: Key, neg_b: Key) -> float:
	var pos := Input.is_physical_key_pressed(pos_a) or Input.is_physical_key_pressed(pos_b)
	var neg := Input.is_physical_key_pressed(neg_a) or Input.is_physical_key_pressed(neg_b)
	return float(pos) - float(neg)


func _try_catch() -> void:
	if baseball == null:
		_log("no baseball assigned", true)
		return
	if baseball.get("in_play") != true:
		return
	if _cooldown > 0.0:
		_log("rejected: recatch cooldown %.2fs left" % _cooldown)
		return
	if baseball.freeze:
		_log("rejected: ball is frozen")
		return
	var center := global_position + Vector3.UP * body_center_height
	var dist := baseball.global_position.distance_to(center)
	var vy := baseball.linear_velocity.y
	var summary := "dist=%.2f (radius %.2f) vy=%.2f ball=%s center=%s" % [dist, catch_radius, vy, baseball.global_position, center]
	var on_ground: bool = baseball.get("has_touched_ground") == true or baseball.global_position.y <= ground_ball_max_height
	if vy >= 0.0 and not on_ground:
		_log("rejected: ball rising and not a ground ball; " + summary)
		return
	if dist > catch_radius:
		_log("rejected: out of range; " + summary)
		return
	_log(("FIELDED (ground ball); " if on_ground else "CAUGHT (in flight); ") + summary, true)
	has_ball = true
	for f: Fielder in get_tree().get_nodes_in_group("fielders"):
		f.is_player_controlled = (f == self)
	baseball.freeze = true
	baseball.linear_velocity = Vector3.ZERO
	baseball.global_position = global_position + Vector3.UP * hold_height
	# Only a fly catch is an out; a fielded grounder leaves the play live.
	if on_ground:
		ball_fielded.emit(self, baseball)
	else:
		ball_caught.emit(self, baseball)
		EventBus.ball_caught.emit(self, baseball)


func throw_ball(target: Node3D = null) -> void:
	if target == null:
		target = _nearest_target()
	if not has_ball or target == null or target == self:
		return
	var flat := target.global_position - global_position
	flat.y = 0.0
	if flat.is_zero_approx():
		return
	flat = flat.normalized()
	var axis := flat.cross(Vector3.UP).normalized()
	var direction := flat.rotated(axis, -deg_to_rad(throw_arc_degrees))
	has_ball = false
	_cooldown = recatch_cooldown
	baseball.freeze = false
	baseball.launch(direction * throw_speed)
	baseball.sleeping = false
	ball_thrown.emit(self, baseball, target)


func _nearest_target() -> Node3D:
	var best: Node3D = null
	var best_dist := INF
	for t in throw_targets:
		if t == null:
			continue
		var d := global_position.distance_squared_to(t.global_position)
		if d < best_dist:
			best_dist = d
			best = t
	return best


func _base_target(exported: Node3D, sibling_name: String) -> Node3D:
	if exported != null:
		return exported
	var parent := get_parent()
	return parent.get_node_or_null(sibling_name) as Node3D if parent != null else null
