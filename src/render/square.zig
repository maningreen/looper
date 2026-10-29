const std = @import("std");
const mangle = @import("mangle");
const rl = @import("raylib");
const alias = @import("../alias.zig");
const border = @import("../border.zig");
const physics = @import("../physics.zig");

pub const requirements = mangle.system.Signature{
    .fields = &.{
        .{ .name = "position", .schema = .{ .simple = alias.Position } },
        .{ .name = "length", .schema = .{ .simple = alias.SquareDimensions } },
        .{ .name = "color", .schema = .{ .simple = rl.Color } },
        .{ .name = "rot", .schema = .{ .simple = physics.rotation.Rotation }, .status = .optional },
    },
};

pub fn receive(comptime T: type, value: *T, event: anytype, _: anytype) void {
    switch (@TypeOf(event)) {
        alias.Render => draw(value.*),
        else => {},
    }
}

fn draw(value: anytype) void {
    const T = @TypeOf(value);
    if (@hasField(T, "rot")) {
        rl.drawRectanglePro(
            .{
                .x = value.position.x,
                .y = value.position.y,
                .height = value.length.side,
                .width = value.length.side,
            },
            (rl.Vector2{ .x = value.length.side, .y = value.length.side }).scale(0.5),
            value.rot.theta * std.math.deg_per_rad,
            value.color,
        );
    } else {
        rl.drawRectanglePro(
            .{
                .x = value.position.x,
                .y = value.position.y,
                .height = value.length.side,
                .width = value.length.side,
            },
            (rl.Vector2{ .x = value.length.side, .y = value.length.side }).scale(0.5),
            0,
            value.color,
        );
    }
}
