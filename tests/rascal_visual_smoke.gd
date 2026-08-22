extends SceneTree

const EXPECTED_SPAN_M := 2.79

func _init() -> void:
	var paths := [
		"res://assets/models/rascal/rascal_body.obj",
		"res://assets/models/rascal/l_aileron.obj",
		"res://assets/models/rascal/r_aileron.obj",
		"res://assets/models/rascal/elevator.obj",
		"res://assets/models/rascal/rudder.obj",
		"res://assets/models/rascal/prop_disk.obj",
	]
	for path in paths:
		var mesh: Mesh = load(path)
		if mesh == null or mesh.get_surface_count() == 0:
			_fail("Rascal mesh failed to import: " + path)
			return
	var body: Mesh = load(paths[0])
	var span := body.get_aabb().size.x
	if absf(span - EXPECTED_SPAN_M) > 0.08:
		_fail("Rascal visual span is incorrect: %.3f m" % span)
		return
	var textured_surfaces := 0
	for surface_index in body.get_surface_count():
		var material := body.surface_get_material(surface_index)
		if material is BaseMaterial3D and material.albedo_texture != null:
			textured_surfaces += 1
	if textured_surfaces == 0:
		_fail("Rascal texture was not attached to the imported mesh")
		return
	print("RASCAL_VISUAL_PASS span_m=", span, " surfaces=", body.get_surface_count(), " textured=", textured_surfaces)
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
