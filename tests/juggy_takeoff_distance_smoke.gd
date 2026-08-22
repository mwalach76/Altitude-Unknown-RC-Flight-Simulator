extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://src/main.tscn")
	var simulator = scene.instantiate()
	root.add_child(simulator)
	Input.action_press("pitch_down")
	var rascal_distance := await _measure_takeoff(simulator)
	simulator.aircraft.set_aircraft_model("Juggy")
	simulator.reset_simulation()
	var juggy_distance := await _measure_takeoff(simulator)
	Input.action_release("pitch_down")
	if juggy_distance > rascal_distance * 0.53:
		_fail("Juggy takeoff roll was not halved: Rascal %.2f m, Juggy %.2f m" % [rascal_distance, juggy_distance])
		return
	print("JUGGY_TAKEOFF_DISTANCE_PASS rascal=%.2f juggy=%.2f ratio=%.3f" % [rascal_distance, juggy_distance, juggy_distance / rascal_distance])
	quit()

func _measure_takeoff(simulator: Node) -> float:
	simulator.controller.throttle_keyboard = 1.0
	var start: Vector3 = simulator.aircraft.global_position
	for frame in 900:
		await physics_frame
		if not simulator.aircraft._js_grounded:
			return simulator.aircraft.global_position.distance_to(start)
	return INF

func _fail(message: String) -> void:
	Input.action_release("pitch_down")
	push_error(message)
	quit(1)
