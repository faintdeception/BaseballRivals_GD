extends RigidBody3D

## Becomes true once the ball touches the ground after being reset; a fielder
## can only record an out on a ball that has not.
var has_touched_ground: bool = false
## Ball center at or below this height counts as touching the ground (radius is 0.074).
@export var ground_touch_height: float = 0.2


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _physics_process(_delta):
	if not freeze and global_position.y <= ground_touch_height:
		has_touched_ground = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func reset_to(pos: Vector3):
	freeze = true
	global_position = pos
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	visible = true
	has_touched_ground = false


func launch(velocity: Vector3):
	freeze = false
	linear_velocity = velocity
