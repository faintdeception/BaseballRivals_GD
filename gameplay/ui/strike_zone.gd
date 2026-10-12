extends Control

@export var batter_cam: Camera3D
@export var batter: Node3D
@export var fill_color: Color = Color(1, 1, 1, 0.15)
@export var outline_color: Color = Color(1, 1, 1, 0.9)
@export var outline_width: float = 2.0

var _rect := Rect2()
var _visible_zone := false


func _process(_delta: float) -> void:
	_visible_zone = _update_rect()
	queue_redraw()


# Projects the zone's 8 corners and stores their screen-space bounds. False if it can't be shown.
func _update_rect() -> bool:
	if batter_cam == null or batter == null or not batter_cam.current or batter.data == null:
		return false
	var box: AABB = batter.get_strike_zone()
	var min_p := Vector2(INF, INF)
	var max_p := Vector2(-INF, -INF)
	for i in 8:
		var corner := box.get_endpoint(i)
		if batter_cam.is_position_behind(corner):
			return false
		var s := batter_cam.unproject_position(corner)
		min_p = Vector2(minf(min_p.x, s.x), minf(min_p.y, s.y))
		max_p = Vector2(maxf(max_p.x, s.x), maxf(max_p.y, s.y))
	_rect = Rect2(min_p, max_p - min_p)
	return true


func _draw() -> void:
	if not _visible_zone:
		return
	draw_rect(_rect, fill_color, true)
	draw_rect(_rect, outline_color, false, outline_width)
