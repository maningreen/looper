const std = @import("std");
const Io = std.Io;

const looper = @import("looper");
const raylib = looper.raylib;

pub fn main(init: std.process.Init) !void {
    raylib.setTraceLogLevel(.warning);
    raylib.initWindow(1920 * 0.9, 1080 * 0.9, "hell");
    defer raylib.closeWindow();

    const shader = try raylib.loadShader(null, "./resources/shaders/palette.glsl");
    defer shader.unload();

    const pixelLength = 10;
    const renderTexture = try raylib.loadRenderTexture(
        @trunc(looper.border.length / pixelLength),
        @trunc(looper.border.length / pixelLength),
    );
    defer renderTexture.unload();

    const rand = std.Random.IoSource{ .io = init.io };
    var registry = looper.Registry.init(init.io, init.gpa, looper.Extra{
        .camera = .{
            .offset = .zero(),
            .target = .zero(),
            .rotation = 0,
            .zoom = 0.4,
        },
        .random = rand.interface(),
        .renderTexture = renderTexture,
        .shader = shader,
    });
    defer registry.deinit();

    try registry.addValue(try looper.Player.init(init.gpa, init.io));

    var last = std.Io.Timestamp.now(init.io, .real);
    raylib.setTargetFPS(120);
    while (!raylib.windowShouldClose()) {
        const now = std.Io.Timestamp.now(init.io, .real);
        const t = @as(f64, @floatFromInt(last.durationTo(now).nanoseconds)) / std.time.ns_per_s;
        last = now;

        const extra: *looper.Extra = &registry.info.extra;
        looper.camera.singlePass(&registry.info);
        extra.mousePosition = extra.camera.target.subtract(extra.camera.offset.subtract(raylib.getMousePosition()).scale(1 / extra.camera.zoom));
        extra.windowDimensions = .{
            .x = @floatFromInt(raylib.getScreenWidth()),
            .y = @floatFromInt(raylib.getScreenHeight()),
        };

        {
            var key = raylib.getKeyPressed();
            while (key != .null) : (key = raylib.getKeyPressed())
                try registry.emit(key);
        }

        try registry.process(@floatCast(t));

        extra.start();

        try registry.emit(looper.alias.Render{});

        looper.border.render();

        extra.end();
    }
}
