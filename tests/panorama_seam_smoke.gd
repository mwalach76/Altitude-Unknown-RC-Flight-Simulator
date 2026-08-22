extends SceneTree

func _init() -> void:
	var source: Texture2D = load("res://assets/environment/rc_flying_field_panorama_v3.png")
	var image := FlyingField.make_seamless_panorama(source).get_image()
	if image.is_empty():
		_fail("Panorama failed to load")
		return
	var difference := 0.0
	var maximum := 0.0
	for y in image.get_height():
		var left := image.get_pixel(0, y)
		var right := image.get_pixel(image.get_width() - 1, y)
		var pixel_difference := absf(left.r - right.r) + absf(left.g - right.g) + absf(left.b - right.b)
		difference += pixel_difference
		maximum = maxf(maximum, pixel_difference)
	var average := difference / image.get_height()
	if average > 0.035 or maximum > 0.20:
		_fail("Panorama edge mismatch is too visible: average=%.4f maximum=%.4f" % [average, maximum])
		return
	print("PANORAMA_SEAM_PASS average=%.4f maximum=%.4f" % [average, maximum])
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
