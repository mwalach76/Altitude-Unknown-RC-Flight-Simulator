extends Node

var controller: ControllerManager
var aircraft: FixedWing
var hud: Label
var help: Label
var setup_panel: PanelContainer
var quick_panel: PanelContainer
var axis_label: Label
var camera_mode := 0
var camera: Camera3D
var camera_target := Vector3.ZERO
var hud_visible := true
var flight_model_button: Button

func _ready() -> void:
	controller = ControllerManager.new()
	add_child(controller)
	_build_world()
	_build_ui()
	_spawn_aircraft()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("reset_aircraft"):
		reset_simulation()
	if Input.is_action_just_pressed("change_camera"):
		cycle_camera()
	_update_camera(delta)
	hud.text = "%s   •   %s\n%3.0f km/h   %4.0f m   THR %3.0f%%   %s%s" % [controller.device_name(), aircraft.flight_model_name, aircraft.airspeed * 3.6, aircraft.global_position.y, aircraft.throttle * 100.0, ["PILOT", "CHASE", "ONBOARD"][camera_mode], "   •   CRASHED" if aircraft.crashed else ""]
	var lines := PackedStringArray()
	for axis in controller.axis_count():
		lines.append("Axis %d   %+.3f" % [axis, controller.raw_axis(axis)])
	axis_label.text = "LIVE INPUT\n" + "\n".join(lines) if not lines.is_empty() else "NO JOYSTICK DETECTED\nKeyboard controls are active."
	var viewport_size := get_viewport().get_visible_rect().size
	help.position = Vector2(20, viewport_size.y - 38)

func _build_world() -> void:
	var field := FlyingField.new()
	add_child(field)
	field.build()
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 52.0
	add_child(camera)

func _spawn_aircraft() -> void:
	aircraft = FixedWing.new()
	add_child(aircraft)
	aircraft.setup(controller)
	reset_simulation()
	_update_flight_model_button()

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	var menu_button := Button.new()
	menu_button.text = "☰"
	menu_button.position = Vector2(18, 16)
	menu_button.size = Vector2(46, 42)
	menu_button.add_theme_font_size_override("font_size", 22)
	menu_button.add_theme_stylebox_override("normal", _panel_style(Color(0.03, 0.05, 0.07, 0.72), 14))
	menu_button.pressed.connect(func(): quick_panel.visible = not quick_panel.visible)
	canvas.add_child(menu_button)

	var hud_panel := PanelContainer.new()
	hud_panel.position = Vector2(78, 16)
	hud_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.03, 0.05, 0.07, 0.66), 12))
	canvas.add_child(hud_panel)
	hud = Label.new()
	hud.add_theme_font_size_override("font_size", 16)
	hud.add_theme_color_override("font_color", Color("f4f7f8"))
	hud_panel.add_child(hud)

	help = Label.new()
	help.text = "W/S throttle   •   Arrows roll/pitch   •   A/D yaw   •   R reset   •   C camera   •   H HUD   •   F1 controller"
	help.add_theme_font_size_override("font_size", 14)
	help.add_theme_color_override("font_color", Color(1, 1, 1, 0.88))
	canvas.add_child(help)

	quick_panel = PanelContainer.new()
	quick_panel.position = Vector2(18, 68)
	quick_panel.size = Vector2(220, 196)
	quick_panel.visible = false
	quick_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.03, 0.05, 0.07, 0.88), 12))
	canvas.add_child(quick_panel)
	var quick_box := VBoxContainer.new()
	quick_panel.add_child(quick_box)
	var quick_title := Label.new()
	quick_title.text = "RC FLIGHT LAB"
	quick_title.add_theme_font_size_override("font_size", 18)
	quick_box.add_child(quick_title)
	_add_menu_button(quick_box, "Controller setup", func(): setup_panel.visible = true; quick_panel.visible = false)
	_add_menu_button(quick_box, "Change camera", cycle_camera)
	_add_menu_button(quick_box, "Reset aircraft", reset_simulation)
	flight_model_button = _add_menu_button(quick_box, "Flight model", toggle_flight_model)
	_update_flight_model_button()
	_add_menu_button(quick_box, "Toggle HUD", toggle_hud)
	_add_menu_button(quick_box, "Resume", func(): quick_panel.visible = false)

	setup_panel = PanelContainer.new()
	setup_panel.position = Vector2(890, 55)
	setup_panel.size = Vector2(370, 540)
	setup_panel.visible = false
	setup_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.03, 0.05, 0.07, 0.92), 14))
	canvas.add_child(setup_panel)
	var box := VBoxContainer.new()
	setup_panel.add_child(box)
	var title := Label.new()
	title.text = "CONTROLLER SETUP"
	title.add_theme_font_size_override("font_size", 22)
	box.add_child(title)
	axis_label = Label.new()
	axis_label.add_theme_font_size_override("font_size", 14)
	box.add_child(axis_label)
	for channel in ControllerManager.CHANNELS:
		var row := HBoxContainer.new()
		var name_label := Label.new()
		name_label.text = String(channel).capitalize()
		name_label.custom_minimum_size.x = 90
		row.add_child(name_label)
		var spin := SpinBox.new()
		spin.min_value = 0
		spin.max_value = 15
		spin.value = controller.mapping[String(channel)]
		spin.value_changed.connect(func(value: float): controller.assign_axis(String(channel), int(value)))
		row.add_child(spin)
		var reverse := CheckBox.new()
		reverse.text = "Reverse"
		reverse.button_pressed = controller.reversed[String(channel)]
		reverse.toggled.connect(func(value: bool): controller.toggle_reverse(String(channel), value))
		row.add_child(reverse)
		box.add_child(row)
	var center := Button.new()
	center.text = "Center roll / pitch / yaw"
	center.pressed.connect(controller.center_controls)
	box.add_child(center)
	var close := Button.new()
	close.text = "Close (F1)"
	close.pressed.connect(func(): setup_panel.visible = false)
	box.add_child(close)

func _panel_style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func _add_menu_button(parent: VBoxContainer, label_text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = label_text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func toggle_flight_model() -> void:
	aircraft.toggle_flight_model()
	_update_flight_model_button()

func _update_flight_model_button() -> void:
	if flight_model_button == null or aircraft == null:
		return
	flight_model_button.text = "Flight model: %s" % aircraft.flight_model_name
	flight_model_button.disabled = not aircraft.advanced_available() and aircraft.flight_model_name == "Simple"
	flight_model_button.tooltip_text = aircraft.advanced_error

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F1:
			setup_panel.visible = not setup_panel.visible
		elif event.keycode == KEY_H:
			toggle_hud()

func cycle_camera() -> void:
	camera_mode = (camera_mode + 1) % 3

func toggle_hud() -> void:
	hud_visible = not hud_visible
	hud.get_parent().visible = hud_visible
	help.visible = hud_visible

func reset_simulation() -> void:
	if aircraft == null:
		return
	aircraft.reset_aircraft()
	camera_mode = 0
	camera_target = aircraft.global_position
	var pilot_position := Vector3(14.0, 2.5, 20.0)
	camera.global_position = pilot_position
	camera.fov = 48.0
	camera.look_at(camera_target, Vector3.UP)

func _update_camera(delta: float) -> void:
	if aircraft == null:
		return
	camera_target = camera_target.lerp(aircraft.global_position, 1.0 - exp(-delta * 12.0))
	if camera_mode == 0:
		var pilot_position := Vector3(14.0, 2.5, 20.0)
		camera.global_position = pilot_position
		camera.look_at(camera_target, Vector3.UP)
		var distance := pilot_position.distance_to(aircraft.global_position)
		# Keep an RC-sized model legible without turning the camera into an
		# unnaturally locked chase view. Zoom tightens progressively with range.
		var desired_fov := clampf(48.0 - maxf(0.0, distance - 12.0) * 0.48, 16.0, 48.0)
		camera.fov = lerpf(camera.fov, desired_fov, 1.0 - exp(-delta * 3.5))
	elif camera_mode == 1:
		var desired := aircraft.global_position + aircraft.global_basis.z * 8.5 + Vector3.UP * 2.8
		camera.global_position = camera.global_position.lerp(desired, 1.0 - exp(-delta * 5.0))
		camera.look_at(camera_target, Vector3.UP)
		camera.fov = lerpf(camera.fov, 54.0, 1.0 - exp(-delta * 4.0))
	else:
		camera.global_transform = aircraft.global_transform.translated_local(Vector3(0, 0.42, -0.48))
		camera.fov = 72.0
