class_name ControllerManager
extends Node

const SAVE_PATH := "user://controller_mapping.cfg"
const CHANNELS := [&"throttle", &"roll", &"pitch", &"yaw"]

var device_id := -1
var mapping := {"throttle": 1, "roll": 0, "pitch": 1, "yaw": 2}
var reversed := {"throttle": true, "roll": false, "pitch": true, "yaw": false}
var centers := {"throttle": 0.0, "roll": 0.0, "pitch": 0.0, "yaw": 0.0}
var minimums := {"throttle": -1.0, "roll": -1.0, "pitch": -1.0, "yaw": -1.0}
var maximums := {"throttle": 1.0, "roll": 1.0, "pitch": 1.0, "yaw": 1.0}
var deadband := 0.04
var throttle_keyboard := 0.0
var endpoint_calibration_active := false

func _ready() -> void:
	Input.joy_connection_changed.connect(_on_connection_changed)
	load_mapping()
	select_first_device()

func _process(_delta: float) -> void:
	if not endpoint_calibration_active or device_id < 0:
		return
	for channel_name in CHANNELS:
		var key := String(channel_name)
		var value := raw_axis(int(mapping[key]))
		minimums[key] = minf(float(minimums[key]), value)
		maximums[key] = maxf(float(maximums[key]), value)

func select_first_device() -> void:
	var devices := Input.get_connected_joypads()
	device_id = devices[0] if not devices.is_empty() else -1

func _on_connection_changed(_device: int, _connected: bool) -> void:
	select_first_device()

func device_name() -> String:
	return Input.get_joy_name(device_id) if device_id >= 0 else "Keyboard fallback"

func axis_count() -> int:
	# Godot exposes the standard SDL axis slots but no per-device axis-count API.
	# Showing all ten slots makes unusual RC dongles diagnosable as well.
	return 10 if device_id >= 0 else 0

func raw_axis(axis: int) -> float:
	return Input.get_joy_axis(device_id, axis) if device_id >= 0 else 0.0

func channel(channel: StringName) -> float:
	if device_id < 0:
		return _keyboard_channel(channel)
	var key := String(channel)
	var raw_value := raw_axis(int(mapping.get(key, 0)))
	var minimum := float(minimums.get(key, -1.0))
	var maximum := float(maximums.get(key, 1.0))
	var center := float(centers.get(key, 0.0))
	var value: float
	if channel == &"throttle":
		value = remap(raw_value, minimum, maximum, -1.0, 1.0) if maximum - minimum > 0.1 else 0.0
	else:
		var extent := maximum - center if raw_value >= center else center - minimum
		value = (raw_value - center) / maxf(0.05, extent)
	if bool(reversed.get(String(channel), false)):
		value = -value
	if absf(value) < deadband:
		value = 0.0
	value = clampf(value / maxf(0.01, 1.0 - deadband), -1.0, 1.0)
	return (value + 1.0) * 0.5 if channel == &"throttle" else value

func _keyboard_channel(channel: StringName) -> float:
	if channel == &"throttle":
		throttle_keyboard = clampf(throttle_keyboard + (Input.get_axis("throttle_down", "throttle_up") * get_process_delta_time()), 0.0, 1.0)
		return throttle_keyboard
	if channel == &"roll": return Input.get_axis("roll_left", "roll_right")
	if channel == &"pitch": return Input.get_axis("pitch_down", "pitch_up")
	return Input.get_axis("yaw_left", "yaw_right")

func assign_axis(channel: String, axis: int) -> void:
	mapping[channel] = axis
	save_mapping()

func toggle_reverse(channel: String, enabled: bool) -> void:
	reversed[channel] = enabled
	save_mapping()

func center_controls() -> void:
	for channel_name in CHANNELS:
		if channel_name != &"throttle":
			centers[String(channel_name)] = raw_axis(int(mapping[String(channel_name)]))
	save_mapping()

func start_endpoint_calibration() -> void:
	if device_id < 0:
		return
	endpoint_calibration_active = true
	for channel_name in CHANNELS:
		var key := String(channel_name)
		var value := raw_axis(int(mapping[key]))
		minimums[key] = value
		maximums[key] = value

func finish_endpoint_calibration() -> bool:
	if not endpoint_calibration_active:
		return false
	endpoint_calibration_active = false
	for channel_name in CHANNELS:
		var key := String(channel_name)
		if float(maximums[key]) - float(minimums[key]) < 0.2:
			minimums[key] = -1.0
			maximums[key] = 1.0
	save_mapping()
	return true

func save_mapping() -> void:
	var config := ConfigFile.new()
	for channel_name in CHANNELS:
		config.set_value("axes", channel_name, mapping[String(channel_name)])
		config.set_value("reverse", channel_name, reversed[String(channel_name)])
		config.set_value("center", channel_name, centers[String(channel_name)])
		config.set_value("minimum", channel_name, minimums[String(channel_name)])
		config.set_value("maximum", channel_name, maximums[String(channel_name)])
	config.set_value("calibration", "deadband", deadband)
	config.save(SAVE_PATH)

func load_mapping() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK: return
	for channel_name in CHANNELS:
		mapping[String(channel_name)] = config.get_value("axes", channel_name, mapping[String(channel_name)])
		reversed[String(channel_name)] = config.get_value("reverse", channel_name, reversed[String(channel_name)])
		centers[String(channel_name)] = config.get_value("center", channel_name, centers[String(channel_name)])
		minimums[String(channel_name)] = config.get_value("minimum", channel_name, minimums[String(channel_name)])
		maximums[String(channel_name)] = config.get_value("maximum", channel_name, maximums[String(channel_name)])
	deadband = config.get_value("calibration", "deadband", deadband)
