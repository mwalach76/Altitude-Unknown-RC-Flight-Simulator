extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://src/main.tscn")
	var simulator = scene.instantiate()
	root.add_child(simulator)
	Input.action_press("throttle_up")
	Input.action_press("pitch_down")
	var airborne := false
	for frame in 1200:
		await physics_frame
		if not simulator.aircraft._js_grounded:
			airborne = true
			break
	Input.action_release("throttle_up")
	Input.action_release("pitch_down")
	if not airborne:
		_fail("Automated runway roll never reached liftoff")
		return
	var liftoff_position: Vector3 = simulator.aircraft.global_position
	var liftoff_pitch: float = simulator.aircraft.rotation.x
	var minimum_height := liftoff_position.y
	await physics_frame
	minimum_height = minf(minimum_height, simulator.aircraft.global_position.y)
	if absf(simulator.aircraft.global_position.y - liftoff_position.y) > 0.1:
		_fail("Aircraft jumped vertically at the airborne handoff")
		return
	if absf(simulator.aircraft.rotation.x - liftoff_pitch) > deg_to_rad(2.0):
		_fail("Aircraft attitude snapped at the airborne handoff")
		return
	for frame in 29:
		await physics_frame
		minimum_height = minf(minimum_height, simulator.aircraft.global_position.y)
	var aircraft_position: Vector3 = simulator.aircraft.global_position
	var camera_position: Vector3 = simulator.camera.global_position
	var camera_forward: Vector3 = -simulator.camera.global_basis.z
	var target_direction: Vector3 = camera_position.direction_to(simulator.camera_target)
	if not aircraft_position.is_finite() or not simulator.aircraft.global_basis.is_finite():
		_fail("First airborne transform is not finite")
		return
	if aircraft_position.distance_to(liftoff_position) > 15.0:
		_fail("Aircraft jumped an unrealistic distance at the airborne handoff")
		return
	if minimum_height < liftoff_position.y - 0.001:
		_fail("Aircraft sank below runway height during liftoff")
		return
	if camera_forward.dot(target_direction) < 0.999:
		_fail("Pilot camera is not aimed at its target after liftoff")
		return
	if simulator.camera.fov < 15.9 or simulator.camera.fov > 48.1:
		_fail("Pilot camera field of view is invalid after liftoff")
		return
	print("TAKEOFF_CAMERA_PASS aircraft=", aircraft_position, " camera=", camera_position, " fov=", simulator.camera.fov)
	quit(0)

func _fail(message: String) -> void:
	Input.action_release("throttle_up")
	Input.action_release("pitch_down")
	push_error(message)
	quit(1)
