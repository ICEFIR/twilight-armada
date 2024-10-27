extends Control

@export var sprite_item_scene: PackedScene
@export var target_ship: ShipController

var sprite_container: HFlowContainer
var active_ship_build_component: ShipBuildComponent

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Get the HFlowContainer node from the scene.
	sprite_container = $ScrollContainer/HFlowContainer
	scan_ship_components()
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func add_item(texture: Texture2D, item_name: String) -> void:
	# instantiate the sprite item and add it to the sprite container
	var sprite_item: SpriteItem = sprite_item_scene.instantiate()
	sprite_item.set_texture(texture)
	sprite_container.add_child(sprite_item)
	sprite_item.set_onclick_callback(
		func(): 
			if active_ship_build_component:
				active_ship_build_component.queue_free()
			active_ship_build_component = ShipBuildComponent.new()
			print("Selected sprite item: " + item_name)
			active_ship_build_component.add_child(sprite_item.get_node("Sprite2D").duplicate())
			if target_ship:
				target_ship.add_child(active_ship_build_component)
			else:
				add_child(active_ship_build_component)
	)

func scan_ship_components() -> void:
	print("Scanning for ship compoenents")
	# scan components/ship_components for all sprite items
	var scan_path = "res://assets/components/ship_components"
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
					add_item(sprite_item.texture, file_name)
				else:
					print("The root node is not a Sprite2D for file: " + file_name)
			file_name = dir.get_next()
