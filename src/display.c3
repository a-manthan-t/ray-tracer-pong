<* Bindings to raylib and helper functions for drawing. *>
module display;

import geometry;

extern fn void init_window(CInt width, CInt height, CChar* title) @cname("InitWindow");
extern fn CInt should_close() @cname("WindowShouldClose");
extern fn void close_window() @cname("CloseWindow");

extern fn void begin_drawing() @cname("BeginDrawing");
extern fn void end_drawing() @cname("EndDrawing");

struct Color {
    char r;
    char g;
    char b;
    char a;
}

struct Canvas {
    void *data;
    int width;
    int height;
    int mipmaps;
    int format;
}

struct Buffer {
    CUInt id;
    CInt width;
    CInt height;
    CInt mipmaps;
    CInt format;
}

extern fn Canvas make_canvas(CInt width, CInt height, Color tint) @cname("GenImageColor");
extern fn void free_canvas(Canvas canvas) @cname("UnloadImage");
extern fn void draw_fps(CInt x, CInt y) @cname("DrawFPS");
extern fn void clear(Color color) @cname("ClearBackground");

extern fn Buffer load_buffer(Canvas canvas) @cname("LoadTextureFromImage");
extern fn void free_buffer(Buffer buffer) @cname("UnloadTexture");

fn Buffer make_gpu_buffer(int width, int height) {
    Canvas canvas = make_canvas(width, height, { 255, 255, 255, 255 });
    defer free_canvas(canvas);
    return load_buffer(canvas);
}

extern fn void update_buffer(Buffer texture, void* pixels) @cname("UpdateTexture");
extern fn void draw_buffer(Buffer buffer, CInt posX, CInt posY, Color tint) @cname("DrawTexture");

fn void update_frame(Buffer buffer, geometry::Colour[] pixels) {
    begin_drawing();
    clear({});
    update_buffer(buffer, pixels);
    draw_buffer(buffer, 0, 0, { 255, 255, 255, 255 });
    draw_fps(5, 5);
    end_drawing();
}
