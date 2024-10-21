extends Node2D

var rad = 0.5
var shift = rad * 2.0 + rad
var x_start = 75.0
var y_start = 100.0

var rows = 100
var row_size = 100

var cube_rids: Array[RID] = []
var image_rids: Array[RID] = []

@onready var box_shape = RectangleShape2D.new()
@export var tex: Texture2D

func _ready():
    create_cubes()

func create_cubes():
    
    box_shape.size = Vector2(rad, rad)

    for row in range(rows):
        for i in range(row_size):
            var x = i * shift + x_start
            var y = y_start + row * shift

         # Create a RigidBody2D in the PhysicsServer
            var cube_rid: RID = PhysicsServer2D.body_create()
            cube_rids.append(cube_rid)
            PhysicsServer2D.body_set_mode(cube_rid, PhysicsServer2D.BODY_MODE_RIGID)
            PhysicsServer2D.body_set_space(cube_rid, get_world_2d().space)
            PhysicsServer2D.body_set_param(cube_rid, PhysicsServer2D.BODY_PARAM_GRAVITY_SCALE, 0.05)
            PhysicsServer2D.body_set_param(cube_rid, PhysicsServer2D.BODY_PARAM_BOUNCE, 5.0)
            # PhysicsServer2D.gravity_scale(cube_rid, 0.05)

            # Set the cube's position
            var cube_transform = Transform2D()
            cube_transform.origin = Vector2(x, y)
            PhysicsServer2D.body_set_state(cube_rid, PhysicsServer2D.BODY_STATE_TRANSFORM, cube_transform)
            PhysicsServer2D.body_add_shape(cube_rid, box_shape)

            var image = RenderingServer.canvas_item_create()
            image_rids.append(image)
            RenderingServer.canvas_item_set_parent(image, get_canvas_item())
            RenderingServer.canvas_item_add_texture_rect(image, Rect2(Vector2(-rad, -rad), Vector2(rad, rad)), tex)
            RenderingServer.canvas_item_set_transform(image, cube_transform)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    for i in range(len(cube_rids)):
        var cube_rid: RID = cube_rids[i]
        var image_rid: RID = image_rids[i]
        var cube_transform: Transform2D = PhysicsServer2D.body_get_state(cube_rid, PhysicsServer2D.BODY_STATE_TRANSFORM)
        RenderingServer.canvas_item_set_transform(image_rid, cube_transform)
    pass