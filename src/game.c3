module game;

import display;
import geometry;

import std::io;
import std::math;

const float FRICTION = 0.1;

enum Scene {
    FLOOR,
    BALL,
    LEFT_PADDLE,
    RIGHT_PADDLE,
    BACKGROUND,
    LAMP,
}

Shape[6] scene = {
    { Material.GREY_METAL, { .normal = { 0, 0, 1 } }, { 0, 0, -1 }, ShapeType.PLANE },
    { Material.RED_GLASS, { 1 }, { 0, 8, 0 }, ShapeType.SPHERE },
    { Material.BLUE_BLOCK, { .dimensions = { 1, 4, 0.25 } }, { -5, 6, -0.75 }, ShapeType.CUBOID },
    { Material.BLUE_BLOCK, { .dimensions = { 1, 4, 0.25 } }, { 4, 6, -0.75 }, ShapeType.CUBOID },
    { Material.GREEN_ORB, { 2 }, { 0, 14, 1 }, ShapeType.SPHERE },
    { Material.LAMP, { 0.5 }, { -10, 10, 10 }, ShapeType.SPHERE },
};

// Ball variables.
bool moving_right = true;
float speed_x = 2;
float speed_y = 0;

fn void update() {
    float dt = display::frame_time();

    // Update positions.
    speed_x -= FRICTION * display::frame_time();
    scene[Scene.BALL].position.x += (moving_right ? 1 : -1) * speed_x * dt;
    scene[Scene.BALL].position.y += speed_y * dt;

    // Check for collisions with paddles.
    if (math::abs(scene[Scene.BALL].position.x) >= 3.5) {
        moving_right = !moving_right;
        speed_x = 2;

        Scene paddle = scene[Scene.BALL].position.x <= 0 ? Scene.LEFT_PADDLE : Scene.RIGHT_PADDLE;
        float min_y = scene[paddle].position.y;
        float max_y = min_y + scene[paddle].layout.dimensions.y;

        if (min_y >= scene[Scene.BALL].position.y || max_y <= scene[Scene.BALL].position.y) {
            speed_y = 0;
            scene[Scene.BALL].position = { 0, 8, 0 };
            scene[Scene.LEFT_PADDLE].position.y = 6;
            scene[Scene.RIGHT_PADDLE].position.y = 6;
        } else {
            speed_y = (scene[Scene.BALL].position.y - (min_y + max_y) / 2) * 2;
        }
    }

    // Handle input.
    if (display::is_key_down(Key.W)) {
        scene[Scene.LEFT_PADDLE].position.y += dt * 4;
    } else if (display::is_key_down(Key.S)) {
        scene[Scene.LEFT_PADDLE].position.y -= dt * 4;
    }

    if (display::is_key_down(Key.UP)) {
        scene[Scene.RIGHT_PADDLE].position.y += dt * 4;
    } else if (display::is_key_down(Key.DOWN)) {
        scene[Scene.RIGHT_PADDLE].position.y -= dt * 4;
    }
}
