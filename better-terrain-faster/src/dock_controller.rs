use godot::classes::Control;
use godot::prelude::*;

#[derive(GodotClass)]
#[class(base=Control, init)]
pub(crate) struct BetterTerrainFasterDockController {
    base: Base<Control>,
}