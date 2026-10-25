const std = @import("std");
const Io = std.Io;

const mangle = @import("mangle");
const raylib = @import("raylib");
const raygui = @import("raygui");

const accelerate = @import("accelerate.zig");
const input = @import("input.zig");
const render = @import("render.zig");
const alias = @import("alias.zig");
const physics = @import("physics.zig");
const camera = @import("camera.zig");
const time = @import("time.zig");
const dash = @import("dash.zig");
const border = @import("border.zig");

const VectorMap = @import("player/vectormap.zig");
const particle = @import("player/particle.zig");

const Player = @This();

comptime accelerator: accelerate.Manager = .{
    .table = .{
        .accelerate = getAccel,
        .onAccelerate = spawnParticles,
    },
},
comptime player: PlayerFlag = .{},
comptime renderPlayer: render.player.RenderFlag = .{},
comptime friction: alias.Friction = .{},

color: raylib.Color = raylib.Color.yellow,
vectorMap: VectorMap = .{ .left = .s, .right = .f, .up = .e, .down = .d },
position: alias.Position = mangle.alias(alias.Position, raylib.Vector2.init(border.defaultLength / 2, border.defaultLength / 2)),
velocity: alias.Velocity = mangle.alias(alias.Velocity, raylib.Vector2.zero()),
speed: alias.Speed = mangle.alias(alias.Speed, 1250),
dashControl: alias.Speed = mangle.alias(alias.Speed, 2000),

cameraFollow: camera.Follow = mangle.alias(camera.Follow, true),
keybinds: mangle.Compose(Bindings) = .{},

dashManager: dash.Manager = .{},
particleManager: particle.Manager = .{ .time = .{ .elapsed = 0 } },
resource: Resource = .{},

pub const default = Player{};
pub const PlayerFlag = struct {};

const Resource = struct {
    time: time.Elapsed = .{ .elapsed = 0 },
    offset: f32 = 10,

    /// will only return [0..3]
    fn getCount(self: Resource) u2 {
        return @trunc(@min(3, self.time.elapsed));
    }

    fn canUse(self: Resource) bool {
        return self.time.elapsed >= 1;
    }

    fn use(self: *Resource) bool {
        if (self.time.elapsed >= 1) {
            self.time.elapsed -= 1;
            return true;
        }
        return false;
    }
};

const Bindings = struct {
    keys: [2]input.Binding = .{
        .{ .key = .space },
        .{ .key = .left },
    },
    comptime callbacks: [2]input.Callback = [_]input.Callback{
        callChild(null, .beginDash, .systemFunction, null),
        callChild(null, .fire, .systemFunction, .{ .set = input.Error, .@"error" = .KeymapError }),
    },
};

pub fn init(gpa: std.mem.Allocator, io: std.Io) !Player {
    const vectormap = VectorMap.fromFile(gpa, io, null) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        else => VectorMap{},
    };
    return Player{
        .vectorMap = vectormap,
    };
}

pub fn deinit(comptime T: type, value: *T, info: anytype) void {
    const keymap: VectorMap = mangle.flags.originalType(value.vectorMap);
    const file = std.Io.Dir.cwd().createFile(info.io, VectorMap.parse.localPath, .{}) catch return;
    var writeBuf: [128]u8 = undefined;
    var writer = file.writer(info.io, writeBuf[0..]);
    std.zon.stringify.serialize(VectorMap.parse.to(keymap), .{}, &writer.interface) catch return;
    writer.flush() catch return;
}

fn getAccel(comptime T: type, player: *T, info: anytype) raylib.Vector2 {
    const acc: raylib.Vector2 = player.vectorMap.getInput();
    if (!player.dashManager.isDashing) {
        return getInputAccel(T, player, info);
    } else {
        return if (acc.x == 0 and acc.y == 0)
            player.velocity.normalize().scale(player.dashControl * info.delta)
        else
            acc.scale(player.dashControl * info.delta);
    }
}

fn getInputAccel(comptime T: type, player: *T, info: anytype) raylib.Vector2 {
    return player.vectorMap.getInput().scale(player.speed * info.delta);
}

fn spawnParticles(comptime T: type, player: *T, a: raylib.Vector2, info: anytype) accelerate.Manager.Error!void {
    const manager: *particle.Manager = &player.particleManager;
    var prt = manager.createParticle(info.extra.random) orelse return;
    prt.position.position = player.position;
    prt.color = prt.color.fade(0.8);
    const velocityScalar: f32 = a.length() / info.delta;
    const velocityAngle = std.math.atan2(-a.y / velocityScalar, -a.x / velocityScalar) + particle.ranges.randomRange(particle.ranges.getVelocityDeviation(velocityScalar), info.extra.random);
    prt.velocity.velocity = .{ .x = @cos(velocityAngle) * velocityScalar, .y = @sin(velocityAngle) * velocityScalar };
    info.appendDeferred(prt) catch return accelerate.Manager.Error.AccelerateError;
}

/// Doesn't do anything if `!value.resource.canUse()`
pub fn beginDash(comptime T: type, value: *T, info: anytype) void {
    if (!value.resource.canUse()) return;
    value.dashManager.beginDash();
    _ = value.resource.use();
    const accel = getInputAccel(T, value, info);
    if (accel.lengthSqr() > 1)
        value.velocity = accel;
}

pub fn fire(comptime T: type, value: *T, info: anytype) !void {
    _ = .{ value, info };
    std.log.debug("dsakfjasf", .{});
}

/// generates a callback
fn callChild(comptime childInfo: ?struct {
    T: type,
    field: @EnumLiteral(),
}, comptime function: @EnumLiteral(), comptime args: enum {
    selfPtr,
    selfConst,
    systemFunction,
}, comptime @"error": ?struct {
    set: type,
    @"error": @EnumLiteral(),
}) input.Callback {
    const T = if (childInfo) |v| v.T else Player;
    const f = comptime @field(T, @tagName(function));
    const isError = comptime if (@typeInfo(@TypeOf(f)).@"fn".return_type) |v| @typeInfo(v) == .error_union else false;
    const errorSet = comptime .{
        .set = if (@"error") |e|
            e.set
        else if (@typeInfo(@TypeOf(f)).@"fn".return_type) |r|
            if (@typeInfo(r) == .error_union)
                @typeInfo(r).error_union.error_set,
        .particular = if (@"error") |e| @field(e.set, @tagName(e.@"error")) else null,
    };
    const call = switch (args) {
        .selfConst => if (comptime isError)
            struct {
                fn call(comptime U: type, value: *U, _: anytype) errorSet.set!void {
                    if (childInfo) |info| {
                        f(@field(value, @tagName(info.field))) catch |e|
                            if (comptime errorSet.particular) |r|
                                return r
                            else
                                return e;
                    } else unreachable;
                }
            }
        else
            struct {
                fn call(comptime U: type, value: *U, _: anytype) errorSet.set!void {
                    if (childInfo) |info| {
                        f(@field(value, @tagName(info.field)));
                    } else unreachable;
                }
            },
        .selfPtr => if (comptime isError)
            struct {
                fn call(comptime U: type, value: *U, _: anytype) errorSet.set!void {
                    if (childInfo) |info| {
                        f(&@field(value, @tagName(info.field))) catch |e|
                            if (comptime errorSet.particular) |r|
                                return r
                            else
                                return e;
                    } else {
                        f(value) catch |e|
                            if (comptime errorSet.particular) |r|
                                return r
                            else
                                return e;
                    }
                }
            }
        else
            struct {
                fn call(comptime U: type, value: *U, _: anytype) errorSet.set!void {
                    if (childInfo) |info| {
                        f(&@field(value, @tagName(info.field)));
                    } else unreachable;
                }
            },
        .systemFunction => if (comptime isError)
            struct {
                fn call(comptime U: type, value: *U, reg: anytype) errorSet.set!void {
                    if (childInfo) |info| {
                        f(info.T, &@field(value, @tagName(info.field)), reg) catch |e|
                            if (comptime errorSet.particular) |r|
                                return r
                            else
                                return e;
                    } else {
                        f(U, value, reg) catch |e|
                            if (comptime errorSet.particular) |r|
                                return r
                            else
                                return e;
                    }
                }
            }
        else
            struct {
                fn call(comptime U: type, value: *U, reg: anytype) input.Error!void {
                    if (childInfo) |info| {
                        f(U, &@field(value, @tagName(info.field)), reg);
                    } else {
                        f(U, value, reg);
                    }
                }
            },
    };
    return call.call;
}
