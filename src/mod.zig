const std = @import("std");
const rl = @import("raylib");
const zlua = @import("zlua");

pub const Enemy = struct {
    color: rl.Color,
    radius: f32,
    position: rl.Vector2,
    data: zlua.AnyUserdata,
};

onInit: ?zlua.Function,
onDash: ?zlua.Function,
onFire: ?zlua.Function,

pub const Listing = struct {
    names: [][]u8,

    pub const extention = ".lua";

    pub fn load(io: std.Io, dir: std.Io.Dir, gpa: std.mem.Allocator) !Listing {
        var it = dir.iterate();
        var names: std.ArrayList([]u8) = .empty;
        while (try it.next(io)) |child| {
            switch (child.kind) {
                .file => {
                    const name = std.mem.cutSuffix(u8, child.name, extention) orelse continue;
                    const copy = try gpa.alloc(u8, name.len);
                    @memcpy(copy, name);
                    try names.append(gpa, copy);
                },
                else => {},
            }
        }
        return .{ .names = try names.toOwnedSlice(gpa) };
    }

    pub fn deinit(item: *Listing, gpa: std.mem.Allocator) void {
        for (item.names) |name| {
            gpa.free(name);
        }
        gpa.free(item.names);
        item.names = &.{};
    }
};

pub const file = struct {
    pub const directory = "./resources/mods";
};
