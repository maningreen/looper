const std = @import("std");

const mangle = @import("mangle");
const rl = @import("raylib");
const alias = @import("alias.zig");

pub const defaultLength: comptime_float = 2000;

pub var length: f32 = 2000;

pub const system = struct {
    pub const requirements = mangle.system.Signature.fromStruct(struct {
        position: alias.Position,
    });

    pub fn process(comptime T: type, value: *T, _: anytype) void {
        if (value.position.x < 0 or value.position.x > length)
            value.position = wrap(value.position);
        if (value.position.y < 0 or value.position.y > length) {
            value.position = wrap(value.position);
        }
    }
};

pub fn wrap(vector: rl.Vector2) rl.Vector2 {
    return .{
        .x = (vector.x) - length * @trunc(2 * (vector.x - length / 2) / length),
        .y = (vector.y) - length * @trunc(2 * (vector.y - length / 2) / length),
    };
}

pub fn wrapValue(value: f32) f32 {
    return value - length * @trunc(2 * (value - length / 2) / length);
}

pub fn getShortestPathTo(a: rl.Vector2, b: rl.Vector2) rl.Vector2 {
    // from a -> b
    var diff = b.subtract(a);
    if (@abs(diff.x) > length) {
        diff.x += length * -std.math.sign(diff.x);
    }
    if (@abs(diff.y) > length) {
        diff.x += length * -std.math.sign(diff.x);
    }
    return diff;
}

pub fn render() void {
    rl.drawRectangleLinesEx(
        .{
            .x = 0,
            .y = 0,
            .height = length,
            .width = length,
        },
        10,
        .ray_white,
    );
}
