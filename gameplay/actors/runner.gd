class_name Runner
extends Node3D

@export var move_duration: float = 2.0
@export var target_position: Vector3 = Vector3.ZERO

@onready var body_mesh: MeshInstance3D = $MeshInstance3D


func set_batter_data(data: BatterData) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = data.body_color
	body_mesh.material_override = material


func move_to(new_position: Vector3) -> void:
	target_position = new_position
	var tween := create_tween()
	tween.tween_property(self, "global_position", target_position, move_duration)
