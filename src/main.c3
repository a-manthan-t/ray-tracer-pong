module pong;

import std::core::mem;
import std::os;

import display;
import geometry;
import tracer;
import game;

fn void main() {
    display::init_window(tracer::WIDTH, tracer::HEIGHT, "Real Time Ray Tracing With Pong");
    defer display::close_window();

    // Intialise rendering components
    int core_count = os::num_cpu();

    tracer::ranges = mem::new_array(int[2], core_count);
    defer mem::free(tracer::ranges);

    for (int i = 0; i < core_count; i++) {
        tracer::ranges[i] = { (i * tracer::HEIGHT) / core_count, ((i + 1) * tracer::HEIGHT) / core_count };
    }

    tracer::render_pool.init(core_count)!!;
    tracer::gpu_buffer = display::make_gpu_buffer(tracer::WIDTH, tracer::HEIGHT);
    defer display::free_buffer(tracer::gpu_buffer);

    while (!display::should_close()) {
        game::update();
        tracer::draw_frame();
    }
}
