const std = @import("std");
const rl = @import("raylib");

const mangle = @import("mangle");
const alias = @import("alias.zig");
const border = @import("border.zig");
const HealthManager = @import("health.zig");

pub const Tag = enum {
    player,
    enemy,
};

pub const systems = struct {
    pub const hitbox = struct {
        pub const manage = struct {
            pub const requirements = mangle.system.Signature{
                .fields = &.{
                    .{ .schema = .{ .duck = isHitBox }, .name = "hitbox" },
                },
            };

            pub fn process(comptime T: type, value: *T, info: anytype) !void {
                try info.emit(value.hitbox);
            }
        };
        pub const position = struct {
            pub const requirements = mangle.system.Signature{
                .fields = &.{
                    .{ .schema = .{ .duck = isHitBox }, .name = "hitbox" },
                    .{ .schema = .{ .simple = alias.Position }, .name = "pos" },
                },
            };

            pub fn process(comptime T: type, value: *T, _: anytype) !void {
                value.hitbox.pos = value.pos;
            }
        };
    };

    pub const hurtbox = struct {
        pub const manage = struct {
            /// An optional field for hurtbox qualification
            pub const Info = struct {
                /// Arguments: (comptime T: type, value: *T, hitbox: anytype, info: anytype)
                onCall: ?fn (comptime type, anytype, anytype, anytype) Error!void = null,
                healthManager: bool = false,
            };
            pub const Error = error{HurtboxError};

            pub const requirements = mangle.system.Signature{
                .fields = &.{
                    .{ .schema = .{ .duck = isHurtBox }, .name = "hurtbox" },
                    .{ .schema = .{ .simple = Info }, .name = "info", .status = .optional },
                    .{ .schema = .{ .simple = HealthManager }, .name = "hm", .status = .optional },
                },
            };

            pub fn receive(comptime T: type, value: *T, event: anytype, _: anytype) (std.mem.Allocator.Error || Error)!void {
                if (comptime isHitBox(@TypeOf(event))) {
                    if (value.hurtbox.collides(event))
                        if (comptime @hasField(T, "info")) {
                            if (value.info.healthManager) {
                                if (@hasField(T, "hm")) {
                                    value.hm = value.hm.damage(event.damage);
                                } else @compileError(@typeName(mangle.flags.OriginalType(T)) ++ " is missing health manager!");
                            }
                        };
                }
            }
        };
        pub const position = struct {
            pub const requirements = mangle.system.Signature{
                .fields = &.{
                    .{ .schema = .{ .duck = isHurtBox }, .name = "hitbox" },
                    .{ .schema = .{ .simple = alias.Position }, .name = "pos" },
                },
            };

            pub fn process(comptime T: type, value: *T, _: anytype) !void {
                value.hitbox.pos = value.pos;
            }
        };
    };
};

/// A type which will apply damage.
/// A hitbox of tag A will be applied to a Hurtbox of tag A
pub fn Hitbox(comptime t: []const Tag) type {
    return struct {
        pos: rl.Vector2 = .zero(),
        radius: f32,
        damage: f32 = 0,
        comptime isHitBox: bool = true,

        pub const tags: []const Tag = t;
        pub fn collides(hit: @This(), hurt: anytype) bool {
            if (comptime !overlaps(@This(), @TypeOf(hurt)))
                return false;

            return border.checkCollisionCircles(hit.pos, hit.radius, hurt.pos, hurt.radius);
        }
    };
}

/// A type which will have damage applied to it.
/// A hitbox of tag A will be applied to a Hurtbox of tag A
pub fn Hurtbox(comptime t: []const Tag) type {
    return struct {
        pos: rl.Vector2 = .zero(),
        radius: f32,
        comptime isHurtBox: bool = true,

        pub const tags: []const Tag = t;
        pub fn collides(hit: @This(), hurt: anytype) bool {
            if (comptime !overlaps(@This(), @TypeOf(hurt)))
                return false;

            return border.checkCollisionCircles(hit.pos, hit.radius, hurt.pos, hurt.radius);
        }
    };
}

pub fn isHitBox(comptime T: type) bool {
    const info = switch (@typeInfo(T)) {
        .@"struct" => |i| i,
        else => return false,
    };
    if (@hasField(T, "isHitBox")) {
        inline for (info.field_names, info.field_types, info.field_attrs) |name, U, attr| {
            if (comptime std.mem.eql(u8, name, "isHitBox")) {
                if (U == bool)
                    return attr.defaultValue(bool).?
                else
                    return false;
            }
        }
    }
    return false;
}

pub fn isHurtBox(comptime T: type) bool {
    const info = switch (@typeInfo(T)) {
        .@"struct" => |i| i,
        else => return false,
    };
    if (@hasField(T, "isHurtBox")) {
        inline for (info.field_names, info.field_types, info.field_attrs) |name, U, attr| {
            if (comptime std.mem.eql(u8, name, "isHurtBox")) {
                if (U == bool)
                    return attr.defaultValue(bool).?
                else
                    return false;
            }
        }
    }
    return false;
}

pub fn overlaps(comptime T: type, comptime U: type) bool {
    for (T.tags) |tag| {
        for (U.tags) |other| {
            if (tag == other) return true;
        }
    }
    return false;
}
