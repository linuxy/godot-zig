const std = @import("std");
const Builder = @import("std").build.Builder;
const Version = @import("std").build.Version;

fn getRelativePath() []const u8 {
    comptime var src: std.builtin.SourceLocation = @src();
    return std.fs.path.dirname(src.file).? ++ std.fs.path.sep_str;
}

pub const godot = std.build.Pkg{ .name = "godot", .path = std.build.FileSource{ .path = getRelativePath() ++ "godot/index.zig" } };
pub const core = std.build.Pkg{ .name = "core", .path = std.build.FileSource{ .path = getRelativePath() ++ "godot/core/index.zig" } };

pub fn build(builder: *Builder) void {

    var exe = builder.addSharedLibrary("example", "example/src/main.zig", .{ .unversioned = {} });
    exe.setBuildMode(builder.standardReleaseOptions());
    exe.install();
    exe.addIncludeDir("./godot-headers/");
    exe.addPackage(core);
    exe.addPackage(godot);
    exe.linkSystemLibrary("c");

    builder.default_step.dependOn(&exe.step);
    builder.installArtifact(exe);

    const test_step = builder.step("test", "Test");
    const build_test = builder.addTest("godot/core/tests.zig");
    build_test.linkSystemLibrary("c");
    build_test.addIncludeDir("./godot-headers/");
    build_test.addPackage(core);
    build_test.addPackage(godot);
    test_step.dependOn(&build_test.step);
}