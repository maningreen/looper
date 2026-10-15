const std = @import("std");
const mangle = @import("mangle");
const raylib = @import("raylib");

pub const Handler = struct {
    table: *const VTable,
    const VTable = struct {
        getInputVector: fn (self: *Handler, info: anytype) raylib.Vector2,
    };
};
