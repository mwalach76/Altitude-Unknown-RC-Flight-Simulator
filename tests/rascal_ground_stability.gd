extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://src/main.tscn")
	var simulator := scene.instantiate()
	root.add_child(simulator)
	for frame in 180:
		await physics_frame
	var aircraft = simulator.aircraft
	if aircraft.flight_model_name != "JSBSim Rascal 110":
		_fail("Advanced Rascal model did not start: " + aircraft.advanced_error)
		return
	if aircraft.global_position.distance_to(Vector3(0, 0.55, 18.0)) > 0.02:
		_fail("Rascal moved on the ground with zero controls")
		return
	if absf(rad_to_deg(aircraft.rotation.x) - 12.0) > 0.2 or absf(rad_to_deg(aircraft.rotation.z)) > 0.2:
		_fail("Rascal ground attitude became unstable")
		return
	print("RASCAL_GROUND_STABILITY_PASS")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
