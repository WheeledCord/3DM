extends CharacterBody2D

class_name Player

const SPEED = 150.0  # Slower movement speed
const JUMP_VELOCITY = -350.0  # Increased jump velocity for a reasonable height

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity") * 2.0  # Faster falling
var is_jumping = false
var is_punching = false  # State to check if the player is punching

func _ready():
	# Connect animation_finished to handle end of animations
	$AnimatedSprite2D.connect("animation_finished", Callable(self, "_on_animation_finished"))
	NavigationManager.on_trigger_player_spawn.connect(_on_spawn)
	
func _on_spawn(spawn_position: Vector2, direction: String):
	print("Spawn position:", spawn_position, "Direction:", direction)
	global_position = spawn_position

func _physics_process(delta):
	# Apply gravity while not on the floor
	if not is_on_floor():
		velocity.y += gravity * delta
		if not is_jumping:
			is_jumping = true
			$AnimatedSprite2D.play("jump")  # Always play jump animation in the air
	
	# Handle punch action - only punch when on the ground and not already punching
	if Input.is_action_just_pressed("punch") and is_on_floor() and not is_punching:
		punch()
		return  # Skip further processing while punching

	# Handle jump action
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_punching:
		velocity.y = JUMP_VELOCITY
		$AnimatedSprite2D.play("jump")  # Play jump animation when jumping
		is_jumping = true

	# Handle horizontal movement, only if not punching
	if not is_punching:
		var direction = 0.0
		if Input.is_action_pressed("left"):
			direction -= 1
		if Input.is_action_pressed("right"):
			direction += 1

		if direction != 0:
			velocity.x = direction * SPEED

			# Flip the sprite to face the correct direction
			$AnimatedSprite2D.flip_h = direction < 0  # Flip when moving left

			# Play walking animation if on the ground and not jumping
			if is_on_floor() and !is_jumping:
				$AnimatedSprite2D.play("walk")
		else:
			# Stop horizontal movement gradually and switch to idle when grounded
			velocity.x = move_toward(velocity.x, 0, SPEED)
			if is_on_floor() and not is_jumping:
				$AnimatedSprite2D.play("idle")  # Play idle animation when not moving

	# Reset jump state when on the floor
	if is_on_floor() and is_jumping and not is_punching:
		is_jumping = false

	move_and_slide()

# Function to handle punching logic
func punch():
	is_punching = true
	velocity.x = 0  # Stop horizontal movement
	$AnimatedSprite2D.play("punch")

# Function that gets called when any animation finishes
func _on_animation_finished():
	# Check if the punch animation finished
	if $AnimatedSprite2D.animation == "punch":
		is_punching = false  # Allow movement again after punch

	# Play other animations based on current input
	if Input.is_action_pressed("left") or Input.is_action_pressed("right"):
		$AnimatedSprite2D.play("walk")
	elif is_on_floor():
		$AnimatedSprite2D.play("idle")
