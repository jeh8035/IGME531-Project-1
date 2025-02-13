extends Node

@export var building_prefab : Resource = preload("res://BuildingGeneration/building.tscn")

@export var grid_separation_x : float
@export var grid_separation_y : float

@export var min_building_height : float
@export var max_building_height : float

@export var road_width : float

var grid_size_x : float = 100
var grid_size_y : float = 100

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Create buildings
	for x in range(0, grid_size_x, grid_separation_x):
		for y in range(0, grid_size_y, grid_separation_y):
			var instance : BuildingGenerator = building_prefab.instantiate()
			
			instance.bounds = Vector3(
				grid_separation_x / 2 - road_width,
				randf_range(min_building_height, max_building_height),
				grid_separation_y / 2 - road_width
			)
			
			instance.translate(Vector3(x, 0, y))
			add_child(instance)
	
	for y in range(0, grid_size_y, grid_separation_y):
		pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
