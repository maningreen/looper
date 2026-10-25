const std = @import("std");
const mangle = @import("mangle");
const rl = @import("raylib");

const alias = @import("alias.zig");
const border = @import("border.zig");

pub const Follow = mangle.Alias(bool, "should");

/// per second, to be * delta
pub const lerpRate = 10;

pub const system = struct {
    pub const requirements = mangle.system.Signature.fromStruct(
        struct {
            shouldFollow: Follow,
            pos: alias.Position,
        },
    );

    pub fn process(comptime T: type, value: *T, info: anytype) void {
        const cam: *rl.Camera2D = &info.extra.camera;
        if (value.shouldFollow) {
            if (@abs(value.pos.x - cam.target.x) >= border.length / 2) {
                const sign = std.math.sign(value.pos.x - cam.target.x);
                cam.target.x += sign * border.length;
            }
            if (@abs(value.pos.y - cam.target.y) >= border.length / 2) {
                const sign = std.math.sign(value.pos.y - cam.target.y);
                cam.target.y += sign * border.length;
            }
            cam.target = cam.target.lerp(value.pos, lerpRate * info.delta);
        }
    }
};

/// sets camera offset.
pub fn singlePass(info: anytype) void {
    const cam: *rl.Camera2D = &info.extra.camera;
    cam.offset = info.extra.windowDimensions.scale(0.5);
}
