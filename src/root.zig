const std = @import("std");
const Io = std.Io;

pub const mangle = @import("mangle");
pub const raylib = @import("raylib");
pub const raygui = @import("raygui");

pub const Input = @import("input.zig");
pub const alias = @import("alias.zig");

pub const Registry = mangle.Registry(&.{}, &.{}, null);
