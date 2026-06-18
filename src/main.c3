module pong;

import std::io;
import std::core::mem;

import display;
import geometry;
import tracer;

const int WIDTH = 720;
const int HEIGHT = 480;
const int DEPTH = 1;
const int BOUNCES = 2;

fn void main() {
    display::init_window(WIDTH, HEIGHT, "Real Time Ray Tracing in Pong");

    Colour[] frame_buffer = mem::new_array(Colour, WIDTH * HEIGHT);
    Buffer gpu_buffer = display::make_gpu_buffer(WIDTH, HEIGHT);
    Shape[5] scene; // TODO init scene with light source, ball, floor, and paddles
    // TODO multithreaded

    defer mem::free(frame_buffer);
    defer display::free_buffer(gpu_buffer);

    while (!display::should_close()) {
        // TODO game logic.

        // Ray tracing loop.
        for (uint row = 0; row < HEIGHT; row++) {
            for (uint col = 0; col < WIDTH; col++) {
                frame_buffer[row * HEIGHT + col] = tracer::trace({ row, col, DEPTH }, {}, &scene, BOUNCES);
            }
        }

        display::update_frame(gpu_buffer, frame_buffer);
    }

    display::close_window();
}
