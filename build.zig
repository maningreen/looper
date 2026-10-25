const std = @import("std");

const Dependency = struct {
    name: []const u8,
    modules: ?[]const Module = null,

    const Module = struct {
        name: []const u8,
        importName: ?[]const u8 = null,
    };
};

const dependencies: []const Dependency = &.{
    Dependency{ .name = "mangle" },
    Dependency{
        .name = "raylib_zig",
        .modules = &.{
            .{ .name = "raygui" },
            .{ .name = "raylib" },
        },
    },
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("game", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });

    for (dependencies) |dependency| {
        const dep = b.dependency(dependency.name, .{ .target = target, .optimize = optimize });

        for (dependency.modules orelse &.{
            Dependency.Module{ .name = dependency.name },
        }) |requestedModule| {
            const searchName = requestedModule.name;
            const importName = requestedModule.importName orelse searchName;

            const module = dep.module(searchName);
            mod.addImport(importName, module);
        }
    }

    const exe = b.addExecutable(.{
        .name = "game",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "game", .module = mod },
            },
        }),
    });

    b.installArtifact(exe);

    const runStep = b.step("run", "Run the app");

    const runCmd = b.addRunArtifact(exe);
    runStep.dependOn(&runCmd.step);

    const check = b.step("check", "check if the app compiles");
    check.dependOn(&exe.step);
}
