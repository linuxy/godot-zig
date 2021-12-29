pub usingnamespace @import("vector2.zig");
pub usingnamespace @import("rid.zig");
pub usingnamespace @import("transform_2d.zig");
pub usingnamespace @import("string.zig");

const TypeInfo = @import("builtin").TypeInfo;
const util = @import("util.zig");
pub const c = @import("c.zig");
const std = @import("std");
// const godot = @import("../index.zig");
const assert = std.debug.assert;

var memoryBuffer: [3000]u8 = undefined;

pub const Options = c.godot_gdnative_init_options;
pub const Handle = anyopaque;

const WrapperFn = ?fn(?*c.godot_object, ?*anyopaque, ?*anyopaque, c_int, ?[*]?[*]c.godot_variant) callconv(.C) c.godot_variant;
const CreateFn = ?fn(?*c.godot_object, ?*anyopaque) callconv(.C) ?*anyopaque;
const DestroyFn = ?fn(?*c.godot_object, ?*anyopaque, ?*anyopaque) callconv(.C) void;
const FreeFn = ?fn(?*anyopaque) void;
const ConstructorFn = ?fn() callconv(.C) ?*c.godot_object;

var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = general_purpose_allocator.allocator();

fn GodotWrapper(comptime T: type) type {
    return extern struct { 
        fn wrapped(obj: ?*c.godot_object, data: ?*anyopaque, userdata: ?*anyopaque, num: c_int, cargs: ?[*]?[*]c.godot_variant) callconv(.C) c.godot_variant {
            _ = data;
            _ = userdata;
            _ = obj;
            // TODO: use the result from the function call
            var result: c.godot_variant = undefined;
            // TODO: Figure out how to turn array into varargs while casting each
            // argument into the proper type for the function call
            // Refer to how godot_cpp does this.
            const Info = @typeInfo(T);
            const Args = Info.Fn.args;
            var args = cargs.?[0..@intCast(usize, num)];
            var func = @ptrCast(T, data);
            switch (Args.len) {
                0 => {
                    _ = func();
                },
                1 => {
                    // TODO: godot_variant can't directly be casted
                    // If the variant is an object use godot_nativescript_get_userdata
                    var arg0 = @ptrCast(Args[0].arg_type.?, @alignCast(@alignOf(Args[0].arg_type.?), args[0]));
                    _ = func(arg0);
                },
                2 => { 
                    var arg0 = @ptrCast(Args[0].arg_type, @alignCast(@alignOf(Args[0].arg_type), args[0]));
                    var arg1 = @ptrCast(Args[1].arg_type, @alignCast(@alignOf(Args[1].arg_type), args[1]));
                    _ = func(arg0, arg1);
                },
                3 => {
                    var arg0 = @ptrCast(Args[0].arg_type, @alignCast(@alignOf(Args[0].arg_type), args[0]));
                    var arg1 = @ptrCast(Args[1].arg_type, @alignCast(@alignOf(Args[1].arg_type), args[1]));
                    var arg2 = @ptrCast(Args[2].arg_type, @alignCast(@alignOf(Args[2].arg_type), args[2]));
                    _ = func(arg0, arg1, arg2);
                },
                4 => { 
                    var arg0 = @ptrCast(Args[0].arg_type, @alignCast(@alignOf(Args[0].arg_type), args[0]));
                    var arg1 = @ptrCast(Args[1].arg_type, @alignCast(@alignOf(Args[1].arg_type), args[1]));
                    var arg2 = @ptrCast(Args[2].arg_type, @alignCast(@alignOf(Args[2].arg_type), args[2]));
                    var arg3 = @ptrCast(Args[3].arg_type, @alignCast(@alignOf(Args[3].arg_type), args[3]));
                    _ = func(arg0, arg1, arg2, arg3);
                },
                5 => { 
                    var arg0 = @ptrCast(Args[0].arg_type, @alignCast(@alignOf(Args[0].arg_type), args[0]));
                    var arg1 = @ptrCast(Args[1].arg_type, @alignCast(@alignOf(Args[1].arg_type), args[1]));
                    var arg2 = @ptrCast(Args[2].arg_type, @alignCast(@alignOf(Args[2].arg_type), args[2]));
                    var arg3 = @ptrCast(Args[3].arg_type, @alignCast(@alignOf(Args[3].arg_type), args[3]));
                    var arg4 = @ptrCast(Args[4].arg_type, @alignCast(@alignOf(Args[4].arg_type), args[4]));
                    _ = func(arg0, arg1, arg2, arg3, arg4);
                },
                else => {}
            }
            return result;
        }
    };
}

fn GodotFns(comptime T: type) type {
    return struct {
        pub fn create(obj: ?*c.godot_object, data: ?*anyopaque) callconv(.C) ?*anyopaque {
            std.log.info("create?()", .{});
            _ = data;
            var t: *T = std.heap.c_allocator.create(T) catch std.os.abort();
            t.base = @ptrCast(*T.Parent, @alignCast(@alignOf(T.Parent), obj.?));
            std.log.info("init?()", .{});
            if (util.hasField(T, "init")) {
                t.init();
            }
            return @ptrCast(*anyopaque, t);
        }

        pub fn destroy(obj: ?*c.godot_object, method_data: ?*anyopaque, data: ?*anyopaque) callconv(.C) void {
            _ = method_data;
            _ = obj;
            std.log.info("destroy()", .{});
            std.heap.c_allocator.destroy(@ptrCast(*T, @alignCast(@alignOf(T), data.?)));
        }
    };
}

pub const GodotApi = struct {
    const Self = @This();
    const NativeApi = c.godot_gdnative_ext_nativescript_api_struct;
    const CoreApi = c.godot_gdnative_core_api_struct;
    heap: std.heap.FixedBufferAllocator,
    native: ?*NativeApi,
    core: ?*CoreApi, 
    handle: ?*Handle,

    fn new() Self {
        return Self {
            .heap = std.heap.FixedBufferAllocator.init(memoryBuffer[0..]),
            .native = null,
            .core = null,
            .handle = null
        };
    }

    fn getBaseClassName(comptime T: type) []const u8 {
        if (util.getField(T, "Parent")) |field| {
            return @typeName(@TypeOf(field));
        }
        return "";
    }

    fn getFns(comptime T: type) []T {
        comptime {
            const Info = @typeInfo(T);
            var num: usize = 0;
            // First get the number of functions so we can
            // define a const-sized array
            for (Info.Struct.defs) |def| {
                if (def.is_pub) {
                    switch (def.data) {
                        TypeInfo.Definition.Data.Fn => |fndef| {
                            if (fndef.is_export) {
                                num += 1;
                            }
                        },
                        else => {},
                    }
                }
            }
            
            var result: [num]T = []T{} ** num;
            var i: usize = 0;
            for (Info.Struct.defs) |def| {
                if (def.is_pub) {
                    switch (def.data) {
                        TypeInfo.Definition.Data.Fn => |fndef| {
                            if (fndef.is_export) {
                                result[i].t = @TypeOf(@field(T, def.name));
                                result[i].ptr = @ptrToInt(@field(T, def.name));
                                result[i].name = def.name;
                                i += 1;
                            }
                        },
                        else => {}
                    }
                }
            }

            return result;
        } 
    }

    /// This needs to be called in `export godot_nativescript_init(handle: *anyopaque) void`
    pub fn initNative(self: *Self, handle: *Handle) void {
        self.handle = handle;
    }

    /// This needs to be called in `export godot_gdnative_init(options: *godot.Options) void`
    pub fn initCore(self: *Self, options: *Options) void {
        _ = self;
        api.core = unsafePtrCast(*CoreApi, options.api_struct);
        var i: usize = 0;
        while (i < api.core.?.num_extensions) {
            switch (api.core.?.extensions[i].*.type) {
                c.GDNATIVE_EXT_NATIVESCRIPT => {
                    var nativeApi = unsafePtrCast(*c.godot_gdnative_ext_nativescript_api_struct, api.core.?.extensions[i]);
                    api.native = nativeApi;
                },
                    else => {}
            }
            i += 1;
        }
    }

    pub fn getMethod(self: *Self, classname: [*]const u8, method: [*]const u8) ?*c.godot_method_bind {
        if (self.core) |core| {
            return core.godot_method_bind_get_method.?(classname, method);
        } else {
            std.log.warn("Core API hasn't been initialized!\n", .{});
        }
        return null;
    }

    pub fn getConstructor(self: *Self, classname: [*]const u8) ?ConstructorFn {
        if (self.core) |core| {
            var result = core.godot_get_class_constructor.?(classname);
            return @ptrCast(ConstructorFn, result);
        } else {
            std.log.warn("Core API hasn't been initialized!\n", .{});
        }
        return null;
    }

    pub fn newObj(self: *Self, comptime T: type, constructor: ConstructorFn) *T {
        _ = self;
        return @ptrCast(*T, @alignCast(@alignOf(*T), constructor()));
    }

    pub fn registerClass(self: *Self, comptime T: type) void {
        const Name = @typeName(T);
        const BaseName = Self.getBaseClassName(T);
        
        // TODO: Tell user that we ran into an error before aborting
        var name = std.cstr.addNullByte(gpa, Name) catch std.os.abort();
        defer gpa.free(name);
        var base = std.cstr.addNullByte(gpa, BaseName) catch std.os.abort();
        defer gpa.free(base);
        
        const Fns = GodotFns(T);

        var cfn: CreateFn = Fns.create;
        var createFunc = c.godot_instance_create_func { 
            .create_func = cfn, 
            .method_data = null, 
            .free_func = null
        };
        std.log.info("createFunc: {s}", .{createFunc.create_func});
        var dfn: DestroyFn = Fns.destroy;
        var destroyFunc = c.godot_instance_destroy_func {
            .destroy_func = dfn,
            .method_data = null,
            .free_func = null,
        };
        std.log.info("destroyFunc: {s}", .{destroyFunc.destroy_func});
        if (self.native) |native| {
            std.log.info("registerClass() handle: {*} name: {*} base: {*}", .{self.handle, name.ptr, base.ptr});
            native.godot_nativescript_register_class.?(self.handle, name.ptr, base.ptr, createFunc, destroyFunc);
        } else {
            std.log.warn("NativeScript API hasn't been initialized!\n", .{});
            std.os.abort();
        }

        // TODO: Register every function that is `pub` to Godot
        // TODO: Look at T.Inspector const and register all fields with Godot Inspector
    }

    pub fn registerMethod(self: *Self, comptime F: type, classname: [*]const u8, methodname: [*]const u8, func: anytype) void {
        var attributes = c.godot_method_attributes {
            // TODO: Support different method attributes
            .rpc_type = c.GODOT_METHOD_RPC_MODE_DISABLED,
        };
        
        // create a wrapper function
        const Wrapper = GodotWrapper(F);
        var wrapped: WrapperFn = Wrapper.wrapped;

        var mfn = unsafePtrCast(*anyopaque, &func);
        var data = c.godot_instance_method {
            .method = @ptrCast(WrapperFn, &wrapped),
            .method_data = mfn, 
            .free_func = null,
        };

        if (self.native) |native| {
            std.log.info("registerMethod() handle: {*} func: {s}", .{self.handle, data});
            native.godot_nativescript_register_method.?(self.handle, classname, methodname, attributes, data);
        } else {
            std.log.warn("NativeScript API hasn't been initialized!\n", .{});
            std.os.abort();
        }
    }
};

pub var api: GodotApi = GodotApi.new();

pub fn GodotObject(comptime S: type) type {
    api.registerClass(S);
    return S;
}

pub fn unsafePtrCast(comptime T: type, ptr: anytype) T {
    comptime {
        assert(@sizeOf(T) == @sizeOf(@TypeOf(ptr)));
    }
    var result: T = undefined;
    @memcpy(@ptrCast([*]u8, &result), @ptrCast([*]const u8, &ptr), @sizeOf(T));
    return result;
}