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
        const vel = value.handler.table.getVelocity(T, value, info);
        value.velocity = vel;
    }
};

pub const Handler = struct {
    table: VTable,
    pub const VTable = struct {
        getVelocity: fn (comptime T: type, self: anytype, info: anytype) raylib.Vector2,
    };
};
