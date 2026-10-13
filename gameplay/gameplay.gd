extends Node3D

# Home plate:        (0, 0, 0)
# Pitcher's mound:   (0, 0, 18.44)      # straight down +Z
# Mound height:      0.254 m (10")
# Mound radius:      ~2.7 m top, ~5.5 m base (real mounds are wide and gentle)

const GAME_OVER_SCENE = preload("res://gameplay/ui/game_over.tscn")

var _game_over_instance: CanvasLayer = null


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameState.start_at_bat()
	GameState.game_over.connect(_on_game_over)
	if GameState.is_game_over:
		_show_game_over()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_game_over() -> void:
	var pitcher := get_node_or_null("Actors/Pitcher")
	if pitcher and pitcher.has_method("stop"):
		pitcher.stop()
	var batter := get_node_or_null("Actors/Batter")
	if batter and batter.has_method("disable_input"):
		batter.disable_input()
	_show_game_over()


func _show_game_over() -> void:
	if _game_over_instance == null:
		_game_over_instance = GAME_OVER_SCENE.instantiate()
		add_child(_game_over_instance)

