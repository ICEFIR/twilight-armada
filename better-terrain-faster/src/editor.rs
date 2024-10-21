use std::collections::HashMap;
use std::time::UNIX_EPOCH;

use godot::classes::{Button, Control, EditorPlugin, IEditorPlugin, TileSet};
use godot::prelude::*;
use serde::{Deserialize, Serialize};

static EDITOR_DOCK_PATH: &str = "res://addons/better-terrain-faster/editor/dock.tscn";
static FILE_WATCH_CHECK_INTERVAL_MS: i32 = 2000;

#[derive(GodotClass)]
#[class(base=EditorPlugin, tool, init)]
struct BetterTerrainFasterEditor {
    file_watch_countdown_timer: i32,
    file_watch: HashMap<String, FileWatchMeta>,
    tile_set: Option<Gd<TileSet>>,
    dock_scene_instance: Option<Gd<Control>>,
    dock_button: Option<Gd<Button>>,
    base: Base<EditorPlugin>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct FileWatchMeta {
    last_modified: u128,
}

#[godot_api]
impl IEditorPlugin for BetterTerrainFasterEditor {
    fn make_visible(&mut self, visible: bool) {
        if self.dock_button.is_some() {
            self.dock_button.as_mut().unwrap().set_visible(visible);
        }
    }

    fn handles(&self, object: Gd<Object>) -> bool {
        if !object.is_instance_valid() {
            return false;
        }
        return object.is_class(GString::from("TileMapLayer")) || object.is_class(GString::from("TileSet"));
    }

    fn physics_process(&mut self, delta: f64) {
        // Count timer for file watch. Once it reaches 0, check for file changes
        // if self.dock_scene_instance.is_some() {
        //     godot_print!("Better terrain faster is dock visible: {}", self.dock_scene_instance.as_ref().unwrap().is_visible());
        // }

        self.file_watch_check(delta)
    }

    /* Setup only handles TileMayLayers */
    // Edit has incorrect calling signature, so this cannot be implemented in rust
    // https://github.com/godot-rust/gdext/issues/494
    // This call will be delegated to the GDScript side
    fn edit(&mut self, object: Option<Gd<Object>>) {
        if object.is_none() {
            return;
        }
        let object = object.unwrap();
        if object.is_class(GString::from("TileMapLayer")) {
            godot_print!("Better terrain faster editing tile map layer");
            // self.tile_map_layer = Some(object.cast::<TileMapLayer>().unwrap());
        } else if object.is_class(GString::from("TileSet")) {
            godot_print!("Better terrain faster editing tile set");
            self.tile_set = Some(object.cast::<TileSet>());
        }
    }

    fn enter_tree(&mut self) {
        self.load_dock_ui();
        self.setup_file_watch();
    }

    fn exit_tree(&mut self) {
        godot_print!("Better terrain faster Rust Extension Exit Tree!"); // Prints to the Godot console
        self.unload_dock_ui();
    }

    fn ready(&mut self) {
        self.file_watch_countdown_timer = FILE_WATCH_CHECK_INTERVAL_MS;
    }
}

#[godot_api]
impl BetterTerrainFasterEditor {
    fn setup_file_watch(&mut self) {
        self.file_watch.insert(EDITOR_DOCK_PATH.to_string(), load_file_metadata(EDITOR_DOCK_PATH));
    }

    fn file_watch_check(&mut self, delta: f64) {
        self.file_watch_countdown_timer -= (delta * 1000.0) as i32;
        if self.file_watch_countdown_timer >= 0 {
            return;
        }
        self.file_watch_countdown_timer = FILE_WATCH_CHECK_INTERVAL_MS;
        // godot_print!("Checking for file changes");
        let mut modified: bool = false;
        for (file_path, file_meta) in self.file_watch.clone().iter() {
            let metadata = load_file_metadata(file_path);
            if metadata.last_modified != file_meta.last_modified {
                godot_print!("File has been modified: {}, recorded last modified {}, actual last modified {}", file_path, file_meta.last_modified, metadata.last_modified);
                modified = true;
                self.file_watch.insert(file_path.to_string(), metadata);
            }
        }
        if modified {
            self.reload_files();
        }
    }

    fn reload_files(&mut self) {
        godot_print!("Better terrian faster reloading files");
        self.unload_dock_ui();
        self.load_dock_ui();
    }

    fn load_dock_ui(&mut self) {
        godot_print!("Loading better terrain faster scene");
        let scene = match try_load::<PackedScene>(EDITOR_DOCK_PATH) {
            Ok(s) => s,
            Err(_) => {
                godot_print!("Failed to load scene");
                return;
            }
        };

        let scene_instance = match scene.try_instantiate_as::<Control>() {
            Some(instance) => instance,
            None => {
                godot_print!("Failed to instantiate scene");
                return;
            }
        };

        let mut dock_button = self.base_mut().add_control_to_bottom_panel(
            scene_instance.clone(),
            GString::from("Better Terrain Faster"),
        );

        if let Some(button) = dock_button.as_mut() {
            button.set_visible(false);
            self.dock_button = dock_button;
            self.dock_scene_instance = Some(scene_instance);
        } else {
            godot_print!("Failed to add control to bottom panel");
        }
    }

    fn unload_dock_ui(&mut self) {
        godot_print!("Unloading better terrain faster dock ui");
        if self.dock_button.is_some() {
            self.dock_button.take().unwrap().queue_free();
        }
        let mut dock_scene_instance_option = self.dock_scene_instance.take();
        match &mut dock_scene_instance_option {
            Some(dock_scene_instance) => {
                self.base_mut()
                    .remove_control_from_bottom_panel(dock_scene_instance.clone());
                dock_scene_instance.queue_free();
            }
            None => {
                godot_print!("Dock scene is already unloaded");
            }
        }
    }
}

fn load_file_metadata(res_path: &str) -> FileWatchMeta {
    // convert res path to file path
    let file_path = res_path.replace("res://", "");
    let metadata = std::fs::metadata(file_path).unwrap();
    FileWatchMeta {
        last_modified: metadata
            .modified()
            .unwrap()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_millis(),
    }
}
