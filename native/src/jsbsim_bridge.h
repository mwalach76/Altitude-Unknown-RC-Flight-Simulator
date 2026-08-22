#pragma once

#include <memory>
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/string.hpp>

namespace JSBSim { class FGFDMExec; }

namespace godot {

class JsbsimBridge : public RefCounted {
  GDCLASS(JsbsimBridge, RefCounted)

 public:
  JsbsimBridge();
  ~JsbsimBridge() override;

  bool initialize(const String &data_root, const String &aircraft_name,
                  double fixed_step_seconds = 1.0 / 120.0);
  bool reset(double altitude_m = 0.5, double airspeed_mps = 0.0,
             double heading_deg = 0.0, double pitch_deg = 0.0);
  Dictionary step(double throttle, double aileron, double elevator,
                  double rudder);
  Dictionary state() const;
  bool is_ready() const;
  String last_error() const;

 protected:
  static void _bind_methods();

 private:
  std::unique_ptr<JSBSim::FGFDMExec> fdm_;
  bool ready_ = false;
  double dt_ = 1.0 / 120.0;
  String error_;

  static double clamp_unit(double value);
};

}  // namespace godot
