const std = @import("std");
const Io = std.Io;

const game = @import("game");
const raylib = game.raylib;

pub fn main(init: std.process.Init) !void {
    raylib.setTraceLogLevel(.warning);
    raylib.initWindow(1920 * 0.9, 1080 * 0.9, "hell");
    defer raylib.closeWindow();

    const shader = try raylib.loadShader(null, "./resources/shaders/palette.glsl");
    defer shader.unload();

    const pixelLength = 10;
    const renderTexture = try raylib.loadRenderTexture(
        @trunc(game.border.length / pixelLength),
        @trunc(game.border.length / pixelLength),
    );
    defer renderTexture.unload();

    const rand = std.Random.IoSource{ .io = init.io };
    var registry = game.Registry.init(init.io, init.gpa, game.Extra{
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

    try registry.addValue(try game.Player.init(init.gpa, init.io));

    raylib.setTargetFPS(60);
    while (!raylib.windowShouldClose()) {
        const extra: *game.Extra = &registry.info.extra;
        game.camera.singlePass(&registry.info);
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

        try registry.process(raylib.getFrameTime());

        extra.start();

        try registry.emit(game.alias.Render{});

        game.border.render();

        extra.end();
    }
}
