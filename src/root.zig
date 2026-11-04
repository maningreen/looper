const std = @import("std");
const Io = std.Io;

pub const mangle = @import("mangle");
pub const raylib = @import("raylib");
pub const raygui = @import("raygui");
pub const zlua = @import("zlua");

pub const input = @import("input.zig");
pub const accelerate = @import("accelerate.zig");
pub const render = @import("render.zig");
pub const alias = @import("alias.zig");
pub const physics = @import("physics.zig");
pub const border = @import("border.zig");
pub const time = @import("time.zig");
pub const color = @import("color.zig");
pub const dash = @import("dash.zig");
pub const collision = @import("collision.zig");

pub const enemy = @import("enemy.zig");
pub const Laser = @import("laser.zig");

pub const Player = @import("player.zig");
pub const particle = @import("particle.zig");
pub const HealthManager = @import("health.zig");

pub const camera = @import("camera.zig");

pub const messages = @import("message.zig");

pub const Mod = @import("mod.zig");

pub const Extra = @import("Extra.zig");

pub const Registry = mangle.Registry(
    &.{
        Player,
        Player.Bullet,
        Player.Afterimage,
        Player.Node,
        particle.Square,
        enemy.Simple,
    },
    &.{
        input.system,

        accelerate.system,

        dash.system,

        render.circle,
        render.player.body,
        render.player.resources,
        render.square,
        render.health.system,
        Laser.system.render,
        Player.Node.systems.render,

        physics.velocity,
        physics.friction,
        physics.rotation.system,

        time.elapsed,
        time.maxLifetime,
        time.lifetime,

        color.fade.system,
        color.transparent.system,

        collision.systems.hitbox.position,
        collision.systems.hitbox.manage,
        collision.systems.hurtbox.position,
        collision.systems.hurtbox.manage,

        HealthManager.system,

        camera.system,
        border.system,
        Player.Node.systems.applyDamage.en,
        Player.Node.systems.applyDamage.node,
    },
    Extra,
);


pub fn preprocess(self: *Registry.RegistryInformation) void {
    camera.singlePass(self);
}

pub fn deinit(gpa: std.mem.Allocator) void {
    Player.Node.positions.deinit(gpa);
}
