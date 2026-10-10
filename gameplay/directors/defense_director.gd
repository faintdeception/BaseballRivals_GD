extends Node

## Picks which fielder the player controls when a ball is put in play.

@export var ground_y: float = 0.0


func _ready() -> void:
	EventBus.ball_hit.connect(_on_ball_hit)


func _on_ball_hit(ball: RigidBody3D) -> void:
	var landing := Ballistics.predict_landing(ball.global_position, ball.linear_velocity,
			Ballistics.gravity_for(ball), ground_y)
	var best: Fielder = null
	var best_dist := INF
	for f: Fielder in get_tree().get_nodes_in_group("fielders"):
		var d := f.global_position.distance_squared_to(landing)
		if d < best_dist:
			best_dist = d
			best = f
	for f: Fielder in get_tree().get_nodes_in_group("fielders"):
		f.is_player_controlled = (f == best)
