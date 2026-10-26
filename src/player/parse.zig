const std = @import("std");
const raylib = @import("raylib");
const VectorMap = @import("vectormap.zig");
const input = @import("../input.zig");
const KeyBind = @import("bindings.zig").KeyBind;

pub const localPath: []const u8 = "resources/keymap.zig.zon";

pub const StableKey = blk: {
    const info = @typeInfo(raylib.KeyboardKey).@"enum";
    var values: [info.field_values.len]info.tag_type = undefined;
    for (info.field_values, &values) |f, *t| {
        t.* = f;
    }

    break :blk @Enum(info.tag_type, .exhaustive, info.field_names, &values);
};

pub const StableMouseButton = blk: {
    const info = @typeInfo(raylib.MouseButton).@"enum";
    var values: [info.field_values.len]info.tag_type = undefined;
    for (info.field_values, &values) |f, *t| {
        t.* = f;
    }

    break :blk @Enum(info.tag_type, .exhaustive, info.field_names, &values);
};

pub const StableBinding = union(enum) {
    key: StableKey,
    mouse: StableMouseButton,

    fn from(binding: input.Binding) StableBinding {
        return switch (binding) {
            .key => |key| .{ .key = @fromBackingInt(@backingInt(key)) },
            .mouse => |mouse| .{ .mouse = @fromBackingInt(@backingInt(mouse)) },
        };
    }

    fn to(binding: StableBinding) input.Binding {
        return switch (binding) {
            .key => |key| .{ .key = @fromBackingInt(@backingInt(key)) },
            .mouse => |mouse| .{ .mouse = @fromBackingInt(@backingInt(mouse)) },
        };
    }
};

pub const Storage = struct {
    direction: VectorMap,

    keys: std.enums.EnumFieldStruct(KeyBind, StableBinding, null),

    pub fn from(direction: VectorMap, keys: [std.enums.values(KeyBind).len]input.Binding) Storage {
        var values: std.enums.EnumFieldStruct(KeyBind, StableBinding, null) = undefined;
        inline for (std.enums.values(KeyBind), keys) |tag, value|
            @field(values, @tagName(tag)) = StableBinding.from(value);
        return .{ .direction = direction, .keys = values };
    }

    pub fn to(self: Storage) struct {
        VectorMap,
        [std.enums.values(KeyBind).len]input.Binding,
    } {
        var bindings: [std.enums.values(KeyBind).len]input.Binding = undefined;
        inline for (&bindings, std.enums.values(KeyBind)) |*bind, tag|
            bind.* = @field(self.keys, @tagName(tag)).to();
        return .{
            self.direction,
            self.keys,
        };
    }

    pub fn parse(buffer: []const u8) ?Storage {
        const diagnostics: std.zon.parse.Diagnostics = .{ .errors = &.{} };
        const parsed = std.zon.parse.fromSlice(
            Storage,
            .{
                .arena = .failing,
                .gpa = .failing,
                .source = buffer,
                .diagnostics = &diagnostics,
                .ignore_unknown_fields = true,
            },
        ) catch return null;
        return parsed;
    }

    pub fn format(self: Storage, writer: *std.Io.Writer) !void {
        return std.zon.fmt(self, .{}).format(writer);
    }

    pub fn fromFile(io: std.Io, gpa: std.mem.Allocator, path: ?[]const u8) !Storage {
        const file = try std.Io.Dir.cwd().openFile(io, path orelse localPath, .{});
        defer file.close(io);

        var buf: [256]u8 = undefined;
        var reader = file.reader(io, &buf);
        // reader.interface.take
    }
};
