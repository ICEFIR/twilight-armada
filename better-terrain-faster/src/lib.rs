use godot::prelude::*;

mod editor;
mod dock_controller;
struct BetterTerrainFasterExtension;

#[gdextension]
unsafe impl ExtensionLibrary for BetterTerrainFasterExtension {}
