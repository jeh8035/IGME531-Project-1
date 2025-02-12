extends Node

@export var building_prefab : Resource = preload("res://BuildingGeneration/building.tscn")

var grid_size_x : float = 100
var grid_size_y : float = 100
@export var grid_separation_x : float
@export var grid_separation_y : float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for x in range(0, grid_size_x, grid_separation_x):
		for y in range(0, grid_size_y, grid_separation_y):
			var instance : Node3D = building_prefab.instantiate()
			instance.translate(Vector3(x, 0, y))
			add_child(instance)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
