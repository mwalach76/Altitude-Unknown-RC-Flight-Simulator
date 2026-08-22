extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://src/main.tscn")
	var simulator = scene.instantiate()
	root.add_child(simulator)
	await process_frame
	simulator.camera_mode = 2
	simulator.camera.fov = 16.0
	simulator.camera.global_position = Vector3(900.0, -40.0, 700.0)
	simulator.camera_target = Vector3(800.0, -30.0, 600.0)
	simulator.aircraft.crashed = true
	simulator.reset_simulation()
	if simulator.camera_mode != 0:
		_fail("Reset did not restore pilot camera mode")
		return
	if absf(simulator.camera.fov - 48.0) > 0.001:
		_fail("Reset did not restore pilot field of view")
		return
	if simulator.camera_target.distance_to(simulator.aircraft.global_position) > 0.001:
		_fail("Reset camera target does not match runway spawn")
		return
	if simulator.aircraft.crashed:
		_fail("Reset left aircraft in crashed state")
		return
	print("RESET_CAMERA_PASS")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
