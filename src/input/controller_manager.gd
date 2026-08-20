class_name ControllerManager
extends Node

const SAVE_PATH := "user://controller_mapping.cfg"
const CHANNELS := [&"throttle", &"roll", &"pitch", &"yaw"]

var device_id := -1
var mapping := {"throttle": 1, "roll": 0, "pitch": 1, "yaw": 2}
var reversed := {"throttle": true, "roll": false, "pitch": true, "yaw": false}
var centers := {"throttle": 0.0, "roll": 0.0, "pitch": 0.0, "yaw": 0.0}
var deadband := 0.04
var throttle_keyboard := 0.0

func _ready() -> void:
	Input.joy_connection_changed.connect(_on_connection_changed)
	load_mapping()
	select_first_device()

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
	var value := raw_axis(int(mapping.get(String(channel), 0))) - float(centers.get(String(channel), 0.0))
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

func save_mapping() -> void:
	var config := ConfigFile.new()
	for channel_name in CHANNELS:
		config.set_value("axes", channel_name, mapping[String(channel_name)])
		config.set_value("reverse", channel_name, reversed[String(channel_name)])
		config.set_value("center", channel_name, centers[String(channel_name)])
	config.set_value("calibration", "deadband", deadband)
	config.save(SAVE_PATH)

func load_mapping() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK: return
	for channel_name in CHANNELS:
		mapping[String(channel_name)] = config.get_value("axes", channel_name, mapping[String(channel_name)])
		reversed[String(channel_name)] = config.get_value("reverse", channel_name, reversed[String(channel_name)])
		centers[String(channel_name)] = config.get_value("center", channel_name, centers[String(channel_name)])
	deadband = config.get_value("calibration", "deadband", deadband)
