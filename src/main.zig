const std = @import("std");
const Io = std.Io;

const looper = @import("looper");
const raylib = looper.raylib;

pub fn main(init: std.process.Init) !void {
    // seed with IO, then use a DefaultPrng for speed's sake.
    var rand = std.Random.DefaultPrng.init(
        (std.Random.IoSource{
            .io = init.io,
        }).interface().int(u64),
    );

    raylib.setTraceLogLevel(.warning);

    const name = try init.gpa.printSentinel(
        "Looper{s}",
        .{looper.messages.getRandom(rand.random())},
        0,
    );
    if (@import("builtin").mode == .debug)
        std.log.debug("Name: {s}", .{name});

    raylib.initWindow(1920 * 0.9, 1080 * 0.9, name);
    defer raylib.closeWindow();

    init.gpa.free(name);

    const shader = try raylib.loadShader(null, "./resources/shaders/palette.glsl");
    defer shader.unload();

    const renderTexture = try raylib.loadRenderTexture(
        @trunc(looper.border.length / looper.pixelLength),
        @trunc(looper.border.length / looper.pixelLength),
    );
    defer renderTexture.unload();

    var registry = looper.Registry.init(init.io, init.gpa, looper.Extra{
        .camera = .{
            .offset = .zero(),
            .target = .zero(),
            .rotation = 0,
            .zoom = 0.4,
        },
        .random = rand.random(),
        .renderTexture = renderTexture,
        .shader = shader,
        .paused = false,
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
        if (!extra.paused)
            extra.mousePosition = extra.camera.target.subtract(extra.camera.offset.subtract(raylib.getMousePosition()).scale(1 / extra.camera.zoom));
        extra.windowDimensions = .{
            .x = @floatFromInt(raylib.getScreenWidth()),
            .y = @floatFromInt(raylib.getScreenHeight()),
        };

        {
            var key = raylib.getKeyPressed();
            while (key != .null) : (key = raylib.getKeyPressed()) {
                if (key == .p) {
                    extra.paused = !extra.paused;
                }
                try registry.emit(key);
            }
        }

        try registry.process(if (extra.paused) 0 else @floatCast(t));

        extra.start();

        try registry.emit(looper.alias.Render{});

        looper.border.render();

        extra.end();
    }
}
