class_name FixedWing
extends RigidBody3D

const AIR_DENSITY := 1.225
const VISUAL_SCALE := 1.65
const WING_CENTER_Z := -0.08 * VISUAL_SCALE
const WING_CHORD := 0.36 * VISUAL_SCALE
const RUNWAY_SPAWN := Vector3(0, 0.55, 18.0)
const GROUND_ATTITUDE_DEG := 12.0

var config := TrainerConfig.new()
var controls: ControllerManager
var crashed := false
var airspeed := 0.0
var throttle := 0.0
var roll_command := 0.0
var pitch_command := 0.0
var yaw_command := 0.0
var flight_model_name := "Simple"
var advanced_error := ""

var _jsbsim: Object
var _advanced_mode := false
var _js_position := Vector3.ZERO
var _js_heading_offset := 0.0
const JSBSIM_STEP := 1.0 / 120.0

var propeller: Node3D
var left_aileron: Node3D
var right_aileron: Node3D
var elevator_surface: Node3D
var rudder_surface: Node3D

func setup(input_manager: ControllerManager) -> void:
	controls = input_manager
	mass = config.mass_kg
	linear_damp = 0.02
	angular_damp = 0.12
	# The rigid body's custom mass center is measured in model-local space.
	# With -Z forward, the leading edge is the wing's most-negative Z point.
	var wing_leading_edge := WING_CENTER_Z - WING_CHORD * 0.5
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0, 0, wing_leading_edge + WING_CHORD * config.cg_fraction_chord)
	var rolling_material := PhysicsMaterial.new()
	rolling_material.friction = 0.16
	rolling_material.bounce = 0.02
	physics_material_override = rolling_material
	_build_geometry()
	_initialize_jsbsim()

func advanced_available() -> bool:
	return _jsbsim != null

func set_advanced_mode(enabled: bool) -> bool:
	_advanced_mode = enabled and advanced_available()
	flight_model_name = "JSBSim Rascal 110" if _advanced_mode else "Simple"
	custom_integrator = _advanced_mode
	freeze = _advanced_mode
	reset_aircraft()
	return _advanced_mode

func toggle_flight_model() -> bool:
	return set_advanced_mode(not _advanced_mode)

func _initialize_jsbsim() -> void:
	if not ClassDB.class_exists(&"JsbsimBridge"):
		advanced_error = "Native JSBSim extension is not available"
		return
	_jsbsim = ClassDB.instantiate(&"JsbsimBridge")
	var data_root := ProjectSettings.globalize_path("res://assets/jsbsim")
	if not _jsbsim.initialize(data_root, "Rascal", JSBSIM_STEP):
		advanced_error = _jsbsim.last_error()
		_jsbsim = null
		return
	set_advanced_mode(true)

func _physics_process(_delta: float) -> void:
	if not _advanced_mode or controls == null or crashed:
		return
	throttle = controls.channel(&"throttle")
	roll_command = _apply_expo(controls.channel(&"roll"))
	pitch_command = _apply_expo(controls.channel(&"pitch"))
	yaw_command = _apply_expo(controls.channel(&"yaw"))
	# Godot normally runs at 60 Hz; two fixed 120 Hz FDM steps keep JSBSim
	# deterministic and independent of the display frame rate.
	var result: Dictionary
	for iteration in 2:
		result = _jsbsim.step(throttle, roll_command, pitch_command, yaw_command)
		_js_position += Vector3(
			float(result.get("east_mps", 0.0)),
			-float(result.get("down_mps", 0.0)),
			-float(result.get("north_mps", 0.0))
		) * JSBSIM_STEP
	if not bool(result.get("ready", false)):
		advanced_error = _jsbsim.last_error()
		set_advanced_mode(false)
		return
	airspeed = float(result.get("airspeed_mps", 0.0))
	var roll := float(result.get("roll_rad", 0.0))
	var pitch := float(result.get("pitch_rad", 0.0))
	var heading := float(result.get("heading_rad", 0.0)) + _js_heading_offset
	var attitude := Basis(Vector3.UP, -heading) * Basis(Vector3.RIGHT, pitch) * Basis(Vector3.BACK, -roll)
	global_transform = Transform3D(attitude, _js_position)

func _process(delta: float) -> void:
	if propeller:
		propeller.rotate_z(delta * lerpf(4.0, 85.0, throttle))
	if left_aileron:
		left_aileron.rotation.x = lerpf(left_aileron.rotation.x, -roll_command * 0.34, 0.25)
		right_aileron.rotation.x = lerpf(right_aileron.rotation.x, roll_command * 0.34, 0.25)
	if elevator_surface:
		elevator_surface.rotation.x = lerpf(elevator_surface.rotation.x, pitch_command * 0.38, 0.25)
	if rudder_surface:
		rudder_surface.rotation.y = lerpf(rudder_surface.rotation.y, -yaw_command * 0.42, 0.25)

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if _advanced_mode or controls == null or crashed:
		return
	throttle = controls.channel(&"throttle")
	roll_command = _apply_expo(controls.channel(&"roll"))
	pitch_command = _apply_expo(controls.channel(&"pitch"))
	yaw_command = _apply_expo(controls.channel(&"yaw"))
	var velocity_body := state.transform.basis.inverse() * state.linear_velocity
	airspeed = velocity_body.length()
	# Godot body convention used here: forward -Z, right +X, up +Y.
	var forward_speed := maxf(0.0, -velocity_body.z)
	var alpha := atan2(-velocity_body.y, maxf(0.1, forward_speed))
	var cl := clampf(config.cl_zero + config.cl_alpha_per_rad * alpha, -config.cl_max, config.cl_max)
	if absf(alpha) > config.stall_angle_rad:
		cl *= maxf(0.2, 1.0 - (absf(alpha) - config.stall_angle_rad) * 1.8)
	var dynamic_pressure := 0.5 * AIR_DENSITY * forward_speed * forward_speed
	var lift := dynamic_pressure * config.wing_area_m2 * cl
	var drag := dynamic_pressure * config.wing_area_m2 * (config.cd_zero + config.induced_drag_factor * cl * cl)
	state.apply_central_force(state.transform.basis.y * lift)
	state.apply_central_force(state.transform.basis.z * drag)
	state.apply_central_force(-state.transform.basis.z * config.max_thrust_n * throttle)
	var authority := clampf(dynamic_pressure / 45.0, 0.05, 2.5)
	state.apply_torque(state.transform.basis * Vector3(-pitch_command * config.pitch_effectiveness, -yaw_command * config.yaw_effectiveness, -roll_command * config.roll_effectiveness) * authority)
	state.apply_torque(-state.angular_velocity * Vector3(0.8, 0.5, 0.65))
	if state.transform.origin.y < 0.12 and state.linear_velocity.length() > 4.0:
		crashed = true

func reset_aircraft() -> void:
	crashed = false
	if _advanced_mode and _jsbsim != null:
		_js_position = RUNWAY_SPAWN
		_js_heading_offset = 0.0
		_jsbsim.reset(0.55, 0.0, 0.0)
		global_transform = Transform3D(Basis.IDENTITY, RUNWAY_SPAWN)
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO
		return
	freeze = true
	var ground_basis := Basis(Vector3.RIGHT, deg_to_rad(GROUND_ATTITUDE_DEG))
	global_transform = Transform3D(ground_basis, RUNWAY_SPAWN)
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	freeze = false
	sleeping = false

func _apply_expo(input_value: float) -> float:
	return lerpf(input_value, input_value * input_value * input_value, config.control_expo)

func _build_geometry() -> void:
	var body_blue := _material(Color("175a9e"), 0.28, 0.15)
	var wing_white := _material(Color("f4f6f8"), 0.34)
	var trim_orange := _material(Color("f0a12b"), 0.3)
	var dark := _material(Color("1b252f"), 0.45)
	var glass := _material(Color("66b6d6"), 0.12, 0.35)

	_add_cylinder(Vector3(0, 0, 0.02), 0.18, 1.58, body_blue, Vector3(90, 0, 0))
	_add_sphere(Vector3(0, 0, -0.79), Vector3(0.19, 0.19, 0.22), trim_orange)
	_add_sphere(Vector3(0, 0.02, 0.78), Vector3(0.15, 0.15, 0.20), body_blue)
	_add_sphere(Vector3(0, 0.20, -0.16), Vector3(0.15, 0.10, 0.25), glass)

	_add_box(Vector3(0, 0.18, -0.08), Vector3(1.82, 0.07, 0.36), wing_white)
	_add_box(Vector3(0, 0.205, -0.245), Vector3(1.78, 0.018, 0.055), trim_orange)
	left_aileron = _surface(Vector3(-0.63, 0.18, 0.135), Vector3(0.52, 0.045, 0.12), body_blue)
	right_aileron = _surface(Vector3(0.63, 0.18, 0.135), Vector3(0.52, 0.045, 0.12), body_blue)

	_add_box(Vector3(0, 0.06, 0.68), Vector3(0.70, 0.045, 0.16), wing_white)
	elevator_surface = _surface(Vector3(0, 0.06, 0.80), Vector3(0.68, 0.035, 0.11), trim_orange)
	_add_box(Vector3(0, 0.25, 0.69), Vector3(0.045, 0.40, 0.19), wing_white)
	rudder_surface = _surface(Vector3(0, 0.26, 0.83), Vector3(0.035, 0.30, 0.10), trim_orange)

	_add_cylinder(Vector3(-0.23, -0.25, -0.18), 0.095, 0.055, dark, Vector3(0, 0, 90))
	_add_cylinder(Vector3(0.23, -0.25, -0.18), 0.095, 0.055, dark, Vector3(0, 0, 90))
	_add_cylinder(Vector3(-0.19, -0.12, -0.14), 0.012, 0.30, dark, Vector3(0, 0, -35))
	_add_cylinder(Vector3(0.19, -0.12, -0.14), 0.012, 0.30, dark, Vector3(0, 0, 35))
	_add_sphere(Vector3(0, -0.10, 0.75), Vector3(0.025, 0.025, 0.035), dark)

	propeller = Node3D.new()
	propeller.position = Vector3(0, 0, -0.99) * VISUAL_SCALE
	add_child(propeller)
	_add_box_to(propeller, Vector3.ZERO, Vector3(0.055, 0.60, 0.025) * VISUAL_SCALE, dark)
	_add_sphere_to(propeller, Vector3.ZERO, Vector3(0.08, 0.08, 0.06) * VISUAL_SCALE, trim_orange)

	# Keep the aerodynamic body origin independent of the contact geometry.
	# Three wheel contact shapes let the trainer sit on the runway instead of
	# hovering on the old fuselage-sized collision box.
	_add_box_collision(Vector3(0, 0, 0.02) * VISUAL_SCALE, Vector3(0.34, 0.30, 1.50) * VISUAL_SCALE)
	_add_sphere_collision(Vector3(-0.23, -0.25, -0.18) * VISUAL_SCALE, 0.095 * VISUAL_SCALE)
	_add_sphere_collision(Vector3(0.23, -0.25, -0.18) * VISUAL_SCALE, 0.095 * VISUAL_SCALE)
	_add_sphere_collision(Vector3(0, -0.10, 0.75) * VISUAL_SCALE, 0.035 * VISUAL_SCALE)

func _surface(pos: Vector3, size: Vector3, material: Material) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = pos * VISUAL_SCALE
	add_child(pivot)
	_add_box_to(pivot, Vector3.ZERO, size * VISUAL_SCALE, material)
	return pivot

func _material(color: Color, roughness := 0.4, metallic := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material

func _add_box(pos: Vector3, size: Vector3, material: Material) -> void:
	_add_box_to(self, pos * VISUAL_SCALE, size * VISUAL_SCALE, material)

func _add_box_to(parent: Node, pos: Vector3, size: Vector3, material: Material) -> void:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	instance.mesh = mesh
	instance.position = pos
	parent.add_child(instance)

func _add_cylinder(pos: Vector3, radius: float, height: float, material: Material, rotation_deg := Vector3.ZERO) -> void:
	var instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * VISUAL_SCALE
	mesh.bottom_radius = radius * VISUAL_SCALE
	mesh.height = height * VISUAL_SCALE
	mesh.radial_segments = 20
	mesh.material = material
	instance.mesh = mesh
	instance.position = pos * VISUAL_SCALE
	instance.rotation_degrees = rotation_deg
	add_child(instance)

func _add_sphere(pos: Vector3, scale_value: Vector3, material: Material) -> void:
	_add_sphere_to(self, pos * VISUAL_SCALE, scale_value * VISUAL_SCALE, material)

func _add_sphere_to(parent: Node, pos: Vector3, scale_value: Vector3, material: Material) -> void:
	var instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.height = 2.0
	mesh.radius = 1.0
	mesh.radial_segments = 20
	mesh.rings = 12
	mesh.material = material
	instance.mesh = mesh
	instance.position = pos
	instance.scale = scale_value
	parent.add_child(instance)

func _add_box_collision(pos: Vector3, size: Vector3) -> void:
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	collision.position = pos
	add_child(collision)

func _add_sphere_collision(pos: Vector3, radius: float) -> void:
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = radius
	collision.shape = shape
	collision.position = pos
	add_child(collision)
