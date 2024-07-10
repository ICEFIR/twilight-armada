
use std::borrow::BorrowMut;
use std::rc::Rc;

use godot::{engine::EditorInterface, prelude::*};
use godot::classes::EditorPlugin;
use serde::{Serialize, Deserialize};
use godot::engine::{Control, IEditorPlugin};



#[derive(GodotClass)]
#[class(base=EditorPlugin, tool, init, editor_plugin)]
struct BetterTerrianFasterEditor {
    dock_scene: Option<Gd<Control>>,
    base: Base<EditorPlugin>
}

#[godot_api]
impl IEditorPlugin for BetterTerrianFasterEditor{
    fn ready(&mut self) {
        godot_print!("Better terrain faster Rust Extension Ready!"); // Prints to the Godot console
    }

    fn enter_tree(&mut self) {
        godot_print!("Better terrain faster Initilising!"); // Prints to the Godot console
        if let Ok(scene) = try_load::<PackedScene>("res://addons/better-terrain-faster/editor/dock.tscn") {
            let scene_instance = scene.instantiate_as::<Control>();
            self.base_mut().add_control_to_bottom_panel(scene_instance.clone(), GString::from("Better Terrain Faster"));
            self.dock_scene = Some(scene_instance);
        } else {
            godot_print!("Failed to load scene");
            return;
        }
        godot_print!("Better terrain faster Rust Extension initialised!"); 
    }

    fn exit_tree(&mut self) {
        godot_print!("Better terrain faster Rust Extension Exit Tree!"); // Prints to the Godot console
        let dock_scene = &mut self.dock_scene.take().unwrap();
        self.base_mut().remove_control_from_bottom_panel(dock_scene.clone());
        dock_scene.queue_free();
    }
} 