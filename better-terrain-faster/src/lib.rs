mod editor;
use godot::prelude::*;
struct BetterTerrianFasterExtension;

#[gdextension]
unsafe impl ExtensionLibrary for BetterTerrianFasterExtension{}
