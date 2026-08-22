#include "jsbsim_bridge.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

using namespace godot;

void initialize_rcflight_jsbsim(ModuleInitializationLevel level) {
  if (level != MODULE_INITIALIZATION_LEVEL_SCENE) return;
  GDREGISTER_CLASS(JsbsimBridge);
}

void uninitialize_rcflight_jsbsim(ModuleInitializationLevel level) {
  if (level != MODULE_INITIALIZATION_LEVEL_SCENE) return;
}

extern "C" {
GDExtensionBool GDE_EXPORT rcflight_jsbsim_init(
    GDExtensionInterfaceGetProcAddress get_proc_address,
    const GDExtensionClassLibraryPtr library,
    GDExtensionInitialization *initialization) {
  GDExtensionBinding::InitObject init(get_proc_address, library, initialization);
  init.register_initializer(initialize_rcflight_jsbsim);
  init.register_terminator(uninitialize_rcflight_jsbsim);
  init.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);
  return init.init();
}
}
