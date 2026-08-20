# RC Flight Lab

An engineering-oriented RC flight simulator prototype built with Godot 4. It targets macOS (Intel and Apple Silicon) and Windows from one codebase. Milestone 1 provides controller discovery, live axis diagnostics, persistent four-channel assignment/reversal/centering, keyboard fallback, and a flyable fixed-wing trainer.

## Run

1. Install Godot 4.3 or newer from the official Godot site.
2. Import `project.godot` in Godot's Project Manager.
3. Press **F6/F5** to run.

Godot's standard desktop export templates produce `.app`/universal macOS builds and Windows `.exe` builds. No platform-specific dependency is used.

## Controls and controller setup

Press **F1** for live controller axes and mapping. Godot/SDL-compatible USB HID controllers—including a Spektrum dongle when the OS exposes it as a joystick—are discovered generically; vendor IDs are not hard-coded. Select the axis for throttle, roll, pitch, and yaw, reverse it if needed, then center the three spring-centered sticks. Mappings are saved using Godot's per-user application-data path (`user://controller_mapping.cfg`), which is appropriate on both macOS and Windows.

Keyboard fallback: **W/S** throttle, **arrow keys** roll/pitch, **A/D** yaw, **R** reset, and **C** camera mode.

## Physics

The trainer uses an explicit aerodynamic force model rather than only engine damping. Lift and induced/profile drag are calculated from dynamic pressure (`0.5 × density × airspeed²`), wing area, angle of attack, and configurable coefficients. Lift is capped and reduced past the stall angle. Control authority scales with dynamic pressure, so control surfaces weaken near zero airspeed. Thrust and angular damping are separately applied.

Aircraft parameters live in `src/aircraft/trainer_config.gd`; a future milestone will convert instances to `.tres` resources and add an editor UI.

## Coordinate convention

Godot coordinates are used consistently: **-Z forward, +X right, +Y up**. Positive body rotations follow Godot's right-hand convention. Aerodynamic calculations use SI units: metres, seconds, kilograms, Newtons, and radians.

## Engineering Assumptions and Simplifications

- The wing is represented by one lumped lifting surface; spanwise effects and sideslip are omitted.
- Air is still and has constant sea-level density. The wind model comes in a later milestone.
- Lift is perpendicular to the aircraft's body-forward direction, an approximation that becomes inaccurate in extreme attitudes.
- Stall is a smooth coefficient reduction rather than separated-flow simulation.
- Fuselage, tail, and landing-gear drag are currently combined into the profile-drag coefficient.
- Control surfaces generate direct moments scaled by dynamic pressure.
- The visual model and collision box are deliberately simple.

## Project roadmap

- **Milestone 1 (current):** controller input and fixed-wing prototype.
- **Milestone 2:** quadcopter motor/rigid-body model and rate PID controller.
- **Milestone 3:** live PID lab, plots, step-response analysis, CSV logging.
- **Milestone 4:** wind, richer calibration/endpoints, configuration resources, tests, and instructional environments.

## Known limitations

Runtime controller behavior still needs validation with representative macOS and Windows hardware. Endpoint calibration, buttons/switch assignment, wind, quadcopter/PID features, data logging, and automated physics tests are deliberately deferred to later milestones per the incremental-delivery requirement.
