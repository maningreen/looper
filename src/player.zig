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

const parse = @import("player/parse.zig");

pub const VectorMap = @import("player/vectormap.zig");
pub const Resource = @import("player/resource.zig").Manager;
pub const particle = @import("player/particle.zig");

pub const Bullet = @import("player/bullet.zig");
pub const Afterimage = @import("player/afterimage.zig");

const Player = @This();

comptime accelerator: accelerate.Manager = .{
    .table = .{
        .accelerate = getAccel,
        .onAccelerate = manageAccelerate,
    },
},
comptime player: PlayerFlag = .{},
comptime renderPlayer: render.player.body.RenderFlag = .{},
comptime friction: alias.Friction = .{},
comptime afterimageTime: f32 = 0.5 / 4.0,

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
resource: Resource = .{
    .count = 4,
    .rate = 0.75,
},

pub const default = Player{};
pub const PlayerFlag = struct {};

const Bindings = struct {
    const bindCount: usize = 2;

    keys: [bindCount]input.Binding = .{
        .{ .key = .space },
        .{ .mouse = .left },
    },
    comptime callbacks: [bindCount]input.Callback = [_]input.Callback{
        callChild(null, .beginDash, .systemFunction, null),
        callChild(null, .fire, .systemFunction, .{ .set = input.Error, .@"error" = .KeymapError }),
    },
};

pub fn init(gpa: std.mem.Allocator, io: std.Io) !Player {
    const storage = try parse.Storage.fromFile(io, gpa, null);
    if (storage) |stored| {
        const map, const keybinds = stored.to();
        return Player{
            .vectorMap = map,
            .keybinds = .{
                .keys = keybinds,
            },
        };
    } else return Player{};
}

pub fn deinit(comptime T: type, value: *T, info: anytype) void {
    const file = std.Io.Dir.cwd().createFile(info.io, parse.localPath, .{}) catch return;
    defer file.close(info.io);
    var writeBuf: [128]u8 = undefined;
    var writer = file.writer(info.io, writeBuf[0..]);
    writer.interface.print("{}", .{parse.Storage.from(mangle.flags.originalType(value.vectorMap), value.keybinds_keys)}) catch return;
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
    prt.color = prt.color.fade(0.7);
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

pub fn fire(comptime T: type, player: *T, info: anytype) !void {
    if (player.resource.canUse()) {
        std.debug.assert(player.resource.use());
        const target = info.extra.mousePosition;
        const bullet = Bullet.spawn(player.position, target);
        try info.appendDeferred(bullet);
    }
}

pub fn afterimage(player: anytype, info: anytype) ?Afterimage {
    if (@mod(player.dashManager.time.elapsed, player.afterimageTime) < info.delta and player.dashManager.isDashing) {
        return Afterimage{
            .col = raylib.Color.yellow.fade(0.8),
            .position = .{ .position = player.position },
            .angle = .{ .theta = std.math.atan2(info.extra.mousePosition.y - player.position.y, info.extra.mousePosition.x - player.position.x) },
        };
    } else return null;
}

pub fn manageAccelerate(comptime T: type, player: *T, accel: raylib.Vector2, info: anytype) accelerate.Manager.Error!void {
    try spawnParticles(T, player, accel, info);
    if(afterimage(player, info)) |after| {
        info.appendDeferred(after) catch return accelerate.Manager.Error.AccelerateError;
    } 
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
        .particular = if (@"error") |e|
            @field(e.set, @tagName(e.@"error"))
        else
            null,
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
                            return if (comptime errorSet.particular) |r|
                                r
                            else
                                e;
                    } else {
                        f(U, value, reg) catch |e|
                            return if (comptime @as(?errorSet.set, errorSet.particular)) |r|
                                r
                            else
                                e;
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
