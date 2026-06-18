module tracer;

import geometry;

fn Colour trace(Vec3 direction, Vec3 offset, Shape[] shapes, int bounces_left) {
    foreach (&shape : shapes) {
        if (try data = shape.intersect(direction, offset)) {
            // Somehow calculate colour TODO {}
            return {} + trace(...data, shapes, bounces_left - 1);
        }
    }

    return {};
}
