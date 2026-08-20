class_name TrainerConfig
extends Resource

@export var mass_kg := 2.2
@export var wing_area_m2 := 0.52
@export var wing_span_m := 1.65
@export var mean_chord_m := 0.32
@export var max_thrust_n := 22.0
@export var cl_zero := 0.22
@export var cl_alpha_per_rad := 4.5
@export var cl_max := 1.25
@export var cd_zero := 0.035
@export var induced_drag_factor := 0.075
@export var stall_angle_rad := deg_to_rad(16.0)
@export var pitch_effectiveness := 4.2
@export var roll_effectiveness := 2.8
@export var yaw_effectiveness := 1.8
@export_range(0.0, 0.8, 0.05) var control_expo := 0.35
