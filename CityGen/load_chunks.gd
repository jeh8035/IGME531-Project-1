extends Node

@export var player_node : Node3D
@export var chunk_size : int

var chunk_asset := preload("res://CityGen/city_gen.tscn")

var loaded_chunks : Dictionary

func encode_coordinate(coordinate : Vector3, offX : float = 0.5, offY : float = 0.5) -> Vector2i:
	return Vector2i(
		roundi((coordinate.x / chunk_size) + offX),
		roundi((coordinate.z / chunk_size) + offY)
	)
	

func decode_coordinate(key : Vector2i) -> Vector3:
	return Vector3(
		(key.x) * chunk_size,
		0,
		(key.y) * chunk_size
	)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	for x in range(-1, 2):
		for y in range(-1, 2):
			var trunc_pos := encode_coordinate(player_node.global_position, x, y)
			
			if !loaded_chunks.has(trunc_pos):
				var asset : Node3D = chunk_asset.instantiate()
				asset.grid_size_x = chunk_size
				asset.grid_size_y = chunk_size
				asset.translate(decode_coordinate(trunc_pos))
				add_child(asset)
				loaded_chunks[trunc_pos] = true
