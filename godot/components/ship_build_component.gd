extends Node2D
class_name ShipBuildComponent
var grid_size = 16
var grid_half = 8
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Snapping to grid according to mouse position
	# assume grid size is 16x16
	
	var mouse_position = get_global_mouse_position()
	# calculate mouse position in grid coordinates
	var grid_x = int(mouse_position.x / grid_size) * grid_size
	var grid_y = int(mouse_position.y / grid_size) * grid_size
	# print("Mouse X: " + str(mouse_position.x) + " Grid X: " + str(grid_x) + "Mouse Y " + str(mouse_position.y) + " Grid Y: " + str(grid_y))

	# set the position of the ship build component to the grid coordinates
	# but since this is centered, we need to offset by half the grid size
	global_position = Vector2(grid_x, grid_y)