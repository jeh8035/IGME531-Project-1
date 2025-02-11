extends MultiMeshInstance3D

@export
var mesh : Mesh

var data : PackedFloat32Array

func add_block(x : float, y : float, z : float) -> void:
	data.append_array([
		1, 0, 0, x,
		0, 1, 0, y,
		0, 0, 1, z
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
	add_block(0,0,0)
	add_block(2,2,2)
	finish()
