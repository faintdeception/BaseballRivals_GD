extends Node

# Autoloads have no scene, so the resources are assigned as export defaults rather than in the Inspector.
@export var batters: Array[BatterData] = [
	preload("res://data/batters/batter_a.tres"),
	preload("res://data/batters/batter_b.tres"),
	preload("res://data/batters/batter_c.tres"),
	preload("res://data/batters/batter_d.tres"),
	preload("res://data/batters/batter_e.tres"),
	preload("res://data/batters/batter_f.tres"),
	preload("res://data/batters/batter_g.tres"),
	preload("res://data/batters/batter_h.tres"),
	preload("res://data/batters/batter_i.tres"),
]


func get_batter(index: int) -> BatterData:
	if index < 0 or index >= batters.size():
		push_error("RosterManager: no batter at index %d" % index)
		return null
	return batters[index]
