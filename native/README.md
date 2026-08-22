# Native JSBSim extension

This directory contains the optional Godot GDExtension that embeds JSBSim. The
simulator's existing simple flight model remains available when this extension
is absent.

Dependencies are pinned Git submodules under `third_party/`:

- `godot-cpp`: Godot 4.7 C++ bindings
- `jsbsim`: JSBSim v1.3.1

## macOS debug build

```sh
cmake -S native -B native/build -G Ninja \
  -DCMAKE_BUILD_TYPE=Debug \
  -DGODOTCPP_TARGET=template_debug
cmake --build native/build --target rcflight_jsbsim
```

The output is written to `native/bin/librcflight_jsbsim.dylib`. Windows and
macOS release binaries must be built separately before cross-platform export.

Do not commit `native/build` or compiled binaries.
