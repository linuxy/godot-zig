import json
import os
import re

OutputDir = 'godot/'
DefaultApiPath = 'godot-headers/api.json'
GodotFile = 'index.zig'
ConstantsFile = 'global_constants.zig'

files = []

def split_on_uppercase(s, keep_contiguous=False):
    string_length = len(s)
    is_lower_around = (lambda: s[i-1].islower() or 
                       string_length > (i + 1) and s[i + 1].islower())

    start = 0
    parts = []
    for i in range(1, string_length):
        if s[i].isupper() and (not keep_contiguous or is_lower_around()):
            parts.append(s[start: i])
            start = i
    parts.append(s[start:])

    return parts

def name_to_zig_constant(name):
    parts = name.lower().split('_')
    for i, p in enumerate(parts):
        parts[i] = p[0].upper() + p[1:]
    return ''.join(parts)

def name_to_zig_file(name):
    parts = split_on_uppercase(name, True)
    for i, p in enumerate(parts):
        parts[i] = parts[i].lower()
    return '_'.join(parts)

def name_to_zig_var(name):
    parts = name.lower().split('_')
    for i, p in enumerate(parts):
        if i == 0: continue
        parts[i] = p[0].upper() + p[1:]
    return escape_zig_func_name(''.join(parts))

def generate_api(api):
    if not os.path.exists(OutputDir):
        os.makedirs(OutputDir)
    with open(api) as f:
        tree = json.load(f)
        for item in tree:
            name = item['name']
            if name == 'GlobalConstants':
                constants = generate_constants(item)
                c = open(OutputDir + ConstantsFile, 'w+')
                c.write(constants)
            else:
                obj, name = generate_obj(item)
                c = open(OutputDir + name + '.zig', 'w+')
                c.write(obj)
    imports = []
    for f in files:
        if len(f.strip()) > 0:
            imports.append('pub usingnamespace @import("{0}.zig");'.format(f))
    imports.append('pub usingnamespace @import("core/index.zig");')
    with open(OutputDir + GodotFile, 'w+') as f:
        f.write('\n'.join(imports))


def generate_constants(item, join=True):
    source = []
    for c in item['constants']:
        source.append(generate_zig_constant(c, item['constants'][c]))
    if join:
        return '\n'.join(source)
    else:
        source


def generate_zig_constant(name, value, pub='pub'):
    return '{0} const {1} = {2};'.format(pub, name_to_zig_constant(name), value)


"""
			{
				"name": "set_position",
				"return_type": "void",
				"is_editor": false,
				"is_noscript": false,
				"is_const": false,
				"is_reverse": false,
				"is_virtual": false,
				"has_varargs": false,
				"is_from_script": false,
				"arguments": [
					{
						"name": "position",
						"type": "Vector2",
						"has_default_value": false,
						"default_value": ""
					}
				]
			},
            """

def type_to_zig_type(name):
    if re.match('^enum', name):
        return ('i32', False)
    if name == 'bool':
        return (name, False)
    if name == 'int':
        return ('i32', False)
    if name == 'float':
        return ('f32', False)
    return ('void', False) if name == 'void' else ('godot.{0}'.format(name), True)

def method_name_to_ptr_name(name):
    return name + 'Ptr'

def escape_zig_func_name(name):
    if name == 'var':
        return 'var_'
    if name == 'section':
        return 'section_'
    if name == 'error':
        return 'error_'
    if name == 'align':
        return 'align_'
    if name == 'use':
        return 'use_'
    if name == 'resume':
        return 'resume_'
    if name == 'cancel':
        return 'cancel_'
    if name == 'export':
        return 'export_'
    if name == 'type':
        return '@"type"'
    if name == 'bool':
        return '@"bool"'
    if name == 'c':
        return '_c'
    if name == 'args':
        return '_args'
    if name == 'new':
        return '_new'
    return name

def escape_zig_name(name):
    if name == 'var':
        return 'var_'
    if name == 'section':
        return 'section_'
    if name == 'error':
        return 'error_'
    if name == 'align':
        return 'align_'
    if name == 'use':
        return 'use_'
    if name == 'resume':
        return 'resume_'
    if name == 'cancel':
        return 'cancel_'
    if name == 'export':
        return 'export_'
    if name == 'type':
        return '@"type"'
    if name == 'bool':
        return '@"bool"'
    if name == 'c':
        return '_c'
    if name == 'args':
        return '_args'
    if name == 'new':
        return '_new'
    if name == 'draw':
        return '_draw'
    if name == 'index':
        return '_index'
    if name == 'enum':
        return '@"enum"'
    return name

def generate_method(class_name, method, has_base=True):
    source = []
    method_name = name_to_zig_var(method['name'])
    return_type, is_struct = type_to_zig_type(method['return_type'])
    source.append('pub fn {0}(self: *const Self'.format(method_name))
    args_len = len(method['arguments'])
    for i, arg in enumerate(method['arguments']):
        if i + 1 <= args_len:
            source.append(', ')
        tname, is_struct = type_to_zig_type(arg['type'])
        struct = '*const ' if is_struct else ''
        source.append('{0}: {1} {2}'.format(escape_zig_name(arg['name']), struct, tname))
    ptr_name = method_name_to_ptr_name(class_name + method_name)
    source.append(') {0} {{'.format(return_type))
    source.append('''
    if ({0} == null) {{
        {0} = godot.api.getMethod("{1}", "{2}");
    }}
    '''.format(ptr_name, class_name, method['name']))
    source.append('_ = self;\n')
    source.append('var _result: ?*anyopaque = null;\n')
    if args_len > 0:
        for i, arg in enumerate(method['arguments']):
            _, is_struct = type_to_zig_type(arg['type'])
            struct = '' if is_struct else '*'
            source.append('    var _arg{0}: ?*const anyopaque = @ptrCast(*const anyopaque, {1}{2});\n'.format(i, struct, escape_zig_name(arg['name'])))
        source.append('    var args: [{0}]?*const anyopaque = []?*const anyopaque {{'.format(args_len))
        for i, arg in enumerate(method['arguments']):
            source.append('_arg{0},'.format(i))
        source.append('''};\n    var cargs: ?*?*const anyopaque = &args[0];\n''')
    else:
        source.append('    var cargs: ?*?*const anyopaque = null;\n')
    base = '@ptrCast(*c.godot_object, @alignCast(@alignOf(*c.godot_object), self.base))' if has_base else 'null'
    source.append('    _ = godot.api.core.?.godot_method_bind_ptrcall.?({0}, {1}, cargs, _result);\n'.format(ptr_name, base))
    if return_type != 'void':
        source.append('    return @ptrCast(*{0}, @alignCast(@alignOf(&{0}), _result)).*;\n'.format(return_type))
    source.append('}')
    return ''.join(source)

def generate_obj(item):
    source = []
    file_name = name_to_zig_file(item['name'])
    files.append(file_name)
    name = item['name']
    source.append('const godot = @import("index.zig");')
    source.append('const c = @import("core/c.zig");')
    source.append('const as = @import("core/util.zig").as;')
    if item['base_class'] != '':
        source.append('const {0} = @import("{1}.zig").{0};'.format(item['base_class'], name_to_zig_file(item['base_class'])))
    source.append('\n// Function pointers \n')
    for method in item['methods']:
        if method['is_virtual']:
            continue
        source.append('var {0}: ?*c.godot_method_bind = null;'.format(method_name_to_ptr_name(name + name_to_zig_var(method['name']))))
    source.append('var {0}: ?fn() ?*c.godot_object = null;'.format(method_name_to_ptr_name(name + 'constructor')))
    source.append('\n//End function pointers\npub const {0} = struct {{'.format(name))
    if item['base_class'] != '':
        source.append('const Parent = {0};'.format(item['base_class']))
    source.append('const Self = @This();')
    # after constants
    if item['base_class'] != '':
        source.append('base: *Parent,')
    source.append('tmp: u8,')
    source.append('pub fn new() *Self {')
    source.append('if ({0} == null) {{ {0} = godot.api.getConstructor("{1}"); }}'.format(method_name_to_ptr_name(name + 'constructor'), name))
    source.append('return godot.api.newObj(Self, {0}.?);'.format(method_name_to_ptr_name(name + 'constructor')))
    source.append('}')
    source.append('''pub fn destroy(self: *Self) void {
        _ = godot.api.core.?.godot_object_destroy.?(@ptrCast(*c.godot_object, self));
    }''')
    for method in item['methods']:
        if method['is_virtual']:
            continue
        source.append(generate_method(name, method, item['base_class'] != ''))
    for k in item:
        pass
    source.append('};')
    return '\n'.join(source), file_name


generate_api(DefaultApiPath)
