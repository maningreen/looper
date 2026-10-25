const std = @import("std");
const mangle = @import("mangle");
const raylib = @import("raylib");

const alias = @import("alias.zig");

pub const system = struct {
    pub const requirements = mangle.system.Signature.fromStruct(
        struct {
            handler: Manager,
            velocity: alias.Velocity,
        },
    );

    pub fn process(comptime T: type, value: *T, info: anytype) !void {
        if (value.handler.table.accelerate) |getVel| {
            const accel: raylib.Vector2 = getVel(T, value, info);
            if (accel.x != 0 or accel.y != 0) {
                if (value.handler.table.onAccelerate) |onAccel|
                    try onAccel(T, value, accel, info);
            }
            value.velocity = value.velocity.add(accel);
        }
    }
};

pub const Manager = struct {
    table: VTable = .{},

    pub const Error = error{AccelerateError};

    pub const VTable = struct {
        accelerate: ?fn (comptime T: type, self: anytype, info: anytype) raylib.Vector2 = null,
        /// this will do nothing without a getVelocity != to `return .zero()`
        onAccelerate: ?fn (comptime T: type, self: anytype, accleration: raylib.Vector2, info: anytype) Error!void = null,
    };
};
