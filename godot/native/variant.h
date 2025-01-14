#ifndef CGDNATIVE_VARIANT_H
#define CGDNATIVE_VARIANT_H

#include <gdnative/variant.h>
#include <stdlib.h>

godot_variant **zig_godot_variant_build_array(int);
void zig_godot_variant_add_element(godot_variant **, godot_variant *, int);

#endif
