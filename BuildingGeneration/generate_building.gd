extends MultiMeshInstance3D

@export var mesh : Mesh
@export var bounds : Vector3
@export var num_blocks : int

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
	for i in range(num_blocks):
		add_block(
			randf_range(0, bounds.x),
			randf_range(0, bounds.y),
			randf_range(0, bounds.z),
			Vector3(
				randf_range(1, bounds.x),
				randf_range(1, bounds.y),
				randf_range(1, bounds.z)
			)
		)
	finish()
