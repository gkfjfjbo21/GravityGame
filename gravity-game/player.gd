extends CharacterBody2D
## Игрок — CharacterBody2D платформер.
## Колесо мыши — сила гравитации (0.2x–5x). Направление — только через объекты.
## A/D — ходьба, Space — variable jump, Shift — dash.

# ── Движение ──
const SPEED := 200.0
const JUMP_VELOCITY := -350.0
const JUMP_VELOCITY_MIN := -150.0  # минимальный прыжок (короткое нажатие)
const STICKY_SPEED_MULT := 0.35
const STICKY_JUMP_MULT := 0.5
var on_sticky: bool = false
var on_conveyor: bool = false
var conveyor_speed: float = 0.0

# ── Гравитация ──
const BASE_GRAVITY := 980.0
var gravity_multiplier: float = 1.0
const GRAVITY_STEP := 0.25
var gravity_min: float = 0.2
var gravity_max: float = 5.0
var gravity_direction: int = 1  # 1 = вниз, -1 = вверх

signal gravity_changed(multiplier: float, direction: int)

# ── Прыжок ──
var _coyote_timer: float = 0.0
const COYOTE_TIME := 0.1
var _jump_buffer_timer: float = 0.0
const JUMP_BUFFER_TIME := 0.1
var _is_jumping: bool = false
var _has_double_jump: bool = false
var double_jump_unlocked: bool = false

# ── Dash ──
var dash_unlocked: bool = false
var _can_air_dash: bool = true
var _is_dashing: bool = false
var _dash_timer: float = 0.0
const DASH_SPEED := 500.0
const DASH_DURATION := 0.15
const DASH_COOLDOWN := 0.4
var _dash_cooldown_timer: float = 0.0
var _dash_direction: float = 0.0

# ── Wall slide / wall jump ──
const WALL_SLIDE_SPEED := 50.0
const WALL_JUMP_VELOCITY := Vector2(350.0, -350.0)
const WALL_JUMP_LOCK_TIME := 0.15  # время, когда игрок не может двигаться к стене после wall jump
var _is_wall_sliding: bool = false
var _wall_jump_lock_timer: float = 0.0
var _wall_jump_dir: float = 0.0

# ── Interact сфера ──
var _near_interact_sphere: Area2D = null  # ссылка на ближайшую сферу

# ── Визуал (плейсхолдер) ──
const PLAYER_SIZE := Vector2(20, 32)

func _ready() -> void:
	# Коллизия — прямоугольник
	var shape := RectangleShape2D.new()
	shape.size = PLAYER_SIZE
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)
	# Лимит скорости вверх
	floor_snap_length = 4.0

var gravity_locked: bool = false  # антигравитационная зона блокирует колесо

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	if gravity_locked:
		return
	# Колесо мыши — только сила, НЕ направление
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		gravity_multiplier = clampf(gravity_multiplier - GRAVITY_STEP, gravity_min, gravity_max)
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		gravity_multiplier = clampf(gravity_multiplier + GRAVITY_STEP, gravity_min, gravity_max)
	else:
		return
	gravity_changed.emit(gravity_multiplier, gravity_direction)

func _physics_process(delta: float) -> void:
	var on_floor := _is_on_ground()
	var on_wall := is_on_wall()
	var grav := BASE_GRAVITY * gravity_multiplier * gravity_direction

	# ── Coyote time ──
	if on_floor:
		_coyote_timer = COYOTE_TIME
		_can_air_dash = true
		_has_double_jump = true
	elif on_wall:
		_can_air_dash = true
	else:
		_coyote_timer -= delta

	# ── Jump buffer ──
	if Input.is_action_just_pressed("ui_accept"):
		_jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		_jump_buffer_timer -= delta

	# ── Dash cooldown ──
	_dash_cooldown_timer -= delta
	_wall_jump_lock_timer -= delta

	# ── Dash ──
	if _is_dashing:
		_dash_timer -= delta
		velocity.x = _dash_direction * DASH_SPEED
		velocity.y = 0.0
		if _dash_timer <= 0.0:
			_is_dashing = false
		move_and_slide()
		_flip_sprite()
		return

	if Input.is_action_just_pressed("dash") and dash_unlocked and _dash_cooldown_timer <= 0.0:
		var dir := Input.get_axis("move_left", "move_right")
		if dir == 0.0:
			dir = 1.0 if not _is_flipped() else -1.0
		if not on_floor and not _can_air_dash:
			pass  # нельзя дешить в воздухе повторно
		else:
			_is_dashing = true
			_dash_timer = DASH_DURATION
			_dash_cooldown_timer = DASH_COOLDOWN
			_dash_direction = dir
			if not on_floor:
				_can_air_dash = false
			move_and_slide()
			_flip_sprite()
			return

	# ── Гравитация ──
	if not on_floor:
		velocity.y += grav * delta

	# ── Wall slide ──
	_is_wall_sliding = false
	if on_wall and not on_floor and velocity.y * gravity_direction > 0:
		_is_wall_sliding = true
		velocity.y = WALL_SLIDE_SPEED * gravity_direction
		_coyote_timer = 0.0  # нет coyote с wall slide

	# ── Прыжок ──
	var jump_mult := STICKY_JUMP_MULT if on_sticky else 1.0
	if _jump_buffer_timer > 0.0:
		if _near_interact_sphere != null:
			# Активация сферы вместо прыжка/дабл джампа
			flip_gravity()
			_jump_buffer_timer = 0.0
		elif _coyote_timer > 0.0:
			# Обычный прыжок
			velocity.y = JUMP_VELOCITY * gravity_direction * jump_mult
			_is_jumping = true
			_coyote_timer = 0.0
			_jump_buffer_timer = 0.0
		elif _is_wall_sliding:
			# Wall jump — всегда сильный отскок от стены (как в Hollow Knight)
			var wall_normal := get_wall_normal()
			velocity.x = wall_normal.x * WALL_JUMP_VELOCITY.x
			velocity.y = WALL_JUMP_VELOCITY.y * gravity_direction
			_is_jumping = true
			_is_wall_sliding = false
			_jump_buffer_timer = 0.0
			_wall_jump_lock_timer = WALL_JUMP_LOCK_TIME
			_wall_jump_dir = wall_normal.x
			_has_double_jump = true  # wall jump восстанавливает double jump
		elif double_jump_unlocked and _has_double_jump:
			# Double jump
			velocity.y = JUMP_VELOCITY * gravity_direction
			_is_jumping = true
			_has_double_jump = false
			_jump_buffer_timer = 0.0

	# Variable jump — отпустил раньше = ниже прыжок
	if _is_jumping and not Input.is_action_pressed("ui_accept"):
		if gravity_direction == 1 and velocity.y < JUMP_VELOCITY_MIN:
			velocity.y = JUMP_VELOCITY_MIN
		elif gravity_direction == -1 and velocity.y > -JUMP_VELOCITY_MIN:
			velocity.y = -JUMP_VELOCITY_MIN
		_is_jumping = false

	if on_floor and not _is_jumping:
		_is_jumping = false

	# ── Горизонтальное движение ──
	var speed_mult := STICKY_SPEED_MULT if on_sticky else 1.0
	var current_speed := SPEED * speed_mult
	var input_dir := Input.get_axis("move_left", "move_right")
	if _wall_jump_lock_timer > 0.0:
		if sign(input_dir) == -sign(_wall_jump_dir):
			input_dir = 0.0
		velocity.x = move_toward(velocity.x, 0, SPEED * 0.1)
	elif input_dir != 0.0:
		velocity.x = input_dir * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed * 0.3)

	if on_conveyor:
		velocity.x += conveyor_speed

	move_and_slide()
	_flip_sprite()

# ── Проверка пола (учитывает направление гравитации) ──
# up_direction уже меняется при flip_gravity, поэтому is_on_floor() корректен всегда
func _is_on_ground() -> bool:
	return is_on_floor()

# ── Переворот при обратной гравитации ──
func _flip_sprite() -> void:
	scale.y = 1.0 if gravity_direction == 1 else -1.0

func _is_flipped() -> bool:
	return scale.x < 0

# ── Вызывается объектами смены направления гравитации ──
func flip_gravity() -> void:
	gravity_direction *= -1
	velocity.y = 0.0
	up_direction = Vector2(0, -gravity_direction)
	gravity_changed.emit(gravity_multiplier, gravity_direction)

func set_gravity_direction(dir: int) -> void:
	if dir != gravity_direction:
		flip_gravity()

func reset_gravity() -> void:
	gravity_multiplier = 1.0
	gravity_direction = 1
	up_direction = Vector2.UP
	gravity_changed.emit(gravity_multiplier, gravity_direction)

# ── Визуал (плейсхолдер — цветной прямоугольник) ──
func _draw() -> void:
	var rect := Rect2(-PLAYER_SIZE / 2, PLAYER_SIZE)
	draw_rect(rect, Color(0.3, 0.75, 1.0))
	draw_rect(rect, Color(0.15, 0.45, 0.75), false, 2.0)
	# Глаза (показывают направление)
	var eye_y := -6.0
	draw_circle(Vector2(-4, eye_y), 2.5, Color.WHITE)
	draw_circle(Vector2(4, eye_y), 2.5, Color.WHITE)
	draw_circle(Vector2(-4, eye_y), 1.2, Color(0.1, 0.1, 0.2))
	draw_circle(Vector2(4, eye_y), 1.2, Color(0.1, 0.1, 0.2))
