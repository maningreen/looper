const std = @import("std");
const Io = std.Io;

const game = @import("game");
const raylib = game.raylib;

pub fn main(init: std.process.Init) !void {
    var registry = game.Registry.init(init.io, init.gpa, .{});
    defer registry.deinit();

    try registry.addValue(game.Player{ .velocity = game.mangle.alias(game.alias.Velocity, raylib.Vector2{ .x = 100, .y = 100 }) });

    raylib.setTraceLogLevel(.warning);
    raylib.initWindow(1920 * 0.9, 1080 * 0.9, "hell");
    defer raylib.closeWindow();

    // const shader = try raylib.loadShader(null, "./resources/shaders/palette.glsl");
    // defer shader.unload();
    // std.debug.print("{}", .{shader});

    // const pixelLength = 10;
    // const renderTexture = try raylib.loadRenderTexture(1920 / 4, 1080 / 4);
    // defer renderTexture.unload();

    raylib.setTargetFPS(60);
    while (!raylib.windowShouldClose()) {
        registry.info.extra.mousePosition = raylib.getMousePosition();

        try registry.process(raylib.getFrameTime());
        raylib.beginDrawing();

        // renderTexture.begin();
        // shader.activate();

        raylib.clearBackground(.black);

        try registry.emit(game.alias.Render{});
        
        game.border.render();

        // shader.deactivate();
        // renderTexture.end();

        // renderTexture.texture.drawPro(
            // .{ .x = 0, .y = 0, .height = @floatFromInt(-renderTexture.texture.height), .width = @floatFromInt(renderTexture.texture.width) },
            // .{ .x = 0, .y = 0, .height = @floatFromInt(raylib.getScreenHeight()), .width = @floatFromInt(raylib.getScreenWidth()) },
            // .{ .x = 0, .y = 0 },
            // 0,
            // .white,
        // );

        raylib.endDrawing();
    }
}
