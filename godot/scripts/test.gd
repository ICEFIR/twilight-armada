extends Area2D

var mouse_over: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    connect("mouse_entered", on_mouse_entered)
    connect("mouse_exited", on_mouse_exited)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass
    
func on_mouse_entered():
    mouse_over = true
    print("Mouse entered " + name + " with mouse over: " + str(mouse_over))

func on_mouse_exited():
    mouse_over = false
    print("Mouse exited" + name + " with mouse over: " + str(mouse_over))
