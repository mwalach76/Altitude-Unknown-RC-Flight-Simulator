class_name FixedWing
extends RigidBody3D

const AIR_DENSITY := 1.225
var config := TrainerConfig.new()
var controls: ControllerManager
var crashed := false
var airspeed := 0.0
var throttle := 0.0
const VISUAL_SCALE := 1.65

func setup(input_manager: ControllerManager) -> void:
	controls = input_manager
	mass = config.mass_kg
	linear_damp = 0.02
	angular_damp = 0.12
	_build_geometry()

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if controls == null or crashed: return
	throttle = controls.channel(&"throttle")
	var roll := _apply_expo(controls.channel(&"roll"))
	var pitch := _apply_expo(controls.channel(&"pitch"))
	var yaw := _apply_expo(controls.channel(&"yaw"))
	var velocity_body := state.transform.basis.inverse() * state.linear_velocity
	airspeed = velocity_body.length()
	# Godot body convention used here: forward -Z, right +X, up +Y.
	var forward_speed := maxf(0.0, -velocity_body.z)
	# A descending flight path has negative body-Y velocity. With the nose still
	# level that means positive angle of attack (nose above the flight path).
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
	# Surface authority scales with dynamic pressure; damping limits unrealistic rotation.
	var authority := clampf(dynamic_pressure / 45.0, 0.05, 2.5)
	state.apply_torque(state.transform.basis * Vector3(-pitch * config.pitch_effectiveness, -yaw * config.yaw_effectiveness, -roll * config.roll_effectiveness) * authority)
	state.apply_torque(-state.angular_velocity * Vector3(0.8, 0.5, 0.65))
	if state.transform.origin.y < 0.12 and state.linear_velocity.length() > 4.0:
		crashed = true

func reset_aircraft() -> void:
	crashed = false
	freeze = true
	global_transform = Transform3D(Basis.IDENTITY, Vector3(0, 8.0, 18.0))
	# Milestone 1 uses a hand launch: 12 m/s is safely above this trainer's
	# approximate stall speed and leaves time to establish powered flight.
	linear_velocity = -global_transform.basis.z * 12.0
	angular_velocity = Vector3.ZERO
	freeze = false

func _apply_expo(input_value: float) -> float:
	# RC-style expo blends linear and cubic response. Full stick still produces
	# full command, while the center region becomes less sensitive.
	return lerpf(input_value, input_value * input_value * input_value, config.control_expo)

func _build_geometry() -> void:
	_add_box(Vector3(0, 0, 0), Vector3(0.22, 0.22, 1.5), Color("f5a623"))
	_add_box(Vector3(0, 0.05, -0.15), Vector3(1.7, 0.08, 0.38), Color("f4f4f4"))
	_add_box(Vector3(0, 0.08, 0.66), Vector3(0.72, 0.05, 0.22), Color("f4f4f4"))
	_add_box(Vector3(0, 0.25, 0.68), Vector3(0.05, 0.45, 0.25), Color("e95f3c"))
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new(); shape.size = Vector3(1.7, 0.22, 1.5)
	collision.shape = shape; add_child(collision)

func _add_box(pos: Vector3, size: Vector3, color: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new(); mesh.size = size * VISUAL_SCALE
	var material := StandardMaterial3D.new(); material.albedo_color = color
	mesh.material = material; mesh_instance.mesh = mesh; mesh_instance.position = pos * VISUAL_SCALE
	add_child(mesh_instance)
