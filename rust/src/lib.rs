use godot::engine::ISprite2D;
use godot::prelude::*;

struct TwilightArmadaExtension;

#[gdextension]
unsafe impl ExtensionLibrary for TwilightArmadaExtension{}

use godot::prelude::*;
use godot::classes::Sprite2D;
use serde::{Serialize, Deserialize};

#[derive(GodotClass)]
#[class(base=Sprite2D)]
struct TwilightSprint2DDemo {
    attributes: TwilightSprite2DDemoAtrributes,
    #[export]
    stest: f64,
    base: Base<Sprite2D>
}

struct TwilightSprite2DDemoAtrributes {
    speed: f64,
    angular_speed: f64,
}

#[godot_api]
impl ISprite2D for TwilightSprint2DDemo {
    fn init(base: Base<Sprite2D>) -> Self {
        godot_print!("Twilight Armada Rust Extension initilisation"); // Prints to the Godot console
        
        Self {
            attributes: TwilightSprite2DDemoAtrributes {
                speed: 400.0,
                angular_speed: std::f64::consts::PI,
            },
            stest: 0.0,
            base,
        }
        
    }

    fn physics_process(&mut self, delta: f64) {
        // In GDScript, this would be: 
        // rotation += angular_speed * delta
        
        // GDScript code:
        //
        // rotation += angular_speed * delta
        // var velocity = Vector2.UP.rotated(rotation) * speed
        // position += velocity * delta
        
        let radians = (self.attributes.angular_speed * delta) as f32;
        self.base_mut().rotate(radians);

        let rotation = self.base().get_rotation();
        let velocity = Vector2::UP.rotated(rotation) * self.attributes.speed as f32;
        self.base_mut().translate(velocity * delta as f32);
        
        // or verbose: 
        // let this = self.base_mut();
        // this.set_position(
        //     this.position() + velocity * delta as f32
        // );
    }
}