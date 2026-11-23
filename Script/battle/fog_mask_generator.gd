class_name FogMaskGenerator
extends RefCounted

const SIZE := 64
const PIXELS := SIZE * SIZE
const EDGE_WIDTH := 12.0
const SIGMA := 11.0
const KERNEL_RADIUS := 33
const FOG_RGB := Color8(66, 84, 94)
const RECIPE_VERSION := 1
const MATRIX_INDICES := [8, 1, 2, 7, 0, 3, 6, 5, 4]

var shapes: Dictionary = {}
var recipe_id := ""
var _axis_weights: Array[PackedFloat32Array] = []
var _rgba_template := PackedByteArray()


func _init() -> void:
	recipe_id = "fog-cpu-v%d:%d:%.3f:%.3f:%d:%d,%d,%d:rgba8" % [
		RECIPE_VERSION, SIZE, EDGE_WIDTH, SIGMA, KERNEL_RADIUS,
		FOG_RGB.r8, FOG_RGB.g8, FOG_RGB.b8,
	]
	_rgba_template.resize(PIXELS * 4)
	for pixel in PIXELS:
		_rgba_template[pixel * 4] = FOG_RGB.r8
		_rgba_template[pixel * 4 + 1] = FOG_RGB.g8
		_rgba_template[pixel * 4 + 2] = FOG_RGB.b8
	_build_axis_weights()


func _build_axis_weights() -> void:
	var kernel := PackedFloat64Array()
	var total := 0.0
	for offset in range(-KERNEL_RADIUS, KERNEL_RADIUS + 1):
		var weight := exp(-float(offset * offset) / (2.0 * SIGMA * SIGMA))
		kernel.append(weight)
		total += weight
	for column in SIZE:
		var weights := PackedFloat32Array([0.0, 0.0, 0.0])
		for offset in range(-KERNEL_RADIUS, KERNEL_RADIUS + 1):
			var sample_column := column + offset
			var region := 0 if sample_column < 0 else (2 if sample_column >= SIZE else 1)
			weights[region] += kernel[offset + KERNEL_RADIUS] / total
		_axis_weights.append(weights)


func get_shape(mask: int) -> PackedByteArray:
	if shapes.has(mask):
		return shapes[mask]
	var alpha := PackedByteArray()
	alpha.resize(PIXELS)
	for row in SIZE:
		var top := row < SIZE / 2
		var distance_y := float(row) + 0.5 if top else float(SIZE - row) - 0.5
		var vertical := bool(mask & (1 << (0 if top else 4)))
		for column in SIZE:
			var left := column < SIZE / 2
			var distance_x := float(column) + 0.5 if left else float(SIZE - column) - 0.5
			var horizontal := bool(mask & (1 << (6 if left else 2)))
			var diagonal_index := (7 if left else 1) if top else (5 if left else 3)
			var coverage := 1.0
			if horizontal and vertical:
				if not (mask & (1 << diagonal_index)):
					coverage = smoothstep(0.0, EDGE_WIDTH, Vector2(distance_x, distance_y).length())
			elif horizontal:
				coverage = smoothstep(0.0, EDGE_WIDTH, distance_y)
			elif vertical:
				coverage = smoothstep(0.0, EDGE_WIDTH, distance_x)
			else:
				coverage = smoothstep(0.0, EDGE_WIDTH, distance_x) * smoothstep(0.0, EDGE_WIDTH, distance_y)
			alpha[row * SIZE + column] = roundi(coverage * 255.0)
	shapes[mask] = alpha
	return alpha


func generate_alpha(descriptor: Dictionary) -> PackedByteArray:
	var shape := get_shape(int(descriptor["shape_mask"]))
	var samples: PackedByteArray = descriptor["samples"]
	var alpha := PackedByteArray()
	alpha.resize(PIXELS)
	if bool(descriptor["uniform"]):
		var opacity := float(samples[0]) / 10.0
		for pixel in PIXELS:
			alpha[pixel] = roundi(float(shape[pixel]) * opacity)
		return alpha
	var numerators := PackedFloat32Array()
	var denominators := PackedFloat32Array()
	numerators.resize(SIZE * 3)
	denominators.resize(SIZE * 3)
	for column in SIZE:
		var weights := _axis_weights[column]
		for region_row in 3:
			var numerator := 0.0
			var denominator := 0.0
			for region_column in 3:
				var density: int = samples[MATRIX_INDICES[region_row * 3 + region_column]]
				if density > 0:
					numerator += weights[region_column] * float(density)
					denominator += weights[region_column]
			numerators[column * 3 + region_row] = numerator
			denominators[column * 3 + region_row] = denominator
	for row in SIZE:
		var weights := _axis_weights[row]
		for column in SIZE:
			var offset := column * 3
			var numerator := weights[0] * numerators[offset] + weights[1] * numerators[offset + 1] + weights[2] * numerators[offset + 2]
			var denominator := weights[0] * denominators[offset] + weights[1] * denominators[offset + 1] + weights[2] * denominators[offset + 2]
			var density := numerator / denominator if denominator > 0.00001 else float(samples[0])
			alpha[row * SIZE + column] = clampi(roundi(float(shape[row * SIZE + column]) * density / 10.0), 0, 204)
	return alpha


func make_image(alpha: PackedByteArray) -> Image:
	var rgba := _rgba_template.duplicate()
	for pixel in PIXELS:
		rgba[pixel * 4 + 3] = alpha[pixel]
	return Image.create_from_data(SIZE, SIZE, false, Image.FORMAT_RGBA8, rgba)


func blend_alpha(previous: PackedByteArray, target: PackedByteArray, fraction: float) -> PackedByteArray:
	var alpha := PackedByteArray()
	alpha.resize(PIXELS)
	for pixel in PIXELS:
		alpha[pixel] = roundi(lerpf(float(previous[pixel]), float(target[pixel]), fraction))
	return alpha
