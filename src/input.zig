const std = @import("std");
const mangle = @import("mangle");
const raylib = @import("raylib");

pub const system = struct {
    pub const requirements = mangle.system.Signature{
        .fields = &.{
            .{ .name = "bindings", .schema = .{ .array = Binding } },
            .{ .name = "callbacks", .schema = .{ .array = Callback } },
        },
    };

    pub fn process(comptime T: type, value: *T, info: anytype) !void {
        inline for (value.bindings, value.callbacks) |bind, call| {
            switch (bind) {
                .mouse => |button| if (raylib.isMouseButtonPressed(button))
                    try call(T, value, info),
                else => {},
            }
        }
    }

    pub fn receive(comptime T: type, value: *T, event: anytype, info: anytype) !void {
        switch (@TypeOf(event)) {
            raylib.KeyboardKey => try recieveKey(T, value, event, info),
            else => {},
        }
    }

    pub fn recieveKey(comptime T: type, value: *T, event: raylib.KeyboardKey, info: anytype) !void {
        inline for (value.bindings, value.callbacks) |bind, call| {
            switch (bind) {
                .key => |key| if (event == key) try call(T, value, info),
                else => {},
            }
        }
    }
};

pub const Binding = union(enum) {
    key: raylib.KeyboardKey,
    mouse: raylib.MouseButton,
};
pub const Callback = fn (comptime T: type, value: anytype, info: anytype) Error!void;
pub const Error = error{KeymapError};
