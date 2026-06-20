module geometry;

import std::math;

alias Vec3 = float[<3>];
alias Colour = char[<4>];
alias ColourPerc = float[<3>]; // Each float is between 0 and 1 (percent absorption).

const ColourPerc SKY = { 0.12, 0.2, 0.25 };

enum Material : (
    ColourPerc base,    // Base colour.
    // Floats below are between 0 and 1.
    float opacity,      // How much light passes through the object.
    float specular,     // How mirror-like the object is.
    float shiny,        // Controls the reflection brightness fade and can be as large as you want (ie, > 1).
    float emission,     // How much light the object emits.
    float refr_idx,     // The ratio of the speed of light in the material vs a vacuum.
) {
    RED_GLASS { { 1, 0, 0 }, 0.2, 0.5, 16, 0, 1.5 },
    GREY_METAL { { 0.5, 0.5, 0.5 }, 1, 0.25, 64, 0, 0 },
    GREEN_BLOCK { { 0.125, 1, 0.5 }, 1, 0.75, 128, 0, 1.2 },
    LAMP { { 0.99, 0.94, 0.65 }, 1, 0, 0, 1, 0 },
}

enum ShapeType {
    SPHERE,
    CUBOID,
    PLANE,
}

union ShapeLayout {
    float radius;    // Ensure positive.
    Vec3 dimensions; // Ensure positive.
    Vec3 normal;     // Ensure normalised.
}

struct Shape {
    Material material;
    ShapeLayout layout;
    Vec3 position;
    ShapeType type;
}

<* Find the value of t at which the ray intersects the shape. *>
fn float Shape.intersect(&self, Vec3 v, Vec3 o) {
    // Let r be the intersection point. The ray's equation is r = vt + o.
    // v is the (normalised) ray direction, t is some scalar along the ray, o is the offset.
    float t = float::max;

    switch (self.type) {
        case SPHERE:
            // Require |r - p| = rad
            // |vt + o - p| = rad -> expand and form quadratic at^2 + bt + c
            // Here, a = v.v = 1, b = 2(o - p).v, c = (o - p).(o - p) - r ^ 2
            // Now use the quadratic formula to find t values
            Vec3 o_m_p = o - self.position;
            float b = 2 * o_m_p.dot(v);
            float c = o_m_p.dot(o_m_p) - self.layout.radius * self.layout.radius;

            float b2_m_4ac = b * b - 4 * c;
            if (b2_m_4ac < 0) break;

            float discriminant = math::sqrt(b2_m_4ac) / 2;
            float t1 = -b / 2 - discriminant;

            // Choose the exit point if the camera is inside the sphere.
            t = t1 <= 1e-6 ? -b / 2 + discriminant : t1;
        case CUBOID:
            // Require pos <= r <= dim + w => (pos - o)/v <= t <= (pos + dim - o)/v
            Vec3 t_min_pre = (self.position - o) / v;
            Vec3 t_max_pre = (self.position - o + self.layout.dimensions) / v;

            // Swap min and max in each axis if ray was travelling in opposite direction.
            Vec3 t_min = math::min(t_min_pre, t_max_pre);
            Vec3 t_max = math::max(t_min_pre, t_max_pre);

            float t_enter = t_min.max();
            float t_exit = t_max.min();

            if (t_enter <= t_exit) {
                // Choose the exit point if the camera is inside the cuboid.
                t = t_enter <= 1e-6 ? t_exit : t_enter;
            }
        case PLANE:
            // r.n = d -> Also d = p.n
            // r = vt + o -> t is some float
            // (vt + o).n = d => t(v.n) + o.n = d => t = (p.n - o.n)/(v.n) = (p - o).n / (v.n)
            float v_dot_n = v.dot(self.layout.normal);
            if (math::abs(v_dot_n) >= 1e-6) {
                t = (self.position - o).dot(self.layout.normal) / v_dot_n;
            }
    }

    // Object is behind camera if t is negative (halfline should only go forwards).
    return t <= 1e-6 ? float::max : t;
}

<* Find the normal to the shape at a given point of intersection. *>
fn Vec3 Shape.normal_at(&self, Vec3 p) {
    switch (self.type) {
        case SPHERE:
            return (p - self.position).normalize();
        case CUBOID:
            Vec3 min = self.position;
            Vec3 max = self.position + self.layout.dimensions;

            if (p.x - min.x <= 1e-4f) return { -1, 0, 0 };
            if (p.x - max.x <= 1e-4f) return { 1, 0, 0 };
            if (p.y - min.y <= 1e-4f) return { 0, -1, 0 };
            if (p.y - max.y <= 1e-4f) return { 0, 1, 0 };
            if (p.z - min.z <= 1e-4f) return { 0, 0, 1 };
            return { 0, 0, 1 };
        case PLANE:
            return self.layout.normal;
    }
}
