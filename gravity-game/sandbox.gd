@tool
extends Node2D
## Sandbox — оригинальный тестовый уровень со всеми механиками.
## Сохранён как есть. Запускать через смену main_scene в project.godot на sandbox.tscn.

# ── Палитра ──────────────────────────────────────────
const C_WALL   := Color(0.25, 0.25, 0.30)
const C_PLAT   := Color(0.45, 0.45, 0.55)
const C_SPRING := Color(0.15, 0.90, 0.35)
const C_GOAL   := Color(1.00, 0.85, 0.10, 0.85)
const C_SPIKE  := Color(0.90, 0.15, 0.15)
const C_MOVING := Color(0.60, 0.35, 0.70)
const C_FLIP   := Color(0.20, 0.80, 0.90, 0.85)
const C_IFLIP  := Color(0.90, 0.50, 0.20, 0.85)
const C_STICKY := Color(0.85, 0.65, 0.10)
const C_NOGRV  := Color(0.55, 0.20, 0.70, 0.25)
const C_CONV   := Color(0.30, 0.75, 0.55)

const PLAYER_START := Vector2(120, 280)
const W := 1152.0
const H := 648.0
const THICK := 20.0

var player: CharacterBody2D
var gravity_label: Label
var dir_label: Label
var hint_label: Label
var bar_fill: ColorRect
var bar_center_y: float

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.10, 0.10, 0.14))
	_build_walls()
	_build_platforms()
	_build_moving_platforms()
	_build_rotating_obstacles()
	_build_springs()
	_build_spikes()
	_build_conveyors()
	_build_sticky_surfaces()
	_build_antigrav_zones()
	_build_gravity_flippers()
	_build_interact_flippers()
	_build_goal()
	_build_player()
	_build_hud()

func _build_walls() -> void:
	_static_rect(Vector2(W / 2, THICK / 2),       Vector2(W, THICK), 0, C_WALL)
	_static_rect(Vector2(W / 2, H - THICK / 2),   Vector2(W, THICK), 0, C_WALL)
	_static_rect(Vector2(THICK / 2, H / 2),        Vector2(THICK, H), 0, C_WALL)
	_static_rect(Vector2(W - THICK / 2, H / 2),    Vector2(THICK, H), 0, C_WALL)
	_static_rect(Vector2(220, 250), Vector2(360, 14), 0, C_WALL)
	_static_rect(Vector2(400, 320), Vector2(14, 140), 0, C_WALL)
	_static_rect(Vector2(450, 220), Vector2(200, 14), deg_to_rad(18), C_WALL)
	_static_rect(Vector2(570, 250), Vector2(14, 100), 0, C_WALL)
	_static_rect(Vector2(660, 130), Vector2(220, 14), 0, C_WALL)
	_static_rect(Vector2(770, 165), Vector2(14, 80), 0, C_WALL)
	_static_rect(Vector2(900, 70), Vector2(200, 14), deg_to_rad(-12), C_WALL)
	_static_rect(Vector2(550, 450), Vector2(14, 160), 0, C_WALL)
	_static_rect(Vector2(480, 450), Vector2(160, 14), deg_to_rad(-8), C_WALL)
	_static_rect(Vector2(820, 370), Vector2(180, 14), deg_to_rad(10), C_WALL)
	_static_rect(Vector2(1080, 180), Vector2(14, 200), 0, C_WALL)
	_static_rect(Vector2(950, 40), Vector2(100, 14), 0, C_WALL)

func _build_platforms() -> void:
	_static_rect(Vector2(220, 370),  Vector2(260, 14), 0,               C_PLAT)
	_static_rect(Vector2(450, 290),  Vector2(200, 14), deg_to_rad(18),  C_PLAT)
	_static_rect(Vector2(660, 200),  Vector2(220, 14), 0,               C_PLAT)
	_static_rect(Vector2(900, 150),  Vector2(200, 14), deg_to_rad(-12), C_PLAT)
	_static_rect(Vector2(480, 510),  Vector2(160, 14), deg_to_rad(-8),  C_PLAT)
	_static_rect(Vector2(820, 430),  Vector2(180, 14), deg_to_rad(10),  C_PLAT)
	_static_rect(Vector2(1020, 110), Vector2(110, 14), 0,               C_PLAT)

func _build_moving_platforms() -> void:
	_moving_platform(Vector2(350, 450), Vector2(120, 12), Vector2(0, -150), 3.0)
	_moving_platform(Vector2(550, 380), Vector2(100, 12), Vector2(180, 0), 4.0)
	_moving_platform(Vector2(850, 280), Vector2(90, 12), Vector2(120, -80), 3.5)

func _moving_platform(start_pos: Vector2, sz: Vector2, move_offset: Vector2, duration: float) -> void:
	var body := AnimatableBody2D.new()
	body.position = start_pos
	_attach_rect_collision(body, sz)
	_attach_rect_visual(body, sz, C_MOVING)
	add_child(body)
	if Engine.is_editor_hint():
		return
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(body, "position", start_pos + move_offset, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(body, "position", start_pos, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _build_rotating_obstacles() -> void:
	_rotating_obstacle(Vector2(560, 130), 60.0, 2.5, true)
	_rotating_obstacle(Vector2(720, 480), 70.0, 3.0, false)

func _rotating_obstacle(pos: Vector2, arm_len: float, rotation_time: float, clockwise: bool) -> void:
	var pivot := Node2D.new()
	pivot.position = pos
	add_child(pivot)
	for i in 4:
		var spike := Area2D.new()
		spike.rotation = (TAU / 4.0) * i
		var shape := RectangleShape2D.new()
		shape.size = Vector2(arm_len, 8)
		var col := CollisionShape2D.new()
		col.shape = shape
		col.position = Vector2(arm_len / 2, 0)
		spike.add_child(col)
		var vis := ColorRect.new()
		vis.size = Vector2(arm_len, 8)
		vis.position = Vector2(0, -4)
		vis.color = C_SPIKE
		spike.add_child(vis)
		pivot.add_child(spike)
		if not Engine.is_editor_hint():
			spike.body_entered.connect(_spike_hit)
	if Engine.is_editor_hint():
		return
	var tween := create_tween()
	tween.set_loops()
	var angle := TAU if clockwise else -TAU
	tween.tween_property(pivot, "rotation", angle, rotation_time).set_trans(Tween.TRANS_LINEAR).from(0)

func _build_springs() -> void:
	_area_rect(Vector2(300, 618), Vector2(70, 14), C_SPRING, _spring_hit)
	_area_rect(Vector2(760, 618), Vector2(70, 14), C_SPRING, _spring_hit)

func _spring_hit(body: Node2D) -> void:
	if Engine.is_editor_hint():
		return
	if body == player:
		var base_force := 750.0
		var force: float = base_force / player.gravity_multiplier
		player.velocity.y = -force * player.gravity_direction

func _build_spikes() -> void:
	_area_rect(Vector2(600, 625), Vector2(110, 14), C_SPIKE, _spike_hit)
	_area_rect(Vector2(320, 363), Vector2(80, 10), C_SPIKE, _spike_hit)
	_area_rect(Vector2(520, 280), Vector2(60, 10), C_SPIKE, _spike_hit)
	_area_rect(Vector2(660, 250), Vector2(100, 10), C_SPIKE, _spike_hit)
	_area_rect(Vector2(980, 103), Vector2(50, 10), C_SPIKE, _spike_hit)
	_area_rect(Vector2(820, 422), Vector2(70, 10), C_SPIKE, _spike_hit)

func _spike_hit(body: Node2D) -> void:
	if Engine.is_editor_hint():
		return
	if body == player:
		get_tree().reload_current_scene()

func _build_conveyors() -> void:
	_conveyor(Vector2(480, 503), Vector2(140, 14), 45.0)
	_conveyor(Vector2(900, 143), Vector2(120, 14), -40.0)
	_conveyor(Vector2(350, 450), Vector2(100, 14), 35.0)

func _conveyor(pos: Vector2, sz: Vector2, speed: float) -> void:
	_static_rect(pos, sz, 0, C_CONV)
	var area := Area2D.new()
	area.position = pos
	var shape := RectangleShape2D.new()
	shape.size = Vector2(sz.x + 4, sz.y + 20)
	var col := CollisionShape2D.new()
	col.shape = shape
	area.add_child(col)
	var arrow_label := Label.new()
	arrow_label.text = "▸▸▸" if speed > 0 else "◂◂◂"
	arrow_label.add_theme_font_size_override("font_size", 10)
	arrow_label.position = Vector2(-sz.x / 2 + 4, -12)
	arrow_label.modulate = Color(1, 1, 1, 0.6)
	area.add_child(arrow_label)
	add_child(area)
	if not Engine.is_editor_hint():
		area.body_entered.connect(_conveyor_enter.bind(speed))
		area.body_exited.connect(_conveyor_exit)

func _conveyor_enter(body: Node2D, speed: float) -> void:
	if body == player:
		player.on_conveyor = true
		player.conveyor_speed = speed

func _conveyor_exit(body: Node2D) -> void:
	if body == player:
		player.on_conveyor = false
		player.conveyor_speed = 0.0

func _build_sticky_surfaces() -> void:
	_sticky_rect(Vector2(220, 363), Vector2(100, 14))
	_sticky_rect(Vector2(660, 193), Vector2(80, 14))

func _sticky_rect(pos: Vector2, sz: Vector2) -> void:
	_static_rect(pos, sz, 0, C_STICKY)
	var area := Area2D.new()
	area.position = pos
	var shape := RectangleShape2D.new()
	shape.size = Vector2(sz.x + 8, sz.y + 20)
	var col := CollisionShape2D.new()
	col.shape = shape
	area.add_child(col)
	add_child(area)
	if not Engine.is_editor_hint():
		area.body_entered.connect(_sticky_enter)
		area.body_exited.connect(_sticky_exit)

func _sticky_enter(body: Node2D) -> void:
	if body == player:
		player.on_sticky = true

func _sticky_exit(body: Node2D) -> void:
	if body == player:
		player.on_sticky = false

func _build_antigrav_zones() -> void:
	_antigrav_zone(Vector2(450, 300), Vector2(120, 120))
	_antigrav_zone(Vector2(850, 350), Vector2(100, 150))

func _antigrav_zone(pos: Vector2, sz: Vector2) -> void:
	var area := Area2D.new()
	area.position = pos
	var shape := RectangleShape2D.new()
	shape.size = sz
	var col := CollisionShape2D.new()
	col.shape = shape
	area.add_child(col)
	var vis := ColorRect.new()
	vis.size = sz
	vis.position = -sz / 2
	vis.color = C_NOGRV
	area.add_child(vis)
	var border := ColorRect.new()
	border.size = sz
	border.position = -sz / 2
	border.color = Color(0.55, 0.20, 0.70, 0.5)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area.add_child(border)
	var inner := ColorRect.new()
	inner.size = sz - Vector2(4, 4)
	inner.position = -sz / 2 + Vector2(2, 2)
	inner.color = C_NOGRV
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area.add_child(inner)
	add_child(area)
	if not Engine.is_editor_hint():
		area.body_entered.connect(_antigrav_enter)
		area.body_exited.connect(_antigrav_exit)

func _antigrav_enter(body: Node2D) -> void:
	if body == player:
		player.gravity_locked = true

func _antigrav_exit(body: Node2D) -> void:
	if body == player:
		player.gravity_locked = false

func _build_gravity_flippers() -> void:
	_gravity_flip_sphere(Vector2(660, 170))
	_gravity_flip_sphere(Vector2(900, 120))

func _gravity_flip_sphere(pos: Vector2) -> void:
	var area := Area2D.new()
	area.position = pos
	var shape := CircleShape2D.new()
	shape.radius = 18.0
	var col := CollisionShape2D.new()
	col.shape = shape
	area.add_child(col)
	add_child(area)
	var vis := Node2D.new()
	vis.set_script(load("res://flip_sphere_visual.gd") if ResourceLoader.exists("res://flip_sphere_visual.gd") else null)
	if vis.get_script() == null:
		var canvas := _DrawCircleNode.new()
		canvas.radius = 18.0
		canvas.color = C_FLIP
		area.add_child(canvas)
	else:
		area.add_child(vis)
	if not Engine.is_editor_hint():
		area.body_entered.connect(_flip_sphere_hit)

func _flip_sphere_hit(body: Node2D) -> void:
	if body == player:
		player.flip_gravity()

func _build_interact_flippers() -> void:
	_interact_flip_sphere(Vector2(500, 170))
	_interact_flip_sphere(Vector2(800, 500))

func _interact_flip_sphere(pos: Vector2) -> void:
	var area := Area2D.new()
	area.position = pos
	var shape := CircleShape2D.new()
	shape.radius = 22.0
	var col := CollisionShape2D.new()
	col.shape = shape
	area.add_child(col)
	var canvas := _DrawCircleNode.new()
	canvas.radius = 22.0
	canvas.color = C_IFLIP
	area.add_child(canvas)
	add_child(area)
	if not Engine.is_editor_hint():
		area.body_entered.connect(_interact_sphere_enter.bind(area))
		area.body_exited.connect(_interact_sphere_exit.bind(area))

func _interact_sphere_enter(body: Node2D, area: Area2D) -> void:
	if body == player:
		player._near_interact_sphere = area

func _interact_sphere_exit(body: Node2D, area: Area2D) -> void:
	if body == player and player._near_interact_sphere == area:
		player._near_interact_sphere = null

func _build_goal() -> void:
	_area_rect(Vector2(1050, 65), Vector2(55, 55), C_GOAL, _goal_hit)

func _goal_hit(body: Node2D) -> void:
	if Engine.is_editor_hint():
		return
	if body == player:
		hint_label.text = "✦  LEVEL COMPLETE!  ✦   R — restart"
		hint_label.modulate = Color(1, 0.85, 0, 1)
		hint_label.add_theme_font_size_override("font_size", 22)
		hint_label.position = Vector2(380, 300)

func _static_rect(pos: Vector2, sz: Vector2, rot: float, color: Color) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	body.rotation = rot
	_attach_rect_collision(body, sz)
	_attach_rect_visual(body, sz, color)
	add_child(body)

func _area_rect(pos: Vector2, sz: Vector2, color: Color, on_enter: Callable) -> void:
	var area := Area2D.new()
	area.position = pos
	_attach_rect_collision(area, sz)
	_attach_rect_visual(area, sz, color)
	add_child(area)
	area.body_entered.connect(on_enter)

func _attach_rect_collision(parent: Node2D, sz: Vector2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = sz
	var col := CollisionShape2D.new()
	col.shape = shape
	parent.add_child(col)

func _attach_rect_visual(parent: Node2D, sz: Vector2, color: Color) -> void:
	var vis := ColorRect.new()
	vis.size = sz
	vis.position = -sz / 2
	vis.color = color
	parent.add_child(vis)

class _DrawCircleNode extends Node2D:
	var radius: float = 18.0
	var color: Color = Color.CYAN
	func _draw() -> void:
		draw_circle(Vector2.ZERO, radius, color)
		draw_arc(Vector2.ZERO, radius, 0, TAU, 32, color.darkened(0.3), 2.0)

func _build_player() -> void:
	player = CharacterBody2D.new()
	player.position = PLAYER_START
	player.set_script(load("res://player.gd"))
	add_child(player)
	# В песочнице — все способности открыты
	player.dash_unlocked = true
	player.double_jump_unlocked = true
	if not Engine.is_editor_hint():
		player.gravity_changed.connect(_on_gravity_changed)

func _build_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)
	gravity_label = Label.new()
	gravity_label.position = Vector2(20, 8)
	gravity_label.add_theme_font_size_override("font_size", 20)
	hud.add_child(gravity_label)
	dir_label = Label.new()
	dir_label.position = Vector2(20, 36)
	dir_label.add_theme_font_size_override("font_size", 18)
	hud.add_child(dir_label)
	hint_label = Label.new()
	hint_label.position = Vector2(20, 620)
	hint_label.add_theme_font_size_override("font_size", 13)
	hint_label.text = "A/D — move  |  Space — jump  |  Scroll — gravity  |  Shift — dash  |  R — restart"
	hint_label.modulate = Color(1, 1, 1, 0.4)
	hud.add_child(hint_label)
	var bar_bg := ColorRect.new()
	bar_bg.position = Vector2(1112, 100)
	bar_bg.size = Vector2(18, 448)
	bar_bg.color = Color(0.18, 0.18, 0.22)
	hud.add_child(bar_bg)
	var one_x_mark := ColorRect.new()
	one_x_mark.position = Vector2(1108, 193)
	one_x_mark.size = Vector2(26, 2)
	one_x_mark.color = Color(1, 1, 1, 0.4)
	hud.add_child(one_x_mark)
	bar_fill = ColorRect.new()
	hud.add_child(bar_fill)
	bar_center_y = 100.0
	_update_hud(1.0, 1)

func _on_gravity_changed(multiplier: float, direction: int) -> void:
	if Engine.is_editor_hint():
		return
	_update_hud(multiplier, direction)

func _update_hud(multiplier: float, direction: int) -> void:
	gravity_label.text = "Gravity: %.1fx" % multiplier
	if direction >= 0:
		dir_label.text = "▼ DOWN"
		dir_label.modulate = Color(0.5, 0.85, 1.0)
	else:
		dir_label.text = "▲ UP"
		dir_label.modulate = Color(1.0, 0.4, 0.4)
	var normalized := (multiplier - 0.2) / (5.0 - 0.2)
	var bar_h := normalized * 448.0
	bar_fill.position = Vector2(1114, 100 + 448 - bar_h)
	bar_fill.size = Vector2(14, bar_h)
	if direction >= 0:
		bar_fill.color = Color(0.35, 0.70, 1.0, 0.85)
	else:
		bar_fill.color = Color(1.0, 0.4, 0.4, 0.85)

func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			get_tree().reload_current_scene()
		elif event.keycode == KEY_ESCAPE:
			get_tree().quit()
