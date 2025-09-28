extends ParallaxBackground

@export var base_speed: Vector2 = Vector2(100, 0)

func _process(delta: float) -> void:
	scroll_base_offset += base_speed * delta
