const std = @import("std");
const mangle = @import("mangle");
const rl = @import("raylib");

const alias = @import("alias.zig");

const HealthManager = @import("health.zig");
const render = @import("render.zig");

pub const Simple = struct {
    position: alias.Position = .{ .position = .{ .x = 1000, .y = 1000 } },
    health: HealthManager = .init(5),

    comptime radius: alias.Radius = .{ .radius = 30 },
    comptime color: rl.Color = .brown,
    comptime renderManager: render.health.Flag = .{
        .offset = .{
            .x = -15,
            .y = 35,
            .height = 10,
            .width = 30,
        },
    },
};
