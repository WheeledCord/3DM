extends Camera2D
@export var follow_target: Node2D
@export var smooth_speed := 5.0
@export var tilemap: TileMap
var snap_time := 0.1
var timer := 0.0

func _ready():
	if follow_target:
		global_position = follow_target.global_position.round()
	
	set_camera_limits()
	timer = snap_time

func _process(delta):
	if timer > 0:
		timer -= delta
		global_position = follow_target.global_position.round()
		return
	
	if follow_target:
		var target_position = follow_target.global_position.round()
		
		# Move camera by whole pixels only
		var direction = (target_position - global_position).normalized()
		var distance = global_position.distance_to(target_position)
		
		if distance > 1.0:  # Only move if more than 1 pixel away
			var movement = direction * smooth_speed * 60.0 * delta  # 60 pixels per second base
			movement = movement.round()  # Round movement to whole pixels
			
			var new_position = global_position + movement
			
			# Don't overshoot the target
			if global_position.distance_to(new_position) > distance:
				new_position = target_position
			
			# Clamp within limits
			new_position.x = clamp(new_position.x, limit_left, limit_right)
			new_position.y = clamp(new_position.y, limit_top, limit_bottom)
			
			global_position = new_position

func set_camera_limits(): 
	var map_limits = tilemap.get_used_rect()
	var tile_size = tilemap.tile_set.tile_size
	
	limit_left = map_limits.position.x * tile_size.x
	limit_right = map_limits.end.x * tile_size.x
	limit_top = map_limits.position.y * tile_size.y
	limit_bottom = map_limits.end.y * tile_size.y
