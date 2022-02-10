#include <gdnative/gdnative.h>
#include <stdlib.h>

#ifndef CHELPER_H
#define CHELPER_H
godot_gdnative_api_struct *zig_get_ext(godot_gdnative_api_struct **ext, int i);
void **zig_void_build_array(int length);
void zig_void_add_element(void **array, void *element, int index);
#endif
