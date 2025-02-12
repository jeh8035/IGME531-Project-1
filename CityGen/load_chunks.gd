extends Node

@export var player_node : Node3D
@export var chunk_size : int

var chunk_asset := preload("res://CityGen/city_gen.tscn")

var loaded_chunks : Dictionary

func encode_coordinate(coordinate : Vector3) -> Vector2i:
	return Vector2i(
		roundi(0.5 + coordinate.x / chunk_size),
		roundi(0.5 + coordinate.z / chunk_size)
	)
	

func decode_coordinate(key : Vector2i) -> Vector3:
	return Vector3(
		(key.x - 0.5) * chunk_size,
		0,
		(key.y - 0.5) * chunk_size
	)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var trunc_pos := encode_coordinate(player_node.global_position)
	
	if !loaded_chunks.has(trunc_pos):
		var asset : Node3D = chunk_asset.instantiate()
		asset.grid_size_x = chunk_size
		asset.grid_size_y = chunk_size
		add_child(asset)
		asset.global_position = decode_coordinate(trunc_pos)
		loaded_chunks[trunc_pos] = true
