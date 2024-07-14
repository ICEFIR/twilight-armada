
use std::borrow::BorrowMut;
use std::collections::HashMap;
use std::rc::Rc;
use std::time::UNIX_EPOCH;

use godot::{engine::EditorInterface, prelude::*};
use godot::classes::EditorPlugin;
use ron::de;
use serde::{Serialize, Deserialize};
use godot::engine::{packed_scene, Control, IEditorPlugin};

static EDITOR_DOCK_PATH: &str = "res://addons/better-terrain-faster/editor/dock.tscn";
static FILE_WATCH_CHECK_INTERVAL_MS: i32 = 2000;

#[derive(GodotClass)]
#[class(base=EditorPlugin, tool, init, editor_plugin)]
struct BetterTerrianFasterEditor {
    file_watch_countdown_timer: i32,
    file_watch: HashMap<String, FileWatchMeta>,
    dock_scene: Option<Gd<Control>>,
    base: Base<EditorPlugin>
}

struct FileWatchMeta {
    last_modified: u128,
}

#[godot_api]
impl IEditorPlugin for BetterTerrianFasterEditor{
    fn ready(&mut self) {
        godot_print!("Better terrain faster Rust Extension Ready!"); // Prints to the Godot console
        self.file_watch_countdown_timer = FILE_WATCH_CHECK_INTERVAL_MS;
    }

    fn enter_tree(&mut self) {
        self.load_dock_ui();
    }

    fn physics_process(&mut self, delta: f64) {
        // Count timer for file watch. Once it reaches 0, check for file changes
        self.file_watch_check(delta)
    }
    fn exit_tree(&mut self) {
        godot_print!("Better terrain faster Rust Extension Exit Tree!"); // Prints to the Godot console
        self.unload_dock_ui();
    }
}

#[godot_api]
impl BetterTerrianFasterEditor {

    fn file_watch_check(&mut self, delta: f64) {
        self.file_watch_countdown_timer -= (delta * 1000.0) as i32;
        if self.file_watch_countdown_timer >= 0 {
           return; 
        }
        self.file_watch_countdown_timer = FILE_WATCH_CHECK_INTERVAL_MS;
        // godot_print!("Checking for file changes");
        let mut modified: bool = false;
        for (file_path, file_meta) in self.file_watch.iter_mut() {
            let metadata = load_file_metadata(file_path);
            if metadata.last_modified != file_meta.last_modified {
                godot_print!("File has been modified: {}, recorded last modified {}, actual last modified {}", file_path, file_meta.last_modified, metadata.last_modified);
                modified = true;
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
        if let Ok(scene) = try_load::<PackedScene>(EDITOR_DOCK_PATH) {
            // register file watch metadata
            let file_meta = load_file_metadata(EDITOR_DOCK_PATH);
            self.file_watch.insert(EDITOR_DOCK_PATH.to_string(), file_meta);
            let scene_instance = scene.instantiate_as::<Control>();
            self.base_mut().add_control_to_bottom_panel(scene_instance.clone(), GString::from("Better Terrain Faster"));
            self.dock_scene = Some(scene_instance);
        } else {
            godot_print!("Failed to load scene");
            return;
        }
    }
    
    fn unload_dock_ui(&mut self) {
        godot_print!("Unloading better terrain faster dock ui");
        let mut dock_scene_option = self.dock_scene.take();
        match &mut dock_scene_option {
            Some(dock_scene) => {
                self.base_mut().remove_control_from_bottom_panel(dock_scene.clone());
                dock_scene.queue_free();
            },
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
        last_modified: metadata.modified().unwrap().duration_since(UNIX_EPOCH).unwrap().as_millis()
    }
}