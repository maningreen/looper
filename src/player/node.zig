const std = @import("std");
const rl = @import("raylib");
const mangle = @import("mangle");

const time = @import("../time.zig");
const enemy = @import("../enemy.zig");
const alias = @import("../alias.zig");
const render = @import("../render.zig");

const Laser = @import("../laser.zig");
const HealthManager = @import("../health.zig");
const Node = @This();
const Flag = struct {};

pos: alias.Position,

/// local coordinates relative to position.
/// if null the first item *will* be used
next: Next = .none,

elapsed: time.Elapsed = .{ .elapsed = 0 },

comptime lifespan: time.Lifetime = .{
    .max = struct {
        pub fn max(_: type, _: anytype, _: anytype) f32 {
            return 3;
        }
    }.max,
    .after = struct {
        pub fn after(comptime T: type, value: *T, info: anytype) time.Lifetime.Error!void {
            info.emit(systems.add.Pop{}) catch |err| switch (err) {
                error.OutOfMemory => return error.OutOfMemory,
                else => return time.Lifetime.Error.AfterError,
            };
            try info.dropDeferred(value);
        }
    }.after,
},
comptime radius: alias.Radius = .{ .radius = 10 },
comptime col: rl.Color = color,
comptime flag: Flag = .{},

pub fn init(pos: rl.Vector2) Node {
    return .{
        .pos = .{ .position = pos },
    };
}

pub fn initRegistry(pos: rl.Vector2, info: anytype) Node {
    const maybe = info.getItemFromIndex(Node, 0, .bottom);
    if (maybe) |first| {
        return Node{
            .pos = .{ .position = pos },
            .next = Next{ .first = Next.Data{
                .position = first.pos.position,
                .laser = Laser.init(pos, first.pos.position, .white, 10),
            } },
        };
    } else return .{ .pos = .{ .position = pos } };
}

pub fn setNextSys(comptime T: type, value: *T, next: Node, comptime tag: std.meta.Tag(Next)) void {
    comptime std.debug.assert(tag != .none);
    value.next = @unionInit(Next, @tagName(tag), .{
        .position = next.pos.position,
        .laser = Laser.init(value.pos, next.pos.position, color, 10),
    });
}

pub fn setNext(self: *Node, next: Node) void {
    setNextSys(Node, self, next);
}

pub fn addValue(node: Node, info: anytype) !void {
    try info.appendDeferred(node);
    try info.emit(systems.add.Push{ .node = node });
}

pub const Next = union(enum) {
    next: Data,
    first: Data,
    none: void,
    const Data = struct {
        position: rl.Vector2,
        laser: Laser,
    };
};

fn Damage(comptime T: type) type {
    return struct {
        comptime Enemy: type = T,
        instance: *T,

        pub const isDamage = true;
    };
}

const color = rl.Color.white;

pub const systems = struct {
    pub const render = struct {
        pub const requirements = mangle.system.Signature.fromStruct(Node);

        pub fn receive(comptime T: type, value: *T, event: anytype, info: anytype) void {
            switch (@TypeOf(event)) {
                alias.Render => {
                    switch (@as(Next, value.next)) {
                        .none => {
                            const first = info.getItemFromIndex(T, 0, .bottom) orelse return;
                            if (@intFromPtr(first) == @intFromPtr(value)) // convert to int because getItemFromIndex returns internal, not named
                                return;
                            const l = Laser.init(value.pos, first.pos.position, value.col, 10);
                            l.draw();
                        },
                        .first, .next => |next| {
                            next.laser.draw();
                        },
                    }
                },
                else => {},
            }
        }
    };

    pub const add = struct {
        pub const requirements = mangle.system.Signature.fromStruct(Node);

        pub const Push = struct {
            node: Node,
        };

        pub const Pop = struct {};

        pub fn receive(comptime T: type, value: *T, event: anytype, info: anytype) !void {
            switch (@TypeOf(event)) {
                Push => addNode(T, value, event.node, info),
                Pop => try dropNode(T, value, info),
                else => {},
            }
        }

        pub fn addNode(comptime T: type, value: *T, node: Node, _: anytype) void {
            switch (value.next) {
                .none, .first => setNextSys(T, value, node, .next),
                .next => {},
            }
        }

        pub fn dropNode(comptime T: type, value: *T, info: anytype) !void {
            switch (value.next) {
                .first => {
                    const maybe = info.getItemFromIndex(Node, 1, .bottom);
                    if (maybe) |second|
                        setNextSys(T, value, mangle.flags.originalType(second.*), .first)
                    else
                        value.next = .none;
                },
                else => {},
            }
        }
    };

    pub const applyDamage = struct {
        pub const en = struct {
            pub const requirements = mangle.system.Signature.fromStruct(struct {
                enemyFlag: enemy.EnemyFlag,
                radius: alias.Radius,
                position: alias.Position,
                hm: HealthManager,
            });

            pub fn process(comptime T: type, value: *T, info: anytype) !void {
                try info.emit(Damage(T){ .instance = value });
            }
        };
        pub const node = struct {
            pub const requirements = mangle.system.Signature.fromStruct(Node);

            pub fn receive(comptime T: type, value: *T, event: anytype, info: anytype) void {
                if (comptime !@hasDecl(@TypeOf(event), "isDamage")) return;
                if (comptime !@TypeOf(event).isDamage) return;

                const damage: Damage(event.Enemy) = event;
                const next = switch (value.next) {
                    .next, .first => |v| v,
                    .none => return,
                };
                if (next.laser.collidesWrap(damage.instance.position, damage.instance.radius))
                    damage.instance.hm = damage.instance.hm.damage(5 * info.delta);
            }
        };
    };
};
