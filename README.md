# RC Flight Lab

An engineering-oriented RC flight simulator prototype built with Godot 4. It targets macOS (Intel and Apple Silicon), Windows x86-64, and 64-bit Raspberry Pi from one codebase. The current prototype provides controller discovery, live axis diagnostics, persistent four-channel assignment/reversal/centering, keyboard fallback, a flyable fixed-wing trainer, and a realistic club-style flying field.

## Run

1. Install Godot 4.3 or newer from the official Godot site.
2. Import `project.godot` in Godot's Project Manager.
3. Press **F6/F5** to run.

## Standalone builds

Download the archive for your platform from the GitHub release page; Godot is
not required to run an exported build.

- **macOS:** unzip and open `RC Flight Lab.app`. The build is universal for
  Apple Silicon and Intel Macs. Because the initial release is ad-hoc signed,
  macOS may require **Control-click > Open** the first time.
- **Windows:** unzip and run `RC-Flight-Lab.exe` on 64-bit Windows.
- **Raspberry Pi:** use a 64-bit Raspberry Pi OS with desktop/OpenGL support,
  extract the `.tar.gz`, and run `./RC-Flight-Lab.arm64`.

The GitHub Actions release workflow compiles the native JSBSim bridge and
exports all three packages. A tag named `rc-flight-lab-v*` also publishes the
packages as a GitHub release.

## Controls and controller setup

Press **F1** for live controller axes and mapping. Godot/SDL-compatible USB HID controllers—including a Spektrum dongle when the OS exposes it as a joystick—are discovered generically; vendor IDs are not hard-coded. Select the axis for throttle, roll, pitch, and yaw, reverse it if needed, then center the three spring-centered sticks. Mappings are saved using Godot's per-user application-data path (`user://controller_mapping.cfg`), which is appropriate on both macOS and Windows.

Keyboard fallback: **W/S** throttle, **arrow keys** roll/pitch, **A/D** yaw, **R** reset, **C** camera mode, and **H** HUD visibility.

The trainer starts stationary on its landing gear near the end of the runway. Advance the throttle, allow it to build speed, and apply gentle up-elevator to rotate and take off. Resetting with **R** returns it to the same ground-start position.

## Visual presentation

The current scene uses the matching FlightGear/ArduPilot SIG Rascal 110 visual
model, converted to Godot-native OBJ/PNG assets and centered on the JSBSim CG.
Its ailerons, elevator, and rudder remain animated from the live transmitter
commands. A procedural high-wing model remains as a source-level fallback if
the imported assets are unavailable. Asset provenance and GPLv3 terms are in
`assets/models/rascal/README.md`.

An original panoramic rural flying-field backdrop is combined with 3D grass,
runway markings, safety fencing, cones, and a small hangar. The default
ground-pilot camera tracks the airplane and automatically narrows its field of
view with distance so the model remains readable during a normal circuit.
Chase and onboard cameras remain available with **C**.

## Physics

The trainer uses an explicit aerodynamic force model rather than only engine damping. Lift and induced/profile drag are calculated from dynamic pressure (`0.5 × density × airspeed²`), wing area, angle of attack, and configurable coefficients. Lift is capped and reduced past the stall angle. Control authority scales with dynamic pressure, so control surfaces weaken near zero airspeed. Thrust and angular damping are separately applied.

Aircraft parameters live in `src/aircraft/trainer_config.gd`; a future milestone will convert instances to `.tres` resources and add an editor UI.

### JSBSim advanced model

The `feature/rc-sim-jsbsim` branch contains an in-progress native integration
with JSBSim 1.3.1. The existing Godot force model is being retained as the
portable **Simple** mode; JSBSim will provide the nonlinear six-degree-of-
freedom **Advanced** mode.

The native bridge, pinned dependencies, build instructions, and smoke tests are
under `native/` and `tests/`. Advanced mode now loads a SIG Rascal 110 RC model,
maps transmitter commands into JSBSim, and converts JSBSim's NED state into the
Godot scene. The menu can switch between **JSBSim Rascal 110** and **Simple**;
if the native extension is absent, the simulator remains usable in Simple mode.

The Rascal data is an established ArduPilot/FlightGear baseline, but its upstream
notes call it early-stage rather than validated manufacturer test data. Its data
source and GPLv3-derived licensing caveat are documented in
`assets/jsbsim/README.md`.

## Coordinate convention

Godot coordinates are used consistently: **-Z forward, +X right, +Y up**. Positive body rotations follow Godot's right-hand convention. Aerodynamic calculations use SI units: metres, seconds, kilograms, Newtons, and radians.

## Engineering Assumptions and Simplifications

- The wing is represented by one lumped lifting surface; spanwise effects and sideslip are omitted.
- Air is still and has constant sea-level density. The wind model comes in a later milestone.
- Lift is perpendicular to the aircraft's body-forward direction, an approximation that becomes inaccurate in extreme attitudes.
- Stall is a smooth coefficient reduction rather than separated-flow simulation.
- Fuselage, tail, and landing-gear drag are currently combined into the profile-drag coefficient.
- Control surfaces generate direct moments scaled by dynamic pressure.
- The trainer CG defaults to 33% of the visible wing chord measured aft from the leading edge.
- The Rascal visual mesh is an older, modest-detail FlightGear asset; its fuselage and landing-gear collision shapes remain deliberately simple.

## Project roadmap

- **Milestone 1:** controller input and fixed-wing prototype.
- **Visual milestone 1 (current):** detailed trainer, realistic flying field, compact HUD, and distance-aware pilot camera.
- **Milestone 2:** quadcopter motor/rigid-body model and rate PID controller.
- **Milestone 3:** live PID lab, plots, step-response analysis, CSV logging.
- **Milestone 4:** wind, richer calibration/endpoints, configuration resources, tests, and instructional environments.

## Known limitations

Runtime controller behavior still needs validation with representative macOS and Windows hardware. Endpoint calibration, buttons/switch assignment, wind, quadcopter/PID features, data logging, and automated physics tests are deliberately deferred to later milestones per the incremental-delivery requirement.
