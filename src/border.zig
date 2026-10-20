const std = @import("std");

const mangle = @import("mangle");
const rl = @import("raylib");
const alias = @import("alias.zig");

pub var borderLength: f32 = 1000;

pub const system = struct {
    pub const requirements = mangle.system.Signature.fromStruct(struct {
        position: alias.Position,
    });

    pub fn process(comptime T: type, value: *T, _: anytype) void {
        if (value.position.x < 0 or value.position.x > borderLength)
            value.position = wrap(value.position);
        if (value.position.y < 0 or value.position.y > borderLength) {
            value.position = wrap(value.position);
        }
    }
};

pub fn wrap(vector: rl.Vector2) rl.Vector2 {
    return .{
        .x = vector.x - borderLength * @trunc(2 * (vector.x - borderLength / 2) / borderLength),
        .y = vector.y - borderLength * @trunc(2 * (vector.y - borderLength / 2) / borderLength),
    };
}

pub fn render() void {
    rl.drawRectangleLinesEx(.{.x = 0, .y = 0, .height = borderLength, .width = borderLength,}, 10, .ray_white);
}
