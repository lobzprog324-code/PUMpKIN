extends Node2D

signal resource_collected(kind: String, amount: int)

@export var chunk_index: int = 0
@export var chunk_width: float = 1200.0
var terrain_noise: FastNoiseLite
var detail_noise: FastNoiseLite
var ground_body: StaticBody2D
var objects: Array[Dictionary] = []
const SURFACE_BASE := 465.0
const TERRAIN_AMPLITUDE := 145.0
const STEP := 24.0

func _ready() -> void:
	position.x = chunk_index * chunk_width
	_generate()
	queue_redraw()

func _surface_at(local_x: float) -> float:
	var world_x := position.x + local_x
	var broad := terrain_noise.get_noise_1d(world_x) * TERRAIN_AMPLITUDE
	var detail := detail_noise.get_noise_1d(world_x) * 13.0
	return SURFACE_BASE + broad + detail

func _generate() -> void:
	var points := PackedVector2Array()
	var x := 0.0
	while x <= chunk_width:
		points.append(Vector2(x, _surface_at(x)))
		x += STEP
	points.append(Vector2(chunk_width, 1100))
	points.append(Vector2(0, 1100))

	ground_body = StaticBody2D.new()
	add_child(ground_body)
	var polygon := CollisionPolygon2D.new()
	polygon.polygon = points
	ground_body.add_child(polygon)

	var rng := RandomNumberGenerator.new()
	rng.seed = int(hash(str(terrain_noise.seed, ":", chunk_index)))
	var tree_x := rng.randf_range(70.0, 150.0)
	while tree_x < chunk_width - 50.0:
		if rng.randf() < 0.72:
			var surface_y := _surface_at(tree_x)
			objects.append({"kind":"tree", "x":tree_x, "y":surface_y, "height":rng.randf_range(105, 185), "width":rng.randf_range(18, 27)})
		tree_x += rng.randf_range(95.0, 210.0)

	var rock_count := rng.randi_range(2, 6)
	for i in range(rock_count):
		var rock_x := rng.randf_range(35.0, chunk_width - 35.0)
		objects.append({"kind":"rock", "x":rock_x, "y":_surface_at(rock_x), "size":rng.randf_range(14, 30)})

func _draw() -> void:
	var top := PackedVector2Array()
	var x := 0.0
	while x <= chunk_width:
		top.append(Vector2(x, _surface_at(x)))
		x += STEP
	top.append(Vector2(chunk_width, 1100))
	top.append(Vector2(0, 1100))
	draw_colored_polygon(top, Color("#514b3e"))

	for i in range(1, 7):
		var yoff := i * 34.0
		var line := PackedVector2Array()
		for px in range(0, int(chunk_width) + 1, 48):
			line.append(Vector2(px, _surface_at(px) + yoff + sin(float(px) * 0.018 + i) * 5.0))
		if line.size() > 1:
			draw_polyline(line, Color("#393b35"), 2.0)

	for obj in objects:
		if obj.kind == "tree":
			var w: float = obj.width
			var h: float = obj.height
			var p := Vector2(obj.x, obj.y)
			draw_rect(Rect2(p.x - w * 0.5, p.y - h * 0.58, w, h * 0.58), Color("#55402d"))
			draw_circle(Vector2(p.x, p.y - h * 0.68), h * 0.30, Color("#344b35"))
			draw_circle(Vector2(p.x - h * 0.13, p.y - h * 0.58), h * 0.22, Color("#405b3a"))
			draw_circle(Vector2(p.x + h * 0.14, p.y - h * 0.55), h * 0.21, Color("#293f30"))
		else:
			var s: float = obj.size
			var p := Vector2(obj.x, obj.y - s * 0.35)
			draw_colored_polygon(PackedVector2Array([p + Vector2(-s, s*0.35), p + Vector2(-s*0.55,-s*0.55), p + Vector2(s*0.4,-s*0.7), p + Vector2(s, s*0.35)]), Color("#77766d"))

func interact_near(world_position: Vector2) -> bool:
	for i in range(objects.size()):
		var obj: Dictionary = objects[i]
		var obj_world := Vector2(position.x + obj.x, obj.y)
		if world_position.distance_to(obj_world) < 105.0:
			if obj.kind == "tree":
				resource_collected.emit("wood", 3)
			else:
				resource_collected.emit("stone", 2)
			objects.remove_at(i)
			queue_redraw()
			return true
	return false
