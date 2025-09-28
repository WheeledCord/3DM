extends CharacterBody2D
class_name Player

const PIXELS_PER_SECOND = 120.0
const RIGHT_SPEED_FACTOR = 0.9
const JUMP_VELOCITY = -350.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity") * 2.0
var is_jumping := false
var is_punching := false

func _ready():
	$AnimatedSprite2D.connect("animation_finished", Callable(self, "_on_animation_finished"))
	NavigationManager.on_trigger_player_spawn.connect(_on_spawn)

func _on_spawn(spawn_position: Vector2, direction: String) -> void:
	global_position = spawn_position.round()

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	if _try_punch():
		return
	_handle_jump()
	_handle_horizontal_pixel_perfect(delta)
	_reset_jump_state()
	move_and_slide()

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
		if velocity.y < 0:
			if not is_jumping or $AnimatedSprite2D.animation != "jump":
				is_jumping = true
				$AnimatedSprite2D.play("jump")
		elif velocity.y > 0:
			if $AnimatedSprite2D.animation != "fall":
				$AnimatedSprite2D.play("fall")
	else:
		is_jumping = false

func _handle_horizontal_pixel_perfect(delta: float) -> void:
	if is_punching:
		velocity.x = 0
		return
	
	var dir := Input.get_axis("left", "right")
	
	if dir != 0:
		var effective_speed = PIXELS_PER_SECOND
		if dir > 0:
			effective_speed *= RIGHT_SPEED_FACTOR
		
		# Round the final speed to ensure whole pixel movement
		velocity.x = round(dir * effective_speed)
		
		$AnimatedSprite2D.flip_h = dir < 0
		if is_on_floor() and not is_jumping:
			$AnimatedSprite2D.play("walk")
	else:
		velocity.x = 0
		if is_on_floor() and not is_jumping:
			$AnimatedSprite2D.play("idle")

func _try_punch() -> bool:
	if Input.is_action_just_pressed("punch") and is_on_floor() and not is_punching:
		_start_punch()
		return true
	return false

func _start_punch() -> void:
	is_punching = true
	velocity.x = 0
	$AnimatedSprite2D.play("punch")

func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_punching:
		velocity.y = JUMP_VELOCITY
		$AnimatedSprite2D.play("jump")
		is_jumping = true

func _reset_jump_state() -> void:
	if is_on_floor() and is_jumping and not is_punching:
		is_jumping = false

func _on_animation_finished() -> void:
	if $AnimatedSprite2D.animation == "punch":
		is_punching = false
	if is_punching:
		return
	if Input.is_action_pressed("left") or Input.is_action_pressed("right"):
		$AnimatedSprite2D.play("walk")
	elif is_on_floor():
		$AnimatedSprite2D.play("idle")
