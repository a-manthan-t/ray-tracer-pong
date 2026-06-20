module pong;

import std::io;
import std::core::mem;

import display;
import geometry;
import tracer;

const int WIDTH = 720;
const int HEIGHT = 480;
const int DEPTH = 100;
const int BOUNCES = 5;

fn void main() {
    display::init_window(WIDTH, HEIGHT, "Real Time Ray Tracing With Pong");

    Colour[] frame_buffer = mem::new_array(Colour, WIDTH * HEIGHT);
    Buffer gpu_buffer = display::make_gpu_buffer(WIDTH, HEIGHT);

    defer mem::free(frame_buffer);
    defer display::free_buffer(gpu_buffer);

    Shape[5] scene; // TODO init scene with light source, ball, floor, and paddles

    scene[0] = { Material.GREY_METAL, {}, { 0, 0, -1 }, ShapeType.PLANE };
    scene[0].layout.normal = { 0, 0, 1 };

    scene[1] = { Material.RED_GLASS, { 1 }, { -0.5, 2, 0.5 }, ShapeType.SPHERE };
    scene[2] = { Material.GREEN_BLOCK, { 3 }, { 0, 5, 4 }, ShapeType.SPHERE };
    scene[3] = { Material.GREEN_BLOCK, { 0.8 }, { 3, 2, 1 }, ShapeType.SPHERE };
    scene[4] = { Material.LAMP, { 0.5 }, { -3, -1, 0.5 }, ShapeType.SPHERE };

    // TODO multithreaded, maybe anti aliasing

    while (!display::should_close()) {
        // TODO game logic.

        // Ray tracing loop.
        for (uint row = 0; row < HEIGHT; row++) {
            for (uint col = 0; col < WIDTH; col++) {
                ColourPerc p = tracer::trace(
                    (Vec3) { (float) col - WIDTH / 2, DEPTH, HEIGHT / 2 - (float) row }.normalize(),
                    {},
                    &scene,
                    true,
                    BOUNCES,
                ) * 255;
                frame_buffer[row * WIDTH + col] = (Colour) { (char) p.r, (char) p.g, (char) p.b, 255 };
            }
        }

        display::update_frame(gpu_buffer, frame_buffer);
    }

    display::close_window();
}
