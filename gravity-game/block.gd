@tool
extends StaticBody2D
## Универсальный блок (платформа/стена). Меняй размер и цвет в инспекторе.

@export var block_size := Vector2(100, 14):
	set(v):
		block_size = v
		_update()

@export var block_color := Color(0.45, 0.45, 0.55):
	set(v):
		block_color = v
		_update()

func _ready() -> void:
	var col := get_node_or_null("Collision") as CollisionShape2D
	if col and col.shape:
		col.shape = col.shape.duplicate()
	_update()

func _update() -> void:
	if not is_inside_tree():
		return
	var col := get_node_or_null("Collision") as CollisionShape2D
	if col and col.shape:
		col.shape.size = block_size
	var vis := get_node_or_null("Visual") as ColorRect
	if vis:
		vis.position = -block_size / 2
		vis.size = block_size
		vis.color = block_color
