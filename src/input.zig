const std = @import("std");
const mangle = @import("mangle");
const raylib = @import("raylib");

const alias = @import("alias.zig");

pub const system = struct {
    pub const requirements = mangle.system.Signature.fromStruct(
        struct {
            handler: Handler,
            velocity: alias.Velocity,
        },
    );

    pub fn process(comptime T: type, value: *T, info: anytype) !void {
        if (value.handler.table.getVelocity) |getVel| {
            const vel: raylib.Vector2 = getVel(T, value, info);
            if (vel.subtract(value.velocity).lengthSqr() > 1) {
                if (value.handler.table.onAccelerate) |accel|
                    try accel(T, value, info);
            }
            value.velocity = vel;
        }
    }
};

pub const Handler = struct {
    table: VTable,

    pub const Error = error{AccelerateError};

    pub const VTable = struct {
        getVelocity: ?fn (comptime T: type, self: anytype, info: anytype) raylib.Vector2 = null,
        /// this will do nothing without a getVelocity != to `return .zero()`
        onAccelerate: ?fn (comptime T: type, self: anytype, info: anytype) Error!void = null,
    };
};
