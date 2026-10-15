const std = @import("std");
const Io = std.Io;

const game = @import("game");
const raylib = game.raylib;

pub fn main(init: std.process.Init) !void {
    var registry = game.Registry.init(init.io, init.gpa, {});
    defer registry.deinit();

    raylib.initWindow(1920 / 2, 540, "hell");
    defer raylib.closeWindow();

    raylib.setTargetFPS(30);
    while (!raylib.windowShouldClose()) {
        raylib.beginDrawing();
        raylib.drawSplineBezierQuadratic(&.{ .{ .x = 0, .y = 0 }, .{ .x = 0, .y = 100 }, .{ .x = 100, .y = 100 } }, 10, .white);
        raylib.endDrawing();
    }
}
