const std = @import("std");
const Io = std.Io;

const looper = @import("looper");
const raylib = looper.raylib;

const zlua = looper.zlua;
const Lua = zlua.Lua;

const builtin = @import("builtin");

pub fn main() !void {
    var underlying = switch (builtin.mode) {
        .debug => blk: {
            const base = std.heap.page_allocator;
            const safe = std.heap.SafeAllocator.init(base, .{});
            break :blk .{
                .base = base,
                .safe = safe,
            };
        },
        else => .{ .gpa = std.heap.page_allocator },
    };
    const gpa = switch (builtin.mode) {
        .debug => underlying.safe.allocator(),
        else => underlying.gpa,
    };
    defer switch (builtin.mode) {
        .debug => {
            _ = underlying.safe.deinit();
        },
        else => {},
    };

    var threaded = std.Io.Threaded.init(gpa, .{});
    defer threaded.deinit();
    const io = threaded.io();
    // seed with IO, then use a DefaultPrng for speed's sake.
    var rand = std.Random.DefaultPrng.init(
        (std.Random.IoSource{
            .io = io,
        }).interface().int(u64),
    );

    raylib.setTraceLogLevel(.warning);

    const name = looper.messages.getRandom(rand.random());
    if (@import("builtin").mode == .debug)
        std.log.debug("Name: {s}", .{name});

    raylib.initWindow(1920 * 0.9, 1080 * 0.9, name);
    defer raylib.closeWindow();

    const shader = try raylib.loadShader(null, "./resources/shaders/palette.glsl");
    defer shader.unload();

    const renderTexture = try raylib.loadRenderTexture(
        @trunc(looper.border.length / looper.pixelLength),
        @trunc(looper.border.length / looper.pixelLength),
    );
    defer renderTexture.unload();

    var lua = try Lua.init(gpa);
    defer lua.deinit();
    lua.openMath();
    lua.openBase();
    lua.openString();

    var registry = looper.Registry.init(io, gpa, looper.Extra{
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
        .lua = lua,
    });
    defer registry.deinit();

    try registry.addValue(try looper.Player.init(gpa, io));
    try registry.addValue(looper.enemy.Simple{});

    var last = std.Io.Timestamp.now(io, .awake);
    raylib.setTargetFPS(60);
    while (!raylib.windowShouldClose()) {
        const now = std.Io.Timestamp.now(io, .awake);
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

        extra.start();

        try registry.process(if (extra.paused) 0 else @floatCast(t));

        try registry.emit(looper.alias.Render{});

        looper.border.render();

        extra.end();
    }
}
