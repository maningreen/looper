const std = @import("std");

const mangle = @import("mangle");
const alias = @import("alias.zig");

pub const Elapsed = mangle.Alias(f32, "elapsed");
pub const Lifetime = struct {
    /// The threshold in which the elapsed time must surpass
    max: fn (type, anytype, anytype) f32,
    /// this is called on every `process`, it's expected to deinit the value.
    /// If null, it's similar to `normal`
    after: ?fn (type, anytype, anytype) Error!void = null,

    pub const Error = error{AfterError} || std.mem.Allocator.Error;
};
pub const MaxLifetime = struct {
    max: f32,
};

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
        if (value.elapsed >= value.max.max) {
            try info.dropDeferred(value);
        }
    }
};
