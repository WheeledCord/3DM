extends Camera2D

@export var follow_target: Node2D
@export var smooth_speed := 5.0
@export var tilemap: TileMap  # reference to the tilemap that defines the camera limits

var snap_time := 0.1  # time in seconds for snapping
var timer := 0.0  # timer to track snapping duration

func _ready():
	# snap the camera to the player's position on start
	if follow_target:
		global_position = follow_target.global_position
	
	# update camera limits based on the size of the TileMap
	set_camera_limits()

	# start the snapping process
	timer = snap_time

func _process(delta):
	# if still in snap mode, just snap the camera to the player's position
	if timer > 0:
		timer -= delta
		global_position = follow_target.global_position
		return  # Skip the smooth following during the snap period
	
	# after the snap time, smoothly move the camera toward the follow_target position
	if follow_target:
		var target_position = follow_target.global_position
		
		# smoothly move the camera towards the follow_target
		var new_position = global_position.lerp(target_position, smooth_speed * delta)
		
		# clamp the camera position within the calculated limits
		new_position.x = clamp(new_position.x, limit_left, limit_right)
		new_position.y = clamp(new_position.y, limit_top, limit_bottom)
		
		# set the camera's position after clamping
		global_position = new_position

func set_camera_limits():
	# get the used rectangle of the TileMap to find its extents
	var map_limits = tilemap.get_used_rect()
	
	# get the tile size from the TileMap's TileSet
	var tile_size = tilemap.tile_set.tile_size
	
	# set the camera's limit properties based on the TileMap size and position
	limit_left = map_limits.position.x * tile_size.x
	limit_right = map_limits.end.x * tile_size.x
	limit_top = map_limits.position.y * tile_size.y
	limit_bottom = map_limits.end.y * tile_size.y
