const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const memory_mod = b.createModule(.{
        .root_source_file = b.path("src/memory.zig"),
        .target = target,
        .optimize = optimize,
    });

    const bus_mod = b.createModule(.{
        .root_source_file = b.path("src/bus.zig"),
        .target = target,
        .optimize = optimize,
    });

    bus_mod.addImport("memory", memory_mod);

    const exe = b.addExecutable(.{
        .name = "zmNES",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zmNES", .module = bus_mod },
            },
        }),
    });

    exe.root_module.addLibraryPath(
        b.path("deps/SDL3-3.4.14/lib/x64"),
    );

    exe.root_module.linkSystemLibrary(
        "SDL3",
        .{},
    );

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());
    run_cmd.addPassthruArgs();
}
