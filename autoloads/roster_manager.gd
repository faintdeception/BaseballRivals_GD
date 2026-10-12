extends Node

# Autoloads have no scene, so the resources are assigned as export defaults rather than in the Inspector.
@export var batters: Array[BatterData] = [
	preload("res://data/batters/batter_a.tres"),
	preload("res://data/batters/batter_b.tres"),
]


func get_batter(index: int) -> BatterData:
	return batters[index % batters.size()]
