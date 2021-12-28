const Vector2 = @import("vector2.zig").Vector2;

pub const Transform2D = struct {
    const Self = @This();
    elements: [3]Vector2,
};