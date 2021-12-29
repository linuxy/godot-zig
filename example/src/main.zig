const std = @import("std");
const core = @import("core");
const godot = @import("godot");

pub const log_level: std.log.Level = .warn;

pub const Test = struct {
    const Self = @This();

    pub const Parent = godot.Node2D;
    base: *Parent,
    hi: i32,
    pub fn init(self: *Self) void {
        _ = self;
        std.log.info("init()", .{});
    }
    pub fn derp() void {
    }
};

export fn godot_nativescript_init(p_handle: *anyopaque) void {
    std.log.info("godot_nativescript_init()", .{});
    core.api.initNative(p_handle);
    core.api.registerClass(Test);
    core.api.registerMethod(@TypeOf(Test.init), "Test", "init", Test.init);
    core.api.registerMethod(@TypeOf(Test.derp), "Test", "derp", Test.derp);
}

export fn godot_gdnative_init(o: *core.c.godot_gdnative_init_options) void {
    std.log.info("godot_gdnative_init()", .{});
    core.api.initCore(o);
}

export fn godot_gdnative_terminate(o: *core.c.godot_gdnative_terminate_options) void {
    std.log.info("godot_gdnative_terminate()", .{});
    core.api.native = undefined;
    core.api = undefined;
    _ = o;
}