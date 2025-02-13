class_name BuildingGenerator

extends MultiMeshInstance3D

@export var mesh : Mesh
var bounds : Vector3
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
	var type : int = randi_range(0,2)
	
	match type:
		0:	# Random
			add_block(
				bounds.x/2,
				0,
				bounds.z/2,
				Vector3(
					bounds.x,
					1,
					bounds.z
				)
			)
			for i in range(num_blocks):
				var y_val = randf_range(0, bounds.y)
				add_block(
					randf_range((y_val/bounds.y) * bounds.x/2, bounds.x/2 + bounds.x/2 * (1 - (y_val/bounds.y))),
					y_val,
					randf_range((y_val/bounds.y) * bounds.z/2, bounds.z/2 + bounds.z/2 * (1 - (y_val/bounds.y))),
					Vector3(
						randf_range(1, bounds.x/10),
						randf_range(1, bounds.y/2),
						randf_range(1, bounds.z/10)
					)
				)
		1:	# Stacked
			for i in range(num_blocks):
				add_block(
					bounds.x/2,
					(bounds.y/num_blocks) * i,
					bounds.z/2,
					Vector3(
						bounds.x/sqrt(i),
						(bounds.y/num_blocks),
						bounds.z/sqrt(i)
					)
				)
		2:	# Cube
			add_block(
				bounds.x/2,
				0,
				bounds.z/2,
				Vector3(
					bounds.x,
					bounds.y,
					bounds.z
				)
			)
	finish()
