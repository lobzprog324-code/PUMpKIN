extends Node2D

const CHUNK_SCRIPT = preload("res://scripts/terrain_chunk.gd")
const PLAYER_SCRIPT = preload("res://scripts/player.gd")

@export var chunk_width: float = 1200.0
@export var view_chunks: int = 3

var world_seed: int = 0
var player: CharacterBody2D
var chunks: Dictionary = {}
var terrain_noise := FastNoiseLite.new()
var detail_noise := FastNoiseLite.new()
var ui_label: Label
var inventory := {"wood": 0, "stone": 0}

func _ready() -> void:
	world_seed = randi()
	terrain_noise.seed = world_seed
	terrain_noise.frequency = 0.0017
	terrain_noise.fractal_octaves = 4
	terrain_noise.fractal_gain = 0.48
	detail_noise.seed = world_seed + 7919
	detail_noise.frequency = 0.012
	detail_noise.fractal_octaves = 2

	player = PLAYER_SCRIPT.new()
	player.position = Vector2(0, 180)
	player.resource_collected.connect(_on_resource_collected)
	add_child(player)

	_build_ui()
	_update_chunks()

func _process(_delta: float) -> void:
	_update_chunks()
	if is_instance_valid(ui_label):
		ui_label.text = "WILDLANDS  |  ДЕРЕВО: %d  КАМЕНЬ: %d" % [inventory.wood, inventory.stone]

func _update_chunks() -> void:
	var center := int(floor(player.global_position.x / chunk_width))
	for offset in range(-view_chunks, view_chunks + 1):
		var index := center + offset
		if not chunks.has(index):
			var chunk = CHUNK_SCRIPT.new()
			chunk.chunk_index = index
			chunk.chunk_width = chunk_width
			chunk.terrain_noise = terrain_noise
			chunk.detail_noise = detail_noise
			chunk.resource_collected.connect(_on_resource_collected)
			add_child(chunk)
			chunks[index] = chunk
	for key in chunks.keys():
		if abs(int(key) - center) > view_chunks + 1:
			chunks[key].queue_free()
			chunks.erase(key)

func _on_resource_collected(kind: String, amount: int) -> void:
	if inventory.has(kind):
		inventory[kind] += amount

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(16, 14)
	layer.add_child(panel)
	ui_label = Label.new()
	ui_label.text = "WILDLANDS  |  ДЕРЕВО: 0  КАМЕНЬ: 0"
	ui_label.add_theme_font_size_override("font_size", 18)
	panel.add_child(ui_label)

	var hint := Label.new()
	hint.text = "A/D или ←/→ — движение   ПРОБЕЛ — прыжок   E — собрать рядом"
	hint.position = Vector2(16, 58)
	hint.add_theme_font_size_override("font_size", 15)
	layer.add_child(hint)

	var left := _make_touch_button("◀", Vector2(24, 610), layer)
	left.button_down.connect(func(): player.set_touch_axis(-1.0))
	left.button_up.connect(func(): player.set_touch_axis(0.0))
	var right := _make_touch_button("▶", Vector2(112, 610), layer)
	right.button_down.connect(func(): player.set_touch_axis(1.0))
	right.button_up.connect(func(): player.set_touch_axis(0.0))
	var jump := _make_touch_button("ПРЫЖОК", Vector2(1090, 610), layer)
	jump.button_down.connect(func(): player.request_jump())

func _make_touch_button(caption: String, pos: Vector2, parent: Node) -> Button:
	var button := Button.new()
	button.text = caption
	button.position = pos
	button.custom_minimum_size = Vector2(76, 68) if caption.length() < 4 else Vector2(130, 68)
	button.add_theme_font_size_override("font_size", 20)
	parent.add_child(button)
	return button
