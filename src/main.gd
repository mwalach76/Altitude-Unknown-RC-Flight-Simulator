extends Node

var controller: ControllerManager
var aircraft: FixedWing
var hud: Label
var setup_panel: PanelContainer
var axis_label: Label
var camera_mode := 0
var camera: Camera3D

func _ready() -> void:
	controller = ControllerManager.new(); add_child(controller)
	_build_world(); _build_ui(); _spawn_aircraft()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("reset_aircraft"): aircraft.reset_aircraft()
	if Input.is_action_just_pressed("change_camera"): camera_mode = (camera_mode + 1) % 3
	_update_camera()
	hud.text = "RC FLIGHT LAB   |   %s\nAirspeed %5.1f m/s   Altitude %5.1f m   Throttle %3.0f%%   Camera %s%s" % [controller.device_name(), aircraft.airspeed, aircraft.global_position.y, aircraft.throttle * 100.0, ["PILOT", "CHASE", "ONBOARD"][camera_mode], "   CRASHED — R to reset" if aircraft.crashed else ""]
	var lines := PackedStringArray()
	for axis in controller.axis_count(): lines.append("Axis %d   %+.3f" % [axis, controller.raw_axis(axis)])
	axis_label.text = "Live axes\n" + "\n".join(lines) if not lines.is_empty() else "No joystick detected.\nKeyboard controls are active."

func _build_world() -> void:
	var world := WorldEnvironment.new(); var env := Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = Color("74a9d8")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color.WHITE; env.ambient_light_energy = 0.65
	world.environment = env; add_child(world)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, -25, 0); sun.shadow_enabled = true; add_child(sun)
	var ground := StaticBody3D.new(); var mesh := MeshInstance3D.new(); var plane := BoxMesh.new(); plane.size = Vector3(300, 0.1, 300)
	var mat := StandardMaterial3D.new(); mat.albedo_color = Color("4d8b45"); plane.material = mat; mesh.mesh = plane; ground.add_child(mesh)
	var collider := CollisionShape3D.new(); var shape := BoxShape3D.new(); shape.size = plane.size; collider.shape = shape; ground.add_child(collider); ground.position.y = -0.05; add_child(ground)
	var runway := MeshInstance3D.new(); var runway_mesh := BoxMesh.new(); runway_mesh.size = Vector3(8, 0.02, 90)
	var runway_mat := StandardMaterial3D.new(); runway_mat.albedo_color = Color("55595c"); runway_mesh.material = runway_mat; runway.mesh = runway_mesh; runway.position.y = 0.01; add_child(runway)
	camera = Camera3D.new(); camera.current = true; add_child(camera)

func _spawn_aircraft() -> void:
	aircraft = FixedWing.new(); add_child(aircraft); aircraft.setup(controller); aircraft.reset_aircraft()

func _build_ui() -> void:
	hud = Label.new(); hud.position = Vector2(18, 15); hud.add_theme_font_size_override("font_size", 18); add_child(hud)
	var help := Label.new(); help.text = "W/S throttle  •  Arrows roll/pitch  •  A/D yaw  •  R reset  •  C camera  •  F1 controller setup"; help.position = Vector2(18, 680); add_child(help)
	setup_panel = PanelContainer.new(); setup_panel.position = Vector2(900, 55); setup_panel.size = Vector2(350, 520); setup_panel.visible = false; add_child(setup_panel)
	var box := VBoxContainer.new(); setup_panel.add_child(box)
	var title := Label.new(); title.text = "CONTROLLER SETUP"; title.add_theme_font_size_override("font_size", 22); box.add_child(title)
	axis_label = Label.new(); box.add_child(axis_label)
	for channel in ControllerManager.CHANNELS:
		var row := HBoxContainer.new(); var name_label := Label.new(); name_label.text = String(channel).capitalize(); name_label.custom_minimum_size.x = 90; row.add_child(name_label)
		var spin := SpinBox.new(); spin.min_value = 0; spin.max_value = 15; spin.value = controller.mapping[String(channel)]; spin.value_changed.connect(func(value: float): controller.assign_axis(String(channel), int(value))); row.add_child(spin)
		var reverse := CheckBox.new(); reverse.text = "Reverse"; reverse.button_pressed = controller.reversed[String(channel)]; reverse.toggled.connect(func(value: bool): controller.toggle_reverse(String(channel), value)); row.add_child(reverse); box.add_child(row)
	var center := Button.new(); center.text = "Center roll / pitch / yaw"; center.pressed.connect(controller.center_controls); box.add_child(center)
	var close := Button.new(); close.text = "Close (F1)"; close.pressed.connect(func(): setup_panel.visible = false); box.add_child(close)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		setup_panel.visible = not setup_panel.visible

func _update_camera() -> void:
	if aircraft == null: return
	if camera_mode == 0:
		camera.global_position = Vector3(18, 7, 22); camera.look_at(aircraft.global_position, Vector3.UP)
	elif camera_mode == 1:
		var desired := aircraft.global_position + aircraft.global_basis.z * 8.0 + Vector3.UP * 2.5
		camera.global_position = camera.global_position.lerp(desired, 0.08); camera.look_at(aircraft.global_position, Vector3.UP)
	else:
		camera.global_transform = aircraft.global_transform.translated_local(Vector3(0, 0.35, -0.4))
