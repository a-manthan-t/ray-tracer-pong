module pong;

import std::io;
import std::core::mem;
import std::thread::pool;

import display;
import geometry;
import tracer;

const int WIDTH = 720;
const int HEIGHT = 480;
const int DEPTH = 100;
const int BOUNCES = 5;

const float FRICTION = 0.25;
const int CORE_COUNT = 8;

Shape[4] scene;
int[2][CORE_COUNT] ranges;
Colour[WIDTH * HEIGHT] frame_buffer;
ThreadPool {CORE_COUNT} render_pool;

fn void main() {
    // Initialise globals
    scene[0] = { Material.GREY_METAL, {}, { 0, 0, -1 }, ShapeType.PLANE };
    scene[0].layout.normal = { 0, 0, 1 };
    scene[1] = { Material.RED_GLASS, { 1 }, { -0.5, 2, 0 }, ShapeType.SPHERE };
    scene[2] = { Material.GREEN_BLOCK, { 3 }, { 0, 5, 3 }, ShapeType.SPHERE };
    scene[3] = { Material.LAMP, { 0.5 }, { -3, -1, 5 }, ShapeType.SPHERE };

    for (int i = 0; i < CORE_COUNT; i++) {
        ranges[i] = { (i * HEIGHT) / CORE_COUNT, ((i + 1) * HEIGHT) / CORE_COUNT };
    }
    ranges[CORE_COUNT - 1][1] = HEIGHT;

    // Intialise rendering components
    display::init_window(WIDTH, HEIGHT, "Real Time Ray Tracing With Pong");

    Buffer gpu_buffer = display::make_gpu_buffer(WIDTH, HEIGHT);
    defer display::free_buffer(gpu_buffer);

    render_pool.init()!!;

    // Game variables
    bool moving_right = true;
    float ball_speed = 2;

    while (!display::should_close()) {
        // TODO game logic.
        //
        ball_speed -= max(0, FRICTION * display::frame_time());
        scene[1].position.x += (moving_right ? 1 : -1) * ball_speed * display::frame_time();
        if (scene[1].position.x >= 3) {
            moving_right = false;
            ball_speed = 2;
        }

        if (scene[1].position.x <= -3) {
            moving_right = true;
            ball_speed = 2;
        }

        // Ray tracing loop.
        foreach (&range : ranges) {
            render_pool.push((ThreadFn) &tracer::trace_range, range);
        }

        render_pool.join();
        display::update_frame(gpu_buffer, &frame_buffer);
    }

    display::close_window();
}
