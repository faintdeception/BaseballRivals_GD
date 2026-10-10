extends Node

## Signals bat contact; listeners predict where the ball goes.
signal ball_hit(ball: RigidBody3D)
## A fielder took the ball in flight (an out).
signal ball_caught(fielder: Node3D, ball: RigidBody3D)
