test "register class" {
    const core = @import("core");
    const godot = @import("godot");
    const Test = struct {
        const Self = @This();
        pub const Parent = godot.Node2D;
        base: *Parent,
        hi: i32,

        pub fn init(self: *Self) void {
            _ = self;
        }

        pub fn derp() void {
        }
    };

    core.api.registerClass(Test);
    core.api.registerMethod(@TypeOf(Test.init), "Test", "init", Test.init);
    core.api.registerMethod(@TypeOf(Test.derp), "Test", "derp", Test.derp);
}
