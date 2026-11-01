const std = @import("std");
const rl = @import("raylib");
const mangle = @import("mangle");
const time = @import("../time.zig");
const Laser = @import("../laser.zig");
const alias = @import("../alias.zig");
const Node = @This();
const Flag = struct {};
const render = @import("../render.zig");

pub const Next = struct {
    position: rl.Vector2,
    laser: Laser,
};

pos: alias.Position,

/// local coordinates relative to position.
next: ?Next = null,

elapsed: time.Elapsed = .{ .elapsed = 0 },
lifespan: time.MaxLifetime = .{ .max = 3 },

comptime radius: alias.Radius = .{ .radius = 10 },
comptime col: rl.Color = color,
comptime flag: Flag = .{},

pub fn init(pos: rl.Vector2) Node {
    return .{ .pos = .{ .position = pos } };
}

pub fn setNextSys(comptime T: type, value: *T, next: Node) void {
    value.next = .{
        .position = next.pos.position,
        .laser = Laser.init(value.pos, next.pos.position, color, 10),
    };
}

pub fn setNext(self: *Node, next: Node) void {
    self.next = .{
        .position = next.pos.position,
        .laser = Laser.init(self.pos, next.pos, color, 10),
    };
}

const color = rl.Color.white;

pub const addSystem = struct {
    pub const requirements = mangle.system.Signature.fromStruct(Node);

    pub fn receive(comptime T: type, value: *T, event: anytype, _: anytype) !void {
        switch (@TypeOf(event)) {
            Node => try addNode(T, value, event),
            else => {},
        }
    }

    pub fn addNode(comptime T: type, value: *T, node: Node) !void {
        std.log.debug("as;ldfj", .{});
        if (value.next == null)
            setNextSys(T, value, node);
    }
};

pub fn addValue(node: Node, info: anytype) !void {
    try info.emit(node);
    try info.appendDeferred(node);
}

pub const renderSystem = struct {
    pub const requirements = mangle.system.Signature.fromStruct(struct { next: ?Next });

    pub fn receive(comptime T: type, value: *T, event: anytype, _: anytype) void {
        switch (@TypeOf(event)) {
            alias.Render => if (value.next) |next| {
                next.laser.draw();
            },
            else => {},
        }
    }
};
