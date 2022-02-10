const std = @import("std");
const core = @import("core");
const godot = @import("godot");
const Utf8View = @import("std").unicode.Utf8View;

pub const log_level: std.log.Level = .info;

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
        std.log.info("derp()", .{});
        var godot_string: core.c.godot_string = undefined;

        var zstr = u8ToWideString("hello from zig->godot_print()!");

        core.c.zig_godot_string_new_with_wide_string(
            core.api.core,
            &godot_string,
            zstr.ptr,
            zstr.len,
        );
        core.c.zig_godot_print(core.api.core, &godot_string);
    }
};

export fn godot_nativescript_init(p_handle: *anyopaque) void {
    std.log.info("godot_nativescript_init()", .{});
    core.api.initNative(p_handle);
    core.api.registerClass(Test);
    core.api.registerMethod(Test.derp, "Test", "derp");
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

pub fn u8ToWideString(string: [:0]const u8) GString {
    const allocator = std.heap.c_allocator;
    const result = allocator.alloc(core.c.wchar_t, string.len) catch unreachable;
    const result_ptr = @ptrCast([*c]core.c.wchar_t, @alignCast(@alignOf(*core.c.wchar_t), result));

    var ustr = Utf8View.init(string) catch unreachable;
    var it = ustr.iterator();
    var i: usize = 0;
    while (it.nextCodepoint()) |cp| {
        result_ptr[i] = @intCast(core.c.wchar_t, cp);
        i += 1;
    }
    return .{ .ptr = result_ptr, .len = @intCast(c_int, i) };
}

const GString = struct {
    ptr: [*c]core.c.wchar_t,
    len: c_int,
};