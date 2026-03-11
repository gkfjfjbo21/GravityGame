@tool
extends Area2D
## Шипы — убивают игрока при касании. Меняй размер в инспекторе.

@export var spike_size := Vector2(80, 10):
	set(v):
		spike_size = v
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
		get_tree().reload_current_scene()

func _update() -> void:
	if not is_inside_tree():
		return
	var col := get_node_or_null("Collision") as CollisionShape2D
	if col and col.shape:
		col.shape.size = spike_size
	var vis := get_node_or_null("Visual") as ColorRect
	if vis:
		vis.position = -spike_size / 2
		vis.size = spike_size
		vis.color = Color(0.9, 0.15, 0.15)
