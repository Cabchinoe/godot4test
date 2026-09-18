class_name EnemySpriteFramesFactory
extends RefCounted


static func build(animation_sheets: Dictionary, frame_size: Vector2i = Vector2i(64, 80)) -> SpriteFrames:
	if animation_sheets.is_empty():
		return null
	var sprite_frames := SpriteFrames.new()
	for animation_name in ["idle", "walk", "aim"]:
		var animation_data: Variant = animation_sheets.get(animation_name, {})
		if not (animation_data is Dictionary):
			continue
		var config := animation_data as Dictionary
		var path := str(config.get("path", ""))
		var texture := load(path) as Texture2D
		if texture == null:
			push_warning("EnemySpriteFramesFactory: failed to load %s" % path)
			return null
		if not sprite_frames.has_animation(animation_name):
			sprite_frames.add_animation(animation_name)
		sprite_frames.set_animation_loop(animation_name, true)
		sprite_frames.set_animation_speed(animation_name, float(config.get("speed", 2.0)))
		var frame_count := maxi(1, int(config.get("frames", 1)))
		for frame_index in frame_count:
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(frame_index * frame_size.x, 0, frame_size.x, frame_size.y)
			sprite_frames.add_frame(animation_name, atlas)
	return sprite_frames
