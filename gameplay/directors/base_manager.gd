extends Node3D

@export var runner_scene: PackedScene
@export var first_base: Node3D
@export var second_base: Node3D
@export var third_base: Node3D

var _runners: Array[Runner] = [null, null, null]
var _base_positions: Array[Node3D] = []


func _ready() -> void:
	_base_positions = [first_base, second_base, third_base]
	if runner_scene == null:
		push_error("BaseManager: runner_scene is not assigned")
		return
	for index in _base_positions.size():
		if _base_positions[index] == null:
			push_error("BaseManager: base anchor %d is not assigned" % index)
			return

	GameState.bases_changed.connect(_sync_runners)
	_sync_runners()


func _sync_runners() -> void:
	for index in GameState.bases.size():
		var batter: BatterData = GameState.bases[index]
		var runner := _runners[index]
		if batter == null:
			if runner != null:
				runner.queue_free()
				_runners[index] = null
			continue

		if runner == null:
			runner = runner_scene.instantiate() as Runner
			if runner == null:
				push_error("BaseManager: runner_scene root must use runner.gd")
				return
			add_child(runner)
			_runners[index] = runner
		runner.set_batter_data(batter)
		runner.global_position = _base_positions[index].global_position + Vector3.UP * 0.4
