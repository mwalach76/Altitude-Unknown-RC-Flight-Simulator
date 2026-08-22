#include "jsbsim_bridge.h"

#include <FGFDMExec.h>
#include <simgear/misc/sg_path.hxx>
#include <godot_cpp/core/class_db.hpp>

namespace godot {

JsbsimBridge::JsbsimBridge() = default;
JsbsimBridge::~JsbsimBridge() = default;

void JsbsimBridge::_bind_methods() {
  ClassDB::bind_method(D_METHOD("initialize", "data_root", "aircraft_name",
                                "fixed_step_seconds"),
                       &JsbsimBridge::initialize, DEFVAL(1.0 / 120.0));
  ClassDB::bind_method(D_METHOD("reset", "altitude_m", "airspeed_mps",
                                "heading_deg"),
                       &JsbsimBridge::reset, DEFVAL(0.5), DEFVAL(0.0),
                       DEFVAL(0.0));
  ClassDB::bind_method(D_METHOD("step", "throttle", "aileron", "elevator",
                                "rudder"),
                       &JsbsimBridge::step);
  ClassDB::bind_method(D_METHOD("state"), &JsbsimBridge::state);
  ClassDB::bind_method(D_METHOD("is_ready"), &JsbsimBridge::is_ready);
  ClassDB::bind_method(D_METHOD("last_error"), &JsbsimBridge::last_error);
}

double JsbsimBridge::clamp_unit(double value) {
  return value < -1.0 ? -1.0 : (value > 1.0 ? 1.0 : value);
}

bool JsbsimBridge::initialize(const String &data_root,
                              const String &aircraft_name,
                              double fixed_step_seconds) {
  ready_ = false;
  error_ = "";
  dt_ = fixed_step_seconds > 0.0 ? fixed_step_seconds : 1.0 / 120.0;
  fdm_ = std::make_unique<JSBSim::FGFDMExec>();
  fdm_->SetDebugLevel(0);
  fdm_->SetRootDir(SGPath(data_root.utf8().get_data()));
  fdm_->SetAircraftPath(SGPath("aircraft"));
  fdm_->SetEnginePath(SGPath("engine"));
  fdm_->SetSystemsPath(SGPath("systems"));
  fdm_->Setdt(dt_);

  if (!fdm_->LoadModel(aircraft_name.utf8().get_data())) {
    error_ = "JSBSim could not load aircraft '" + aircraft_name +
             "' from " + data_root;
    fdm_.reset();
    return false;
  }

  ready_ = true;
  return reset();
}

bool JsbsimBridge::reset(double altitude_m, double airspeed_mps,
                         double heading_deg) {
  if (!fdm_) {
    error_ = "JSBSim is not initialized";
    return false;
  }

  fdm_->SetPropertyValue("ic/h-sl-ft", altitude_m * 3.280839895);
  fdm_->SetPropertyValue("ic/terrain-elevation-ft", 0.0);
  fdm_->SetPropertyValue("ic/u-fps", airspeed_mps * 3.280839895);
  fdm_->SetPropertyValue("ic/v-fps", 0.0);
  fdm_->SetPropertyValue("ic/w-fps", 0.0);
  fdm_->SetPropertyValue("ic/psi-true-deg", heading_deg);
  fdm_->SetPropertyValue("ic/phi-deg", 0.0);
  fdm_->SetPropertyValue("ic/theta-deg", 0.0);

  if (!fdm_->RunIC()) {
    error_ = "JSBSim initial-condition solve failed";
    ready_ = false;
    return false;
  }
  ready_ = true;
  return true;
}

Dictionary JsbsimBridge::step(double throttle, double aileron,
                              double elevator, double rudder) {
  if (!ready_ || !fdm_) return state();

  fdm_->SetPropertyValue("fcs/throttle-cmd-norm", throttle < 0.0 ? 0.0 :
      (throttle > 1.0 ? 1.0 : throttle));
  fdm_->SetPropertyValue("fcs/aileron-cmd-norm", clamp_unit(aileron));
  fdm_->SetPropertyValue("fcs/elevator-cmd-norm", clamp_unit(elevator));
  fdm_->SetPropertyValue("fcs/rudder-cmd-norm", clamp_unit(rudder));

  if (!fdm_->Run()) {
    error_ = "JSBSim stopped while advancing the simulation";
    ready_ = false;
  }
  return state();
}

Dictionary JsbsimBridge::state() const {
  Dictionary result;
  result["ready"] = ready_;
  if (!fdm_) return result;

  result["time_s"] = fdm_->GetPropertyValue("simulation/sim-time-sec");
  result["altitude_m"] = fdm_->GetPropertyValue("position/h-agl-ft") * 0.3048;
  result["airspeed_mps"] = fdm_->GetPropertyValue("velocities/vtrue-fps") * 0.3048;
  result["north_mps"] = fdm_->GetPropertyValue("velocities/v-north-fps") * 0.3048;
  result["east_mps"] = fdm_->GetPropertyValue("velocities/v-east-fps") * 0.3048;
  result["down_mps"] = fdm_->GetPropertyValue("velocities/v-down-fps") * 0.3048;
  result["roll_rad"] = fdm_->GetPropertyValue("attitude/phi-rad");
  result["pitch_rad"] = fdm_->GetPropertyValue("attitude/theta-rad");
  result["heading_rad"] = fdm_->GetPropertyValue("attitude/psi-rad");
  result["p_rad_s"] = fdm_->GetPropertyValue("velocities/p-rad_sec");
  result["q_rad_s"] = fdm_->GetPropertyValue("velocities/q-rad_sec");
  result["r_rad_s"] = fdm_->GetPropertyValue("velocities/r-rad_sec");
  return result;
}

bool JsbsimBridge::is_ready() const { return ready_; }
String JsbsimBridge::last_error() const { return error_; }

}  // namespace godot
