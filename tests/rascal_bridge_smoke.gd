extends SceneTree

func _init() -> void:
	if not ClassDB.class_exists(&"JsbsimBridge"):
		_fail("JsbsimBridge GDExtension class is unavailable")
		return
	var bridge = ClassDB.instantiate(&"JsbsimBridge")
	var data_root := ProjectSettings.globalize_path("res://assets/jsbsim")
	if not bridge.initialize(data_root, "Rascal", 1.0 / 120.0):
		_fail(bridge.last_error())
		return
	if not bridge.reset(20.0, 18.0, 0.0):
		_fail(bridge.last_error())
		return
	var initial: Dictionary = bridge.state()
	var result: Dictionary
	for step_index in 240:
		result = bridge.step(0.65, 0.0, 0.0, 0.0)
	if not bool(result.get("ready", false)):
		_fail(bridge.last_error())
		return
	if float(result.get("time_s", 0.0)) <= float(initial.get("time_s", 0.0)):
		_fail("Rascal simulation time did not advance")
		return
	if not is_finite(float(result.get("airspeed_mps", NAN))):
		_fail("Rascal airspeed is not finite")
		return
	print("RASCAL_BRIDGE_PASS airspeed_mps=", result["airspeed_mps"])
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
