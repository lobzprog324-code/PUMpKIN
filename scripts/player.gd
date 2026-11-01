extends CharacterBody2D

signal resource_collected(kind: String, amount: int)

const SPEED := 245.0
const ACCELERATION := 1050.0
const FRICTION := 1350.0
const JUMP_VELOCITY := -470.0
const GRAVITY := 1250.0

var touch_axis := 0.0
var facing := 1.0
var health := 100.0
var hunger := 100.0
var thirst := 100.0
var stamina := 100.0
var action_cooldown := 0.0

func _ready() -> void:
	var camera := Camera2D.new()
	camera.position = Vector2(0, -210)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	add_child(camera)
	camera.make_current()
	collision_layer = 1
	collision_mask = 1
	var shape := CapsuleShape2D.new()
	shape.radius = 15.0
	shape.height = 66.0
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position.y = -34.0
	add_child(collision)
	queue_redraw()

func _physics_process(delta: float) -> void:
	var axis := Input.get_axis("ui_left", "ui_right")
	if abs(touch_axis) > 0.01:
		axis = touch_axis
	if Input.is_key_pressed(KEY_A):
		axis = -1.0
	elif Input.is_key_pressed(KEY_D):
		axis = 1.0

	if axis != 0.0:
		facing = sign(axis)
		velocity.x = move_toward(velocity.x, axis * SPEED, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	elif Input.is_action_just_pressed("ui_accept"):
		request_jump()

	if action_cooldown > 0.0:
		action_cooldown -= delta

	move_and_slide()
	queue_redraw()

func set_touch_axis(value: float) -> void:
	touch_axis = value

func request_jump() -> void:
	if is_on_floor():
		velocity.y = JUMP_VELOCITY

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		_try_interact()

func _try_interact() -> void:
	if action_cooldown > 0.0:
		return
	action_cooldown = 0.35
	var game := get_parent()
	for chunk in game.get_children():
		if chunk.has_method("interact_near"):
			if chunk.interact_near(global_position + Vector2(facing * 55.0, -25.0)):
				return

func _draw() -> void:
	var skin := Color("#c49a78")
	var clothes := Color("#394b50")
	draw_circle(Vector2(0, -58), 12, skin)
	draw_rect(Rect2(-11, -47, 22, 34), clothes)
	draw_line(Vector2(-7, -17), Vector2(-10, 0), Color("#262d31"), 7)
	draw_line(Vector2(7, -17), Vector2(10, 0), Color("#262d31"), 7)
	draw_line(Vector2(-9, -42), Vector2(-19, -22), skin, 6)
	draw_line(Vector2(9, -42), Vector2(19, -24), skin, 6)
