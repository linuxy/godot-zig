# godot-zig
Godot 3.4 GDNative bindings for Zig

builds against zig 0.9.0
## Building
```
$ git submodule update --init --recursive
$ python gen.py
$ zig build
```

## Setup
* Copy example.dll to your Godot project folder
* Follow these setups to create a .gdnlib pointing to example.dll and a .gdns file
https://docs.godotengine.org/en/stable/tutorials/plugins/gdnative/gdnative-c-example.html
