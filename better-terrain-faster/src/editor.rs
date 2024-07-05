
struct TwilightArmadaExtension;
use godot::prelude::*;
use godot::classes::EditorPlugin;
use serde::{Serialize, Deserialize};
use godot::engine::IEditorPlugin;

#[derive(GodotClass)]
#[class(base=EditorPlugin)]
struct BetterTerrianFasterEditor {
    base: Base<EditorPlugin>
}

#[godot_api]
impl IEditorPlugin for BetterTerrianFasterEditor{
    fn init(base: Base<EditorPlugin>) -> Self {
        godot_print!("Hello, world from better terrain faster!"); // Prints to the Godot console
        
        Self {
            base,
        }
    }

    fn enter_tree(&mut self) {
        godot_print!("Hello, world from better terrain faster enter tree!"); // Prints to the Godot console
        
    }

} 