const std = @import("std");
const raylib = @import("raylib");
const VectorMap = @import("vectormap.zig");
const input = @import("../input.zig");
const KeyBind = @import("bindings.zig").KeyBind;

const StableKey = blk: {
    const info = @typeInfo(raylib.KeyboardKey).@"enum";
    var values: [info.field_values.len]info.tag_type = undefined;
    for (info.field_values, &values) |f, *t| {
        t.* = f;
    }

    break :blk @Enum(info.tag_type, .exhaustive, info.field_names, &values);
};

const StableMouseButton = blk: {
    const info = @typeInfo(raylib.MouseButton).@"enum";
    var values: [info.field_values.len]info.tag_type = undefined;
    for (info.field_values, &values) |f, *t| {
        t.* = f;
    }

    break :blk @Enum(info.tag_type, .exhaustive, info.field_names, &values);
};

const Storage = struct {
    direction: VectorMap,

    keys: std.EnumArray(KeyBind, input.Binding),

    fn from() !void {}
};
