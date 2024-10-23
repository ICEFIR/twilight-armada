extends Panel

var sprite: Sprite2D 
var sprite_texture: Texture2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sprite = $Sprite2D
	if sprite_texture:
		apply_texture()

func set_texture(texture: Texture2D) -> void:
	sprite_texture = texture
	if sprite:
		apply_texture()


func apply_texture() -> void:
	sprite.texture = sprite_texture
	# resize this panel to the underlying sprite size
	custom_minimum_size = sprite_texture.get_size()
	# set the panel size to the sprite size
	set_size(custom_minimum_size)
	# set the sprite position to the center of the panel
	sprite.position = custom_minimum_size / 2

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
