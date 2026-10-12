extends CanvasLayer

@onready var outs_label: Label = $HBoxContainer/OutsLabel if has_node("HBoxContainer/OutsLabel") else $OutsLabel
@onready var score_label: Label = $HBoxContainer/ScoreLabel if has_node("HBoxContainer/ScoreLabel") else $ScoreLabel


func _ready() -> void:
	GameState.bases_changed.connect(_refresh)
	GameState.outs_changed.connect(_on_outs_changed)
	_refresh()


func _on_outs_changed(_new_outs: int) -> void:
	_refresh()


func _refresh() -> void:
	if outs_label:
		outs_label.text = "Outs: %d" % GameState.outs
	if score_label:
		score_label.text = "Score: %d" % GameState.score
