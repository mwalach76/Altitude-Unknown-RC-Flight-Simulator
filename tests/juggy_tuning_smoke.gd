extends SceneTree

func _init() -> void:
	var rascal := FileAccess.get_file_as_string("res://assets/jsbsim/aircraft/Rascal/Rascal.xml")
	var juggy := FileAccess.get_file_as_string("res://assets/jsbsim/aircraft/Juggy/Juggy.xml")
	var expected_changes := {
		"zero-lift drag": ["0.0000\t0.0280", "0.0000\t0.0560"],
		"induced drag": ["<value>0.0400</value>", "<value>0.0800</value>"],
		"aileron response": ["0.0000\t0.1300", "0.0000\t0.2600"],
		"elevator response": ["0.0000\t-0.5000", "0.0000\t-1.0000"],
		"rudder response": ["<value>-0.0500</value>", "<value>-0.1000</value>"],
	}
	for label in expected_changes:
		var values: Array = expected_changes[label]
		if not rascal.contains(values[0]) or not juggy.contains(values[1]):
			_fail("Juggy %s tuning is missing" % label)
			return
	print("JUGGY_TUNING_PASS glide_drag=2x controls=2x")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
