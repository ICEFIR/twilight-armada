extends RigidBody2D

var ship_collision_polygon: CollisionPolygon2D 
var ship_modules: Node2D
@export var ship_name: String = "Ship"
@export var max_speed: float = 100
@export var max_rotation_speed: float = 1
@export var thrust: float = 1
@export var rotation_thrust: float = 1
@export var max_health: float = 100

var health: float = max_health
var current_speed: float = 0
var current_rotation_speed: float = 0
var velocity: Vector2 = Vector2.ZERO

# Input variables
var thrust_input: float = 0
var rotation_input: float = 0

# Optional targeting system variables
var target_position: Vector2 = Vector2.ZERO
var target_angle: float = 0

var selected: bool = false
var mouse_over: bool = false
var is_right_clicking: bool = false
var dragging = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    connect("mouse_entered", on_mouse_entered)
    connect("mouse_exited", on_mouse_exited)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    if Input.is_action_just_pressed("RightClick"):
        is_right_clicking = true
    if Input.is_action_just_released("RightClick"):
        is_right_clicking = false
    process_ship_dragging() 
    
func process_ship_dragging():
    var updated_dragging = is_right_clicking && mouse_over && Global.ship_draggable
    if updated_dragging != dragging:
        dragging = updated_dragging
        if dragging:
            freeze = true
        else:
            freeze = false
            apply_central_impulse(Input.get_last_mouse_velocity())
    
    if dragging:
        var mouse_position = get_global_mouse_position()
        global_position = mouse_position
func on_mouse_entered():
    mouse_over = true

func on_mouse_exited():
    mouse_over = false
