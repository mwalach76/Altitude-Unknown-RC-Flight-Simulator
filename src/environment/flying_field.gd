class_name FlyingField
extends Node3D

const PANORAMA := preload("res://assets/environment/rc_flying_field_panorama_v3.png")

var _windsock_pivot: Node3D
var _windsock_time := 0.0

func _process(delta: float) -> void:
	if _windsock_pivot == null:
		return
	_windsock_time += delta
	_windsock_pivot.rotation.z = deg_to_rad(4.0 + sin(_windsock_time * 1.7) * 3.0)
	_windsock_pivot.rotation.y = deg_to_rad(sin(_windsock_time * 0.45) * 4.0)

func build() -> WorldEnvironment:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	var sky := Sky.new()
	var panorama := PanoramaSkyMaterial.new()
	panorama.panorama = make_seamless_panorama(PANORAMA)
	sky.sky_material = panorama
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("dce6ed")
	environment.ambient_light_sky_contribution = 0.3
	environment.ambient_light_energy = 0.58
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.05
	world.environment = environment
	add_child(world)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_color = Color("fff5df")
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 180.0
	add_child(sun)
	_add_ground()
	_add_runway()
	_add_pilot_area()
	_add_hangar(Vector3(-38, 0, -34))
	_add_markers()
	return world

static func make_seamless_panorama(source: Texture2D) -> ImageTexture:
	var image := source.get_image()
	var width := image.get_width()
	var blend_width := mini(128, width / 8)
	# Cross-blend corresponding pixels on both sides of the wrap. The boundary
	# columns become identical, while smoothstep makes the correction disappear
	# gradually before it reaches the untouched center of the panorama.
	for y in image.get_height():
		for offset in blend_width:
			var left_x := offset
			var right_x := width - 1 - offset
			var left := image.get_pixel(left_x, y)
			var right := image.get_pixel(right_x, y)
			var shared := left.lerp(right, 0.5)
			var keep_original := smoothstep(0.0, 1.0, float(offset) / float(blend_width - 1))
			image.set_pixel(left_x, y, shared.lerp(left, keep_original))
			image.set_pixel(right_x, y, shared.lerp(right, keep_original))
	return ImageTexture.create_from_image(image)

func _add_ground() -> void:
	var ground := StaticBody3D.new()
	var mesh_instance := MeshInstance3D.new()
	var plane := BoxMesh.new()
	plane.size = Vector3(360, 0.1, 360)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("315f32")
	material.roughness = 0.96
	plane.material = material
	mesh_instance.mesh = plane
	ground.add_child(mesh_instance)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = plane.size
	collider.shape = shape
	ground.add_child(collider)
	ground.position.y = -0.05
	add_child(ground)

func _add_runway() -> void:
	_add_box(Vector3(0, 0.015, -24), Vector3(9, 0.03, 105), Color("3d4142"), 0.92)
	_add_box(Vector3(-4.25, 0.036, -24), Vector3(0.12, 0.012, 103), Color("e8e7dc"), 0.75)
	_add_box(Vector3(4.25, 0.036, -24), Vector3(0.12, 0.012, 103), Color("e8e7dc"), 0.75)
	for z in range(-70, 26, 12):
		_add_box(Vector3(0, 0.038, z), Vector3(0.16, 0.014, 5.0), Color("eeeade"), 0.7)

func _add_pilot_area() -> void:
	_add_box(Vector3(13, 0.025, 17), Vector3(12, 0.04, 4), Color("aa9b79"), 0.95)
	for x in range(8, 19, 2):
		_add_box(Vector3(x, 0.6, 14.5), Vector3(0.06, 1.2, 0.06), Color("5b6060"), 0.65)
	_add_box(Vector3(13, 1.15, 14.5), Vector3(10.2, 0.05, 0.05), Color("5b6060"), 0.65)

func _add_hangar(pos: Vector3) -> void:
	_add_box(pos + Vector3(0, 2.2, 0), Vector3(10, 4.4, 7), Color("d8d1bf"), 0.8)
	_add_box(pos + Vector3(0, 2.0, 3.52), Vector3(7.2, 3.7, 0.08), Color("45515b"), 0.72)
	_add_box(pos + Vector3(0, 4.55, 0), Vector3(10.8, 0.18, 7.8), Color("8b3d32"), 0.7)
	_add_hangar_sign(pos)
	_add_rooftop_windsock(pos)

func _add_hangar_sign(pos: Vector3) -> void:
	var sign := Label3D.new()
	sign.name = "AscendHangarSign"
	sign.text = "ASCEND"
	sign.font_size = 160
	sign.pixel_size = 0.012
	sign.modulate = Color("f6f2e8")
	sign.outline_modulate = Color("28343b")
	sign.outline_size = 14
	sign.position = pos + Vector3(0, 2.8, 3.57)
	add_child(sign)

func _add_rooftop_windsock(pos: Vector3) -> void:
	var pole_material := _make_material(Color("b8bec2"), 0.38, 0.55)
	var pole := MeshInstance3D.new()
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.035
	pole_mesh.bottom_radius = 0.035
	pole_mesh.height = 2.2
	pole_mesh.radial_segments = 12
	pole_mesh.material = pole_material
	pole.mesh = pole_mesh
	pole.position = pos + Vector3(0, 5.75, 0)
	add_child(pole)

	_windsock_pivot = Node3D.new()
	_windsock_pivot.name = "RooftopWindsock"
	_windsock_pivot.position = pos + Vector3(0, 6.82, 0)
	add_child(_windsock_pivot)
	var colors := [Color("ef5b2a"), Color("f6f1df"), Color("ef5b2a"), Color("f6f1df")]
	for index in 4:
		var section := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.height = 0.48
		mesh.bottom_radius = 0.22 - index * 0.04
		mesh.top_radius = 0.18 - index * 0.04
		mesh.radial_segments = 16
		mesh.material = _make_material(colors[index], 0.72)
		section.mesh = mesh
		section.rotation.z = deg_to_rad(-90.0)
		section.position.x = 0.24 + index * 0.46
		_windsock_pivot.add_child(section)

func _make_material(color: Color, roughness: float, metallic := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material

func _add_markers() -> void:
	for z in range(-68, 22, 10):
		_add_cone(Vector3(-5.2, 0.18, z))
		_add_cone(Vector3(5.2, 0.18, z))

func _add_cone(pos: Vector3) -> void:
	var instance := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.025
	cone.bottom_radius = 0.16
	cone.height = 0.36
	cone.radial_segments = 12
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("f17b28")
	material.roughness = 0.72
	cone.material = material
	instance.mesh = cone
	instance.position = pos
	add_child(instance)

func _add_box(pos: Vector3, size: Vector3, color: Color, roughness: float) -> void:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	mesh.material = material
	instance.mesh = mesh
	instance.position = pos
	add_child(instance)
