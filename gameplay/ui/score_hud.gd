extends CanvasLayer

@onready var team_label: Label = $PanelContainer/HBoxContainer/TeamLabel
@onready var score_label: Label = $PanelContainer/HBoxContainer/ScoreLabel
@onready var inning_label: Label = $PanelContainer/HBoxContainer/InningLabel
@onready var balls_label: Label = $PanelContainer/HBoxContainer/BallsLabel
@onready var strikes_label: Label = $PanelContainer/HBoxContainer/StrikesLabel
@onready var outs_label: Label = $PanelContainer/HBoxContainer/OutsLabel


func _ready() -> void:
	GameState.balls_changed.connect(_on_count_changed)
	GameState.strikes_changed.connect(_on_count_changed)
	GameState.bases_changed.connect(_refresh)
	GameState.outs_changed.connect(_on_count_changed)
	GameState.inning_changed.connect(_on_count_changed)
	GameState.batting_team_changed.connect(_refresh)
	_refresh()


func _on_count_changed(_new_value: int) -> void:
	_refresh()


func _refresh() -> void:
	team_label.text = GameState.current_team_name()
	score_label.text = str(GameState.current_team_score())
	inning_label.text = "INN:%d" % GameState.inning
	balls_label.text = "B:%d" % GameState.balls
	strikes_label.text = "S:%d" % GameState.strikes
	outs_label.text = "O:%d" % GameState.outs
