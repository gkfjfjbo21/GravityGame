@tool
extends Area2D
## Цель уровня. Подключи сигнал level_completed в скрипте уровня.

signal level_completed

@export var goal_size := Vector2(50, 50):
	set(v):
		goal_size = v
		_update()

func _ready() -> void:
	var col := get_node_or_null("Collision") as CollisionShape2D
	if col and col.shape:
		col.shape = col.shape.duplicate()
	_update()
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		level_completed.emit()

func _update() -> void:
	if not is_inside_tree():
		return
	var col := get_node_or_null("Collision") as CollisionShape2D
	if col and col.shape:
		col.shape.size = goal_size
	var vis := get_node_or_null("Visual") as ColorRect
	if vis:
		vis.position = -goal_size / 2
		vis.size = goal_size
		vis.color = Color(1.0, 0.85, 0.1, 0.85)
