const std = @import("std");
const rl = @import("raylib");
const alias = @import("../alias.zig");
const time = @import("../time.zig");

const Node = @import("node.zig");
const Bullet = @This();

velocity: alias.Velocity,
position: alias.Position,
target: rl.Vector2 = .zero(),

elapsed: time.Elapsed = .{ .elapsed = 0 },
comptime lifetime: time.Lifetime = .{
    .max = struct {
        fn max(comptime T: type, val: *T, _: anytype) f32 {
            return val.max;
        }
    }.max,
    .after = struct {
        fn spawn(comptime T: type, val: *T, info: anytype) time.Lifetime.Error!void {
            Node.initRegistry(val.target, info).addValue(info) catch |err| switch (err) {
                error.OutOfMemory => return error.OutOfMemory,
            };
            try info.dropDeferred(val);
        }
    }.spawn,
},
max: f32,

comptime radius: alias.Radius = .{ .radius = 10 },
comptime col: rl.Color = .white,

pub const speed = 5000;

pub fn spawn(position: rl.Vector2, target: rl.Vector2) Bullet {
    const diff = target.subtract(position);
    const theta = std.math.atan2(diff.y, diff.x);

    const lifetime = diff.length() / speed;

    const velocity: rl.Vector2 = .{ .x = @cos(theta) * speed, .y = @sin(theta) * speed };

    return .{
        .max = lifetime,
        .velocity = .{ .velocity = velocity },
        .position = .{ .position = position },
        .target = target,
    };
}
