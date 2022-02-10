#include <gdnative/gdnative.h>
#include <gdnative_api_struct.gen.h>
#include <nativescript/godot_nativescript.h>
#include <stdio.h>
#include <stdlib.h>

// This is a gateway function for the create method.
void *zig_gateway_create_func(godot_object *obj, void *method_data) {
	// printf("zig: c.zig_create_func_zig()\n");
	void *ret;
	void *zig_create_func(godot_object *, void *);
	ret = zig_create_func(obj, method_data);  // Execute our Zig function.
	return ret;
}

// This is a gateway function for the destroy method.
void *zig_gateway_destroy_func(godot_object *obj, void *method_data,
			       void *user_data) {
	// printf("zig: c.zig_destroy_func_zig()\n");
	void *ret;
	void *zig_destroy_func(godot_object *, void *, void *);
	ret = zig_destroy_func(obj, method_data,
			      user_data);  // Execute our Zig function.
	return ret;
}

// This is a gateway function for the free method.
void *zig_gateway_free_func(void *method_data) {
	// printf("zig: c.zig_free_func_zig()\n");
	void *ret;
	void *zig_free_func(void *);
	ret = zig_free_func(method_data);  // Execute our Zig function.
	return ret;
}

// This is a gateway function for the method
// GDCALLINGCONV godot_variant (*method)(godot_object *, void *, void *, int,
// godot_variant **);
// func zig_method_func(godotObject *c.godot_object, methodData unsafe.Pointer,
// userData unsafe.Pointer, numArgs c.uint, args **c.godot_variant) {
godot_variant zig_gateway_method_func(godot_object *obj, void *method_data,
				      void *user_data, int num_args,
				      godot_variant **args) {
	// printf("zig: c.zig_method_func_zig()\n");
	// printf("zig: Number of arguments: %d\n", num_args);
	godot_variant ret;
	godot_variant zig_method_func(godot_object *, void *, void *, int,
				     godot_variant **);
	ret = zig_method_func(obj, method_data, user_data, num_args,
			     args);  // Execute our Zig function.

	return ret;
}

// This is a gateway function for the set property method.
// GDCALLINGCONV void (*set_func)(godot_object *, void *, void *, godot_variant
// *);
void zig_gateway_property_set_func(godot_object *obj, void *method_data,
				   void *user_data, godot_variant *property) {
	// printf("zig: c.zig_set_property_func()\n");
	void zig_set_property_func(godot_object *, void *, void *,
				  godot_variant *);
	zig_set_property_func(obj, method_data, user_data,
			     property);  // Execute our Zig function.
}

// This is a gateway function for the get property method.
// GDCALLINGCONV godot_variant (*get_func)(godot_object *, void *, void *);
godot_variant zig_gateway_property_get_func(godot_object *obj,
					    void *method_data,
					    void *user_data) {
	// printf("zig: c.zig_get_property_func()\n");
	godot_variant ret;
	godot_variant zig_get_property_func(godot_object *, void *, void *);
	ret = zig_get_property_func(obj, method_data,
				   user_data);  // Execute our Zig function.

	return ret;
}

godot_signal_argument **zig_godot_signal_argument_build_array(int length) {
	godot_signal_argument **arr =
	    malloc(sizeof(godot_signal_argument *) * length);

	return arr;
}

void zig_godot_signal_argument_add_element(godot_signal_argument **array,
					  godot_signal_argument *element,
					  int index) {
	array[index] = element;
}
