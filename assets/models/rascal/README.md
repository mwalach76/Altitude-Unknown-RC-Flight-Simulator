# SIG Rascal 110 visual model

This is a Godot-ready conversion of the FlightGear/ArduPilot SIG Rascal 110
model. The original `Rascal110-000-013.ac` geometry and `Rascal.rgb` texture
were retrieved from:

https://github.com/ArduPilot/ardupilot/tree/master/Tools/autotest/aircraft/Rascal/Models

The geometry is converted to OBJ by `tools/convert_ac3d_to_obj.py`; the SGI
texture is losslessly converted to PNG. Geometry is recentered on the JSBSim
CG and split into the body, ailerons, elevator, and rudder so Godot can animate
the flight controls.

The upstream FlightGear-Rascal repository identifies the model as GPLv3. The
full license is included as `LICENSE-GPLv3.txt`. The converted OBJ meshes and
PNG texture remain derived from that GPLv3 asset.
