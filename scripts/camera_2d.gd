extends Camera2D

# Player reference
@export var player: Node2D
@export var follow_speed: float = 15.0  # Increased default speed
@export var pixel_perfect: bool = true

# Follow mode options
@export_enum("Smooth", "Instant", "Deadzone") var follow_mode: int = 0
@export var deadzone_size: Vector2 = Vector2(50, 30)  # Only used in deadzone mode

# Boundary area
@export var boundary_area: Area2D

# Camera bounds (calculated from Area2D)
var min_x: float
var max_x: float
var min_y: float
var max_y: float

# Viewport size
var viewport_size: Vector2

func _ready():
	# Get viewport size
	viewport_size = get_viewport().get_visible_rect().size
	
	# Calculate bounds from Area2D if provided
	if boundary_area:
		calculate_bounds()
	
	# If no player is assigned, try to find one
	if not player:
		player = get_tree().get_first_node_in_group("player")

func calculate_bounds():
	if not boundary_area:
		return
	
	# Get the CollisionShape2D from the Area2D
	var collision_shape = boundary_area.get_child(0) as CollisionShape2D
	if not collision_shape:
		print("Warning: No CollisionShape2D found in boundary_area")
		return
	
	var shape = collision_shape.shape
	var area_pos = boundary_area.global_position + collision_shape.position
	
	# Handle different shape types
	if shape is RectangleShape2D:
		var rect_shape = shape as RectangleShape2D
		var half_size = rect_shape.size / 2
		
		# Calculate camera bounds considering viewport size
		min_x = area_pos.x - half_size.x + viewport_size.x / 2
		max_x = area_pos.x + half_size.x - viewport_size.x / 2
		min_y = area_pos.y - half_size.y + viewport_size.y / 2
		max_y = area_pos.y + half_size.y - viewport_size.y / 2
		
	else:
		print("Warning: Only RectangleShape2D is supported for boundary areas")

func _process(delta):
	if not player:
		return
	
	var target_pos = player.global_position
	var new_pos: Vector2
	
	# Different follow modes
	match follow_mode:
		0: # Smooth following
			new_pos = global_position.lerp(target_pos, follow_speed * delta)
		
		1: # Instant following
			new_pos = target_pos
		
		2: # Deadzone following
			var distance = target_pos - global_position
			if abs(distance.x) > deadzone_size.x:
				new_pos.x = target_pos.x - sign(distance.x) * deadzone_size.x
			else:
				new_pos.x = global_position.x
			
			if abs(distance.y) > deadzone_size.y:
				new_pos.y = target_pos.y - sign(distance.y) * deadzone_size.y
			else:
				new_pos.y = global_position.y
	
	# Apply bounds if boundary area exists
	if boundary_area:
		new_pos.x = clamp(new_pos.x, min_x, max_x)
		new_pos.y = clamp(new_pos.y, min_y, max_y)
	
	# Apply pixel perfect positioning for pixel art
	if pixel_perfect:
		new_pos = Vector2(round(new_pos.x), round(new_pos.y))
	
	# Set the camera position
	global_position = new_pos

# Call this if you change the boundary area at runtime
func update_bounds():
	calculate_bounds()

# Optional: Set a new boundary area at runtime
func set_boundary_area(new_area: Area2D):
	boundary_area = new_area
	if boundary_area:
		calculate_bounds()

# Optional: Set camera bounds manually (if you don't want to use Area2D)
func set_manual_bounds(min_pos: Vector2, max_pos: Vector2):
	min_x = min_pos.x + viewport_size.x / 2
	max_x = max_pos.x - viewport_size.x / 2
	min_y = min_pos.y + viewport_size.y / 2
	max_y = max_pos.y - viewport_size.y / 2
