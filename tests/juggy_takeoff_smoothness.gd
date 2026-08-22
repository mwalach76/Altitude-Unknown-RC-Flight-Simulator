extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://src/main.tscn")
	var simulator = scene.instantiate()
	root.add_child(simulator)
	simulator.aircraft.set_aircraft_model("Juggy")
	simulator.reset_simulation()
	simulator.controller.throttle_keyboard = 1.0
	Input.action_press("pitch_down")
	for frame in 900:
		await physics_frame
		if not simulator.aircraft._js_grounded:
			break
	if simulator.aircraft._js_grounded:
		_fail("Juggy never reached liftoff")
		return
	var previous_height: float = simulator.aircraft.global_position.y
	var maximum_height_step := 0.0
	for frame in 240:
		await physics_frame
		if frame == 45:
			Input.action_release("pitch_down")
		var height: float = simulator.aircraft.global_position.y
		if not is_finite(height) or not simulator.aircraft.global_basis.is_finite():
			_fail("Juggy produced a non-finite flight state after takeoff")
			return
		maximum_height_step = maxf(maximum_height_step, absf(height - previous_height))
		previous_height = height
	Input.action_release("pitch_down")
	if maximum_height_step > 0.04:
		_fail("Juggy hopped during takeoff (vertical step %.4f m)" % maximum_height_step)
		return
	print("JUGGY_TAKEOFF_SMOOTHNESS_PASS max_step=%.4f" % maximum_height_step)
	quit()

func _fail(message: String) -> void:
	Input.action_release("pitch_down")
	push_error(message)
	quit(1)
