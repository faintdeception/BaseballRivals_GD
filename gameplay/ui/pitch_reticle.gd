extends Control

@export var pitcher: Node3D
@export var batter_cam: Camera3D
@export var radius: float = 10.0
@export var color: Color = Color(1, 0.25, 0.2, 0.95)
@export var line_width: float = 2.0


func _process(_delta: float) -> void:
	var show_it := pitcher != null and batter_cam != null and batter_cam.current \
			and not batter_cam.is_position_behind(pitcher.target_point)
	visible = show_it
	if show_it:
		position = batter_cam.unproject_position(pitcher.target_point)


func _draw() -> void:
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, color, line_width, true)
	draw_line(Vector2(-radius * 1.5, 0), Vector2(-radius * 0.5, 0), color, line_width)
	draw_line(Vector2(radius * 0.5, 0), Vector2(radius * 1.5, 0), color, line_width)
	draw_line(Vector2(0, -radius * 1.5), Vector2(0, -radius * 0.5), color, line_width)
	draw_line(Vector2(0, radius * 0.5), Vector2(0, radius * 1.5), color, line_width)
