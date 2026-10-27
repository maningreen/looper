const std = @import("std");
const rl = @import("raylib");
const alias = @import("../alias.zig");
const time = @import("../time.zig");

const Bullet = @This();

velocity: alias.Velocity,
position: alias.Position,

elapsed: time.Elapsed = .{ .elapsed = 0 },
max: time.MaxLifetime,

comptime radius: alias.Radius = .{ .radius = 10 },
comptime col: rl.Color = .ray_white,

pub const speed = 5000;

pub fn spawn(position: rl.Vector2, target: rl.Vector2) Bullet {
    const diff = target.subtract(position);
    const theta = std.math.atan2(diff.y, diff.x);

    const lifetime = diff.length() / speed;

    const velocity: rl.Vector2 = .{ .x = @cos(theta) * speed, .y = @sin(theta) * speed };

    return .{
        .max = .{ .max = lifetime },
        .velocity = .{ .velocity = velocity },
        .position = .{ .position = position },
    };
}
