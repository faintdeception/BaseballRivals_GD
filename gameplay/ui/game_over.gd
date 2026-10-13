extends CanvasLayer

@onready var result_label: Label = $CenterContainer/VBoxContainer/ResultLabel
@onready var play_again_button: Button = $CenterContainer/VBoxContainer/PlayAgainButton


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	play_again_button.pressed.connect(_on_play_again_pressed)
	update_result_text()


func update_result_text() -> void:
	if result_label != null:
		result_label.text = GameState.get_game_over_text()


func set_result_text(text: String) -> void:
	if result_label != null:
		result_label.text = text


func _on_play_again_pressed() -> void:
	GameState.reset()
	var error := get_tree().change_scene_to_file("res://gameplay/gameplay.tscn")
	if error != OK:
		push_error("Failed to load gameplay scene: %s" % error)
