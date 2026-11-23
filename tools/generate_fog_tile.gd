extends SceneTree

const OUTPUT_DIR := "res://Art/tilesets/urban_night/_review/fog_of_war"


func _initialize() -> void:
	var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	if error != OK:
		push_error("Cannot create fog review directory: %s" % error)
		quit(1)
		return
	var master := _make_image(1024)
	var tile := _make_image(64)
	var preview := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	for row in 2:
		for column in 2:
			preview.blit_rect(tile, Rect2i(0, 0, 64, 64), Vector2i(column * 64, row * 64))
	for entry in [
		[master, "fog_of_war_master_01.png"],
		[tile, "fog_of_war_01.png"],
		[preview, "fog_of_war_repeat_01.png"],
	]:
		var result: int = entry[0].save_png(OUTPUT_DIR.path_join(entry[1]))
		if result != OK:
			push_error("Cannot save fog image: %s" % entry[1])
			quit(1)
			return
	for row in 64:
		for column in 64:
			assert(tile.get_pixel(column, row).a == 1.0)
		assert(tile.get_pixel(0, row) == tile.get_pixel(63, row))
		assert(tile.get_pixel(row, 0) == tile.get_pixel(row, 63))
	print("Fog candidate: 64x64 RGBA8, alpha=255, opposite edges match exactly.")
	print("Master: 1024x1024. Repeat preview: 128x128. All files remain in _review.")
	quit()


func _make_image(size: int) -> Image:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for row in size:
		var phase_y := TAU * float(row % (size - 1)) / float(size - 1)
		for column in size:
			var phase_x := TAU * float(column % (size - 1)) / float(size - 1)
			var cloud := (
				3.5 * cos(phase_x + 0.7) * sin(phase_y + 1.2)
				+ 2.0 * sin(2.0 * phase_x + phase_y)
				+ 1.0 * cos(phase_x - 3.0 * phase_y + 0.4)
			)
			var shade := 32 + roundi(cloud)
			image.set_pixel(column, row, Color8(shade, shade + 2, shade + 4, 255))
	return image
