extends CanvasLayer


func _ready() -> void:
	var delay := 0.2 if GameState.fast_mode else 1.0
	await get_tree().create_timer(delay).timeout
	get_tree().change_scene_to_file("res://gameplay/gameplay.tscn")

