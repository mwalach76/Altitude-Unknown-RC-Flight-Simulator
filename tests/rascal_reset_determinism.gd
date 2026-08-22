extends SceneTree

const STEP := 1.0 / 120.0

func _init() -> void:
	if not ClassDB.class_exists(&"JsbsimBridge"):
		_fail("JsbsimBridge GDExtension class is unavailable")
		return
	var bridge = ClassDB.instantiate(&"JsbsimBridge")
	var data_root := ProjectSettings.globalize_path("res://assets/jsbsim")
	if not bridge.initialize(data_root, "Rascal", STEP):
		_fail(bridge.last_error())
		return
	var first := _launch_profile(bridge)
	# Deliberately contaminate all command and dynamic state before resetting.
	for frame in 90:
		bridge.step(1.0, 0.8, -0.7, 0.6)
	var second := _launch_profile(bridge)
	for property_name in ["airspeed_mps", "roll_rad", "pitch_rad", "heading_rad", "p_rad_s", "q_rad_s", "r_rad_s"]:
		var difference := absf(float(first[property_name]) - float(second[property_name]))
		if difference > 0.000001:
			_fail("Reset retained state in %s (difference %.9f)" % [property_name, difference])
			return
	print("RASCAL_RESET_DETERMINISM_PASS")
	quit(0)

func _launch_profile(bridge: Object) -> Dictionary:
	if not bridge.reset(1.0, 13.0, 0.0, 6.0):
		return {}
	var result: Dictionary
	for frame in 180:
		result = bridge.step(0.75, 0.0, -0.08, 0.0)
	return result

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
