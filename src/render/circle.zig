const std = @import("std");
const mangle = @import("mangle");
const rl = @import("raylib");
const alias = @import("../alias.zig");
const border = @import("../border.zig");
const physics = @import("../physics.zig");

pub const requirements = mangle.system.Signature{
    .fields = &.{
        .{ .name = "color", .schema = .{ .simple = rl.Color } },
        .{ .name = "radius", .schema = .{ .simple = alias.Radius } },
        .{ .name = "pos", .schema = .{ .simple = alias.Position } },
    },
};
pub fn receive(comptime T: type, value: *T, event: anytype, _: anytype) void {
    switch (@TypeOf(event)) {
        alias.Render => draw(value),
        else => {},
    }
}

fn draw(value: anytype) void {
    rl.drawCircleV(value.pos, value.radius, value.color);
}
