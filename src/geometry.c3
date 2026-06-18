module geometry;

typedef Vec3 = inline float[<3>];
typedef Colour = inline char[<4>];

struct Material {
    Colour albedo;
    float roughness;
    float metallic;
    float emission;
}

enum ShapeType {
    SPHERE,
    CUBOID,
    PLANE,
}

union ShapeLayout {
    float radius;
    Vec3 dimensions;
    Vec3 normal;
}

struct Shape {
    Material material;
    ShapeLayout layout;
    Vec3 position;
    ShapeType type;
}

struct IntersectionData {
    Vec3 next_direction;
    Vec3 next_offset;
}

fn IntersectionData? Shape.intersect(&self, Vec3 ray_direction, Vec3 ray_offset) {
    switch (self.type) {
        case SPHERE:
        case CUBOID:
        case PLANE:
            (void) (ray_direction.dot(self.layout.normal) == 0);
    }

    return {}; // TODO
}
