extends Control

var spriteContainer: HFlowContainer
@export var spriteItem: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Get the HFlowContainer node from the scene.
	spriteContainer = $Panel/ScrollContainer/HFlowContainer
	scan_sprites()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func add_item(texture: Texture2D) -> void:
	# instantiate the sprite item and add it to the sprite container
	var sprite_item = spriteItem.instantiate()
	sprite_item.set_texture(texture)
	spriteContainer.add_child(sprite_item)

func scan_sprites() -> void:
	# scan components/ship_components for all sprite items
	var scan_path = "res://components/ship_components"
	var dir := DirAccess.open(scan_path)
	if dir:
		dir.list_dir_begin()

		# each sprite item scene exists in a subdirectory of ship_components
		# for each sprite item, there exists a paced scene file with the name sprite.tscn
		# load the packed scene, instantiate it, extract the sprite item, and add it to the sprite container
		var sprite_dir := dir.get_current_dir()
		var file_name = dir.get_next()
		while file_name != "":
			var path_string = sprite_dir + "/" + file_name + "/sprite.tscn"
			print("Loading sprite item: " + path_string)
			var sprite_scene: PackedScene = load(path_string)
			if sprite_scene:
				# Instantiate the scene
				var sprite_instance = sprite_scene.instantiate()
				# Check if the root node is a Sprite2D
				if sprite_instance is Sprite2D:
					var sprite_item: Sprite2D = sprite_instance as Sprite2D
					print("Adding sprite item: " + file_name)
					add_item(sprite_item.texture)
				else:
					print("The root node is not a Sprite2D for file: " + file_name)
			file_name = dir.get_next()
			