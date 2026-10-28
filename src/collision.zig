const std = @import("std");
const rl = @import("raylib");

const mangle = @import("mangle");
const alias = @import("alias.zig");

pub const Tag = enum {
    player,
    enemy,
};

pub const systems = struct {
    pub const hitbox = struct {
        pub const requirements = mangle.system.Signature{
            .fields = &.{
                .{ .schema = .{ .duck = isHitBox }, .name = "hitbox" },
                .{ .schema = .{ .simple = alias.Position }, .name = "pos", .status = .optional },
            },
        };

        pub fn process(comptime T: type, value: *T, info: anytype) !void {
            if (@hasField(value, "pos")) {
                const emit: @FieldType(T, "hitbox") = .{
                    .rect = .{
                        .x = value.pos.x,
                        .y = value.pos.y,
                        .width = value.hitbox.rect.width,
                        .height = value.hitbox.rect.height,
                    },
                };
                try info.emit(emit);
            } else {
                try info.emit(value.hitbox);
            }
        }
    };

    pub const hurtbox = struct {
        /// An optional field for hurtbox qualification
        pub const Info = struct {
            /// Arguments: (comptime T: type, value: *T, hitbox: anytype, info: anytype)
            onCall: fn (comptime type, anytype, anytype, anytype) Error!void,
        };
        pub const Error = error{HurtboxError};

        pub const requirements = mangle.system.Signature{
            .fields = &.{
                .{ .schema = .{ .duck = isHitBox }, .name = "hitbox" },
                .{ .schema = .{ .simple = alias.Position }, .name = "pos", .status = .optional },
                .{ .schema = .{ .simple = Info }, .name = "info", .status = .optional },
            },
        };

        pub fn receive(comptime T: type, value: *T, event: anytype, info: anytype) !void {
            if (comptime isHitBox(@TypeOf(event))) {
                if (@hasField(value, "pos")) {
                    const emit: @FieldType(T, "hitbox") = .{
                        .rect = .{
                            .x = value.pos.x,
                            .y = value.pos.y,
                            .width = value.hitbox.rect.width,
                            .height = value.hitbox.rect.height,
                        },
                    };
                    try info.emit(emit);
                } else try info.emit(value.hitbox);

                if (@hasField(value, "info"))
                    try value.info.onCall(T, value, event, info);
            }
        }
    };
};

/// A type which will apply damage.
/// A hitbox of tag A will be applied to a Hurtbox of tag A
pub fn Hitbox(comptime tags: []const Tag) type {
    return struct {
        rect: rl.Rectangle,
        comptime tags: []const Tag = tags,
        comptime isHitBox: bool = true,

        pub fn collides(hit: @This(), hurt: anytype) bool {
            if (comptime !overlaps(@This(), @TypeOf(hurt)))
                return false;

            return hit.rect.checkCollision(hurt.rect);
        }
    };
}

/// A type which will have damage applied to it.
/// A hitbox of tag A will be applied to a Hurtbox of tag A
pub fn Hurtbox(comptime tags: []const Tag) type {
    return struct {
        rect: rl.Rectangle,
        comptime tags: []const Tag = tags,
        comptime isHurtBox: bool = true,

        pub fn collides(hit: @This(), hurt: anytype) bool {
            if (comptime !overlaps(@This(), @TypeOf(hurt)))
                return false;

            return hit.rect.checkCollision(hurt.rect);
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
            if (comptime std.mem.eql(U, name, "isHitBox")) {
                if (U == bool)
                    return attr.defaultValue(bool)
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
            if (comptime std.mem.eql(U, name, "isHurtBox")) {
                if (U == bool)
                    return attr.defaultValue(bool)
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
