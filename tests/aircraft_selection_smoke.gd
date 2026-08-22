extends SceneTree

func _init() -> void:
	var controller := ControllerManager.new()
	root.add_child(controller)
	var aircraft := FixedWing.new()
	root.add_child(aircraft)
	aircraft.setup(controller)
	if aircraft.aircraft_name != "Rascal":
		_fail("Rascal is not the default aircraft")
		return
	if not aircraft.set_aircraft_model("Juggy"):
		_fail("Juggy failed to load: " + aircraft.advanced_error)
		return
	if aircraft.aircraft_name != "Juggy" or aircraft.flight_model_name != "JSBSim Juggy":
		_fail("Juggy selection was not applied")
		return
	if not aircraft.set_aircraft_model("Rascal"):
		_fail("Rascal failed to reload: " + aircraft.advanced_error)
		return
	print("AIRCRAFT_SELECTION_PASS")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
