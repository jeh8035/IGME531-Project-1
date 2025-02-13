class_name RoadGenerator
extends MultiMeshInstance3D

@export var mesh : Mesh

var data : PackedFloat32Array

func add_block(x : float, y : float, z : float, new_scale : Vector3 = Vector3(1,1,1)) -> void:
	data.append_array([
		new_scale.x, 0, 0, x,
		0, new_scale.y, 0, y,
		0, 0, new_scale.z, z
	])

func finish() -> void:
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = floori(data.size() / 12.0)
	multimesh.visible_instance_count = multimesh.instance_count
	multimesh.buffer = data

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for x in range(0, get_parent().grid_size_x, get_parent().grid_separation_x):
		add_block(
			x + 3*get_parent().road_width/4 + get_parent().grid_separation_x / 2,
			0,
			get_parent().grid_size_y / 2,
			Vector3(
				get_parent().road_width,
				5.0,
				get_parent().grid_size_y / 2
			)
		)
	for y in range(0, get_parent().grid_size_y, get_parent().grid_separation_y):
		add_block(
			get_parent().grid_size_x / 2,
			0,
			y + 3*get_parent().road_width/4 + get_parent().grid_separation_y / 2,
			Vector3(
				get_parent().grid_size_x / 2,
				5.0,
				get_parent().road_width
			)
		)
			
	finish()
