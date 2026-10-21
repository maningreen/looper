const std = @import("std");

const mangle = @import("mangle");
const alias = @import("alias.zig");

pub const Elapsed = mangle.Alias(f32, "elapsed");
pub const MaxLifetime = mangle.Alias(f32, "max");

pub const elapsed = struct {
    pub const requirements = mangle.system.Signature.fromStruct(struct {
        elapsed: Elapsed,
    });

    pub fn process(comptime T: type, value: *T, info: anytype) void {
        value.elapsed += info.delta;
    }
};

pub const maxLifetime = struct {
    pub const requirements = mangle.system.Signature.fromStruct(struct {
        elapsed: Elapsed,
        max: MaxLifetime,
    });

    pub fn process(comptime T: type, value: *T, info: anytype) !void {
        if (value.elapsed >= value.max) 
            try info.dropDeferred(value);
    }
};
