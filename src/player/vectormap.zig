const std = @import("std");

const mangle = @import("mangle");
const raylib = @import("raylib");
const raygui = @import("raygui");

const VectorMap = @This();

pub const parse = struct {
    pub const localPath: []const u8 = "resources/keymap.zig.zon";
    /// 1 kilobyte.
    pub const maximum: usize = 1024;

    const Represent = @Struct(
        .auto,
        null,
        @typeInfo(VectorMap).@"struct".field_names,
        &@splat(parse.StableKey),
        @typeInfo(VectorMap).@"struct".field_attrs,
    );

    pub fn to(value: VectorMap) Represent {
        var rep: Represent = undefined;
        inline for (@typeInfo(VectorMap).@"struct".field_names) |name|
            @field(rep, name) = @fromBackingInt(@backingInt(@field(value, name)));
        return rep;
    }
    pub fn from(represent: Represent) VectorMap {
        var value: VectorMap = undefined;
        inline for (@typeInfo(VectorMap).@"struct".field_names) |name|
            @field(value, name) = @fromBackingInt(@backingInt(@field(represent, name)));
        return value;
    }
    const StableKey = blk: {
        const info = @typeInfo(Key).@"enum";
        var values: [info.field_values.len]info.tag_type = undefined;
        for (info.field_values, &values) |f, *t| {
            t.* = f;
        }

        break :blk @Enum(info.tag_type, .exhaustive, info.field_names, &values);
    };
};

const Key = raylib.KeyboardKey;

left: Key = .a,
right: Key = .d,
up: Key = .w,
down: Key = .s,

/// returns scalar -1 | 0 | 1
pub fn getHorizontalInput(self: VectorMap) f32 {
    return @as(f32, @floatFromInt(@intFromBool(raylib.isKeyDown(self.right)))) -
        @as(f32, @floatFromInt(@intFromBool(raylib.isKeyDown(self.left))));
}
/// returns scalar -1 | 0 | 1
pub fn getVerticalInput(self: VectorMap) f32 {
    return @as(f32, @floatFromInt(@intFromBool(raylib.isKeyDown(self.down)))) - @as(f32, @floatFromInt(@intFromBool(raylib.isKeyDown(self.up))));
}

/// returns normalized vector of
///     x = -1 | 0 | 1
///     y = -1 | 0 | 1
///     but normalized
pub fn getInput(self: VectorMap) raylib.Vector2 {
    return (raylib.Vector2{ .x = self.getHorizontalInput(), .y = self.getVerticalInput() }).normalize();
}

pub fn fromFile(gpa: std.mem.Allocator, io: std.Io, path: ?[]const u8) !VectorMap {
    const file = try std.Io.Dir.cwd().openFile(io, path orelse parse.localPath, .{ .mode = .read_only });
    defer file.close(io);

    var readBuf: [1028]u8 = undefined;
    var reader = file.reader(io, readBuf[0..]);

    const source = try reader.interface.allocRemainingAlignedSentinel(gpa, .limited(parse.maximum), .@"1", 0);
    defer gpa.free(source);

    var diagnostics = std.zon.parse.Diagnostics{
        .errors = &.{},
    };
    const parsed = try std.zon.parse.fromSliceNoAlloc(
        parse.Represent,
        .{
            .arena = .failing,
            .diagnostics = &diagnostics,
            .gpa = gpa,
            .ignore_unknown_fields = true,
            .source = source,
        },
    );
    if (diagnostics.errors.len > 0) {
        diagnostics.log(path orelse parse.localPath);
    }
    return parse.from(parsed);
}
