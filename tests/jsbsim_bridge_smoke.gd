extends SceneTree

func _init() -> void:
	if not ClassDB.class_exists(&"JsbsimBridge"):
		push_error("JsbsimBridge GDExtension class is unavailable")
		quit(1)
		return

	var bridge = JsbsimBridge.new()
	var data_root := ProjectSettings.globalize_path("res://native/third_party/jsbsim")
	if not bridge.initialize(data_root, "c172p", 1.0 / 120.0):
		push_error(bridge.last_error())
		quit(2)
		return

	var result: Dictionary = bridge.step(0.0, 0.0, 0.0, 0.0)
	if not result.get("ready", false):
		push_error("JSBSim stopped during its first simulation step")
		quit(3)
		return

	print("JSBSIM_BRIDGE_PASS airspeed_mps=", result.get("airspeed_mps", -1.0))
	quit(0)
