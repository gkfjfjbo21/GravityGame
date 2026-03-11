extends Node2D
## Уровень 1 — «Подъём». Логика: HUD, рестарт, цель.
## Геометрия уровня — в level_1.tscn, двигай мышкой в редакторе!

@onready var player: CharacterBody2D = $Player
@onready var goal: Area2D = $Goal

var gravity_label: Label
var dir_label: Label
var hint_label: Label
var bar_fill: ColorRect

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.10, 0.10, 0.14))
	player.dash_unlocked = false
	player.double_jump_unlocked = false
	player.gravity_min = 0.5
	player.gravity_max = 2.0
	player.gravity_changed.connect(_on_gravity_changed)
	goal.level_completed.connect(_on_level_completed)
	_build_hud()

func _on_level_completed() -> void:
	hint_label.text = "✦  УРОВЕНЬ ПРОЙДЕН!  ✦   R — заново"
	hint_label.modulate = Color(1, 0.85, 0, 1)
	hint_label.add_theme_font_size_override("font_size", 22)
	hint_label.position = Vector2(380, 300)

func _on_gravity_changed(multiplier: float, direction: int) -> void:
	_update_hud(multiplier, direction)

# ── HUD ──────────────────────────────────────────────
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
	hint_label.text = "A/D — двигайся  |  Space — прыжок  |  Колёсико — гравитация  |  R — рестарт"
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
	_update_hud(1.0, 1)

func _update_hud(multiplier: float, direction: int) -> void:
	gravity_label.text = "Гравитация: %.2fx" % multiplier
	if direction >= 0:
		dir_label.text = "▼ ВНИЗ"
		dir_label.modulate = Color(0.5, 0.85, 1.0)
	else:
		dir_label.text = "▲ ВВЕРХ"
		dir_label.modulate = Color(1.0, 0.4, 0.4)
	var normalized := (multiplier - 0.2) / (5.0 - 0.2)
	var bar_h := normalized * 448.0
	bar_fill.position = Vector2(1114, 100 + 448 - bar_h)
	bar_fill.size = Vector2(14, bar_h)
	if direction >= 0:
		bar_fill.color = Color(0.35, 0.70, 1.0, 0.85)
	else:
		bar_fill.color = Color(1.0, 0.4, 0.4, 0.85)

# ── Ввод ─────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			get_tree().reload_current_scene()
		elif event.keycode == KEY_ESCAPE:
			get_tree().quit()
