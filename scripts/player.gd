extends CharacterBody2D
class_name Player

const SPEED = 150.0
const RIGHT_SPEED_FACTOR = 0.9  # <— slows rightward movement to 85% of normal
const JUMP_VELOCITY = -350.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity") * 2.0
var is_jumping := false
var is_punching := false

func _ready():
	$AnimatedSprite2D.connect("animation_finished", Callable(self, "_on_animation_finished"))
	NavigationManager.on_trigger_player_spawn.connect(_on_spawn)

func _on_spawn(spawn_position: Vector2, direction: String) -> void:
	global_position = spawn_position

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	if _try_punch():
		return

	_handle_jump()
	_handle_horizontal()
	_reset_jump_state()

	move_and_slide()

	# still snapping to whole pixels
	global_position = global_position.snapped(Vector2.ONE)


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
		if not is_jumping:
			is_jumping = true
			$AnimatedSprite2D.play("jump")

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

func _handle_horizontal() -> void:
	if is_punching:
		return
	var dir := Input.get_axis("left", "right")
	if dir != 0:
		# apply right‐side slowdown as a band‐aid
		var effective_speed = SPEED
		if dir > 0:
			effective_speed *= RIGHT_SPEED_FACTOR
		velocity.x = dir * effective_speed
		$AnimatedSprite2D.flip_h = dir < 0
		if is_on_floor() and not is_jumping:
			$AnimatedSprite2D.play("walk")
	else:
		# smooth stop
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if is_on_floor() and not is_jumping:
			$AnimatedSprite2D.play("idle")

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
