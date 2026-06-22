module tracer;

import std::io;
import std::thread::threadpool;

import display;
import game;
import geometry;
import pong;

const int WIDTH = 720;
const int HEIGHT = 480;
const int DEPTH = 480;
const int BOUNCES = 5;

Buffer gpu_buffer;
Colour[WIDTH * HEIGHT] frame_buffer;

int core_count;
int[2][] ranges;
FixedThreadPool render_pool;

<* Carries our ray tracing and draws a frame. *>
fn void draw_frame() {
    foreach (range : ranges) {
        render_pool.push((ThreadPoolFn) &trace_range, range)!!;
    }

    render_pool.join();
    display::update_frame(gpu_buffer, &frame_buffer);
}

<* Task for a pool to trace all pixels in a range. *>
fn void trace_range(int[]... ranges) {
    int[] range = ranges[0];

    for (int row = range[0]; row < range[1]; row++) {
        for (int col = 0; col < WIDTH; col++) {
            ColourPerc p = tracer::trace(
                (Vec3) { (float) col - WIDTH / 2, DEPTH, HEIGHT / 2 - (float) row }.normalize(),
                {},
                true,
                BOUNCES,
            ) * 255;
            frame_buffer[row * WIDTH + col] = (Colour) { (char) p.r, (char) p.g, (char) p.b, 255 };
        }
    }
}

<* Trace a ray of light to find its colour. *>
fn ColourPerc trace(Vec3 direction, Vec3 offset, bool in_air, int bounces_left) {
    direction = direction.normalize();

    // Find object light ray collides with.
    float t = float::max;
    Shape* seen = null;

    foreach (&shape : game::scene) {
        float new_t = shape.intersect(direction, offset);
        if (new_t < t) {
            t = new_t;
            seen = shape;
        }
    }

    // Sky colour if no object.
    if (t == float::max) {
        return geometry::SKY;
    }

    // A pure light source should only emit its colour.
    if (seen.material.emission == 1) {
        return seen.material.base;
    }

    Vec3 intersection = direction * t + offset;
    Vec3 normal = seen.normal_at(intersection) * (in_air ? 1 : -1);

    // Find contributions from each light source in the scene using the Phong reflection model.

    // Ambient light and emitted light.
    ColourPerc result = (geometry::SKY + seen.material.emission) * seen.material.base;

    foreach NEXT_LIGHT: (&light : game::scene) {
        if (light.material.emission == 0 || light == seen) {
            continue;
        }

        Vec3 light_dir = (light.position - intersection).normalize();
        Vec3 light_offset = intersection + 1e-2 * normal;
        float lt = light.intersect(light_dir, light_offset);

        foreach (&shape : game::scene) {
            if (shape != seen && shape != light && shape.intersect(light_dir, light_offset) < lt) {
                continue NEXT_LIGHT;
            }
        }

        ColourPerc light_colour = light.material.base * light.material.emission;
        result +=
            // diffuse lighting
            seen.material.base * light_colour * max(0, light_dir.dot(normal)) + // Can't have negative lighting.
            // specular lighting
            seen.material.specular * light_colour * max(0, light_dir.reflect(normal).dot(direction)).pow(seen.material.shiny);
    }

    // Iterate with reflected and refracted rays depending on the material.
    if (bounces_left != 0) {
        if (seen.material.specular > 0) {
            result += seen.material.specular * trace(
                direction.reflect(normal),
                intersection + 1e-2 * normal,
                in_air,
                bounces_left - 1
            );
        }

        // Assume shapes are not nested inside each other.
        if (seen.material.opacity < 1) {
            float refr_idx = in_air ? 1 / seen.material.refr_idx : seen.material.refr_idx;
            result *= seen.material.opacity;
            result += trace(
                direction.refract(normal, refr_idx),
                intersection - 1e-2 * normal,
                !in_air,
                bounces_left - 1
            ) * (1 - seen.material.opacity);
        }
    }

    // To prevent overflow wrapping when casting to chars.
    return { min(result.r, 1), min(result.g, 1), min(result.b, 1) };
}
