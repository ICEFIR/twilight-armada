extends Node2D

var selection_start = Vector2.ZERO
var selection_end = Vector2.ZERO
var is_dragging = false
var selected_units = []
var selection_area: CollisionShape2D
var selection_area_color_rect: ColorRect

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    selection_area = get_node("SelectionArea").get_node("CollisionShape2D")
    selection_area_color_rect = get_node("SelectionArea").get_node("ColorRect")
    update_selection_area()
    pass # Replace with function body.

func _unhandled_input(event):
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            # Start selection
            selection_start = get_local_mouse_position()
            is_dragging = true
        elif is_dragging:
            # End selection only if we were dragging
            finish_selection()
    

    
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    if is_dragging:
        selection_end = get_local_mouse_position()
        update_selection_area()

    if Input.is_action_just_released("LeftClick"):
        finish_selection()

func select_units_in_rectangle():
    pass

func update_selection_area():
    if is_dragging:
        selection_area.disabled = false
        selection_area.visible = true
        selection_area_color_rect.visible = true
        var startX : float = min(selection_start.x, selection_end.x)
        var startY : float = min(selection_start.y, selection_end.y)
        var endX : float = max(selection_start.x, selection_end.x)
        var endY : float = max(selection_start.y, selection_end.y)

        var rect = Rect2(Vector2(startX, startY), Vector2(endX - startX, endY - startY))

        selection_area.position = rect.position + rect.size / 2
        selection_area.shape.extents = rect.size / 2

        selection_area_color_rect.position = rect.position
        selection_area_color_rect.size = rect.size
    else:
        selection_area.disabled = true
        selection_area.visible = false
        selection_area_color_rect.visible = false

func finish_selection():
    print("Selection finished")
    is_dragging = false
    selection_end = get_local_mouse_position()
    update_selection_area()
    select_units_in_rectangle()
