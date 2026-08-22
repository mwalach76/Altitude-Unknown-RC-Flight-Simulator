extends SceneTree

func _init() -> void:
	var rascal := FileAccess.get_file_as_string("res://assets/jsbsim/aircraft/Rascal/Rascal.xml")
	var juggy := FileAccess.get_file_as_string("res://assets/jsbsim/aircraft/Juggy/Juggy.xml")
	var expected_changes := {
		"zero-lift drag": ["0.0000\t0.0280", "0.0000\t0.0747"],
		"induced drag": ["<value>0.0400</value>", "<value>0.1067</value>"],
		"aileron response": ["0.0000\t0.1300", "0.0000\t0.3900"],
		"elevator response": ["0.0000\t-0.5000", "0.0000\t-1.5000"],
		"rudder response": ["<value>-0.0500</value>", "<value>-0.1500</value>"],
	}
	for label in expected_changes:
		var values: Array = expected_changes[label]
		if not rascal.contains(values[0]) or not juggy.contains(values[1]):
			_fail("Juggy %s tuning is missing" % label)
			return
	if not juggy.contains("engine file=\"Juggy_G-26A\"") or not juggy.contains("thruster file=\"Juggy_18x16\""):
		_fail("Juggy independent propulsion references are missing")
		return
	var engine := FileAccess.get_file_as_string("res://assets/jsbsim/engine/Juggy_G-26A.xml")
	var propeller := FileAccess.get_file_as_string("res://assets/jsbsim/engine/Juggy_18x16.xml")
	if not engine.contains("17658.16") or not propeller.contains("<minpitch>60</minpitch>"):
		_fail("Juggy 2x-speed propulsion tune is missing")
		return
	print("JUGGY_TUNING_PASS glide=0.375x controls=3x power=8x prop_pitch=2x")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
