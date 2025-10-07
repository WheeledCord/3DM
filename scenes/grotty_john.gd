extends CharacterBody2D
class_name GrottyJohn

const WALK_SPEED = 80.0
const JUMP_VELOCITY = -350.0
const DROPKICK_JUMP_VELOCITY = -350.0
const DROPKICK_SPEED = 500.0
const PUNCH_RANGE = 20.0
const DROPKICK_MIN_RANGE = 80.0
const DROPKICK_MAX_RANGE = 180.0
const RETREAT_DISTANCE = 300.0
const PUNCH_KNOCKBACK = 200.0
const KICK_KNOCKBACK = 800.0
const PUNCH_DURATION = 0.3
const ATTACK_COOLDOWN = 0.8
const DROPKICK_COOLDOWN = 6.0
const ROLL_DURATION = 3.0
const KICK_DURATION = 1.5
const BLOCK_RANGE = 120.0
const INSTANT_BLOCK_RANGE = 40.0
const DASH_PUNCH_RANGE = 45.0
const DASH_PUNCH_SPEED = 200.0
const TACTICAL_RETREAT_RANGE = 60.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity") * 2.0
var starting_position: Vector2
var player: Player = null

enum State { IDLE, WALKING, PUNCHING, JUMPING, DROPKICK_JUMP, DROPKICK_ROLL, DROPKICK_KICK, RETREATING, DASH_PUNCH, TACTICAL_RETREAT }
var current_state = State.IDLE
var roll_timer = 0.0
var kick_timer = 0.0
var dropkick_direction = Vector2.ZERO
var action_timer = 0.0
var attack_cooldown = 0.0
var dropkick_cooldown = 0.0
var has_hit_player = false
var block_jump_timer = 0.0
var should_block_jump = false
var was_player_on_floor = true

@onready var sprite = $AnimatedSprite2D
@onready var hitbox = $Area2D

func _ready():
	starting_position = global_position
	hitbox.monitoring = false
	hitbox.connect("body_entered", Callable(self, "_on_hitbox_body_entered"))

func _physics_process(delta: float) -> void:
	_find_player()
	
	if not player:
		return
	
	_check_player_jump()
	_apply_gravity(delta)
	_update_sprite_direction()
	_update_cooldowns(delta)
	_process_state(delta)
	move_and_slide()

func _find_player() -> void:
	if not player:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]

func _check_player_jump() -> void:
	var player_on_floor = player.is_on_floor()
	
	if was_player_on_floor and not player_on_floor:
		var distance = abs(player.global_position.x - global_position.x)
		var player_moving_right = player.global_position.x > global_position.x
		
		# Only block if player is jumping toward/over the boss
		if player_moving_right and distance <= BLOCK_RANGE and is_on_floor():
			if current_state in [State.IDLE, State.WALKING]:
				# Instant reaction - much faster blocking
				var delay = 0.0
				if distance > INSTANT_BLOCK_RANGE:
					delay = ((distance - INSTANT_BLOCK_RANGE) / (BLOCK_RANGE - INSTANT_BLOCK_RANGE)) * 0.1
				
				block_jump_timer = delay
				should_block_jump = true
	
	was_player_on_floor = player_on_floor

func _apply_gravity(delta: float) -> void:
	if current_state == State.DROPKICK_KICK:
		return
	
	if not is_on_floor():
		var gravity_multiplier = 1.0
		if current_state == State.DROPKICK_ROLL:
			gravity_multiplier = 0.0
		
		velocity.y += gravity * delta * gravity_multiplier

func _update_sprite_direction() -> void:
	if player and current_state != State.DROPKICK_KICK:
		sprite.flip_h = player.global_position.x < global_position.x

func _update_cooldowns(delta: float) -> void:
	if action_timer > 0:
		action_timer -= delta
	if attack_cooldown > 0:
		attack_cooldown -= delta
	if dropkick_cooldown > 0:
		dropkick_cooldown -= delta
	
	if block_jump_timer > 0:
		block_jump_timer -= delta
		if block_jump_timer <= 0 and should_block_jump:
			should_block_jump = false
			if is_on_floor() and current_state in [State.IDLE, State.WALKING]:
				# Better jump blocking with forward momentum
				velocity.y = JUMP_VELOCITY
				var direction = sign(player.global_position.x - global_position.x)
				velocity.x = direction * WALK_SPEED * 0.7
				current_state = State.JUMPING
				sprite.play("jump")

func _process_state(delta: float) -> void:
	var distance_to_player = global_position.distance_to(player.global_position)
	var distance_from_start = global_position.distance_to(starting_position)
	
	if distance_from_start > RETREAT_DISTANCE and current_state not in [State.RETREATING, State.DROPKICK_KICK]:
		_start_retreat()
		return
	
	match current_state:
		State.IDLE:
			_handle_idle(distance_to_player)
		State.WALKING:
			_handle_walking(distance_to_player)
		State.PUNCHING:
			_handle_punching()
		State.JUMPING:
			_handle_jumping()
		State.DROPKICK_JUMP:
			_handle_dropkick_jump()
		State.DROPKICK_ROLL:
			_handle_dropkick_roll(delta)
		State.DROPKICK_KICK:
			_handle_dropkick_kick(delta)
		State.DASH_PUNCH:
			_handle_dash_punch()
		State.TACTICAL_RETREAT:
			_handle_tactical_retreat()
		State.RETREATING:
			_handle_retreat()

func _handle_idle(distance: float) -> void:
	if not is_on_floor():
		return
	
	velocity.x = 0
	sprite.play("idle")
	
	if attack_cooldown > 0:
		return
	
	# ALWAYS prioritize punching when close enough
	if distance < PUNCH_RANGE:
		_start_punch()
		return
	
	# Don't do other actions if we're about to block a jump
	if should_block_jump:
		return
	
	# Tactical decision making
	if dropkick_cooldown <= 0 and distance >= TACTICAL_RETREAT_RANGE and distance <= DROPKICK_MAX_RANGE and randf() > 0.7:
		# Sometimes retreat to use dropkick when it's available
		_start_tactical_retreat()
	elif distance <= DASH_PUNCH_RANGE and distance > PUNCH_RANGE:
		# Dash punch when in medium-close range
		_start_dash_punch()
	elif distance >= DROPKICK_MIN_RANGE and distance <= DROPKICK_MAX_RANGE and dropkick_cooldown <= 0:
		if randf() > 0.4:  # 60% chance
			_start_dropkick()
		else:
			_start_walking()
	else:
		# Aggressive pursuit to get close for punching
		_start_walking()

func _handle_walking(distance: float) -> void:
	if not is_on_floor():
		current_state = State.IDLE
		return
	
	if attack_cooldown > 0:
		current_state = State.IDLE
		return
	
	# ALWAYS prioritize punching when close enough
	if distance < PUNCH_RANGE:
		_start_punch()
		return
	
	# Don't do other actions if we're about to block a jump
	if should_block_jump:
		return
	
	if distance <= DASH_PUNCH_RANGE and distance > PUNCH_RANGE:
		_start_dash_punch()
		return
	elif distance >= DROPKICK_MIN_RANGE and distance <= DROPKICK_MAX_RANGE and dropkick_cooldown <= 0:
		if randf() > 0.3:  # 70% chance while walking
			_start_dropkick()
			return
	
	var direction = sign(player.global_position.x - global_position.x)
	# Very aggressive walking speed when trying to get close for punch/dash
	var speed_multiplier = 1.4 if distance < DROPKICK_MIN_RANGE else 1.0
	velocity.x = direction * WALK_SPEED * speed_multiplier
	sprite.play("walk")

func _handle_punching() -> void:
	velocity.x = 0
	
	if action_timer <= 0:
		hitbox.set_deferred("monitoring", false)
		attack_cooldown = ATTACK_COOLDOWN
		current_state = State.IDLE
		has_hit_player = false

func _handle_jumping() -> void:
	# Continue moving toward player while jumping for better blocking
	var direction = sign(player.global_position.x - global_position.x)
	velocity.x = direction * WALK_SPEED * 0.5
	
	if is_on_floor():
		attack_cooldown = ATTACK_COOLDOWN * 0.6  # Faster recovery after jump
		current_state = State.IDLE

func _handle_dropkick_jump() -> void:
	if velocity.y > 50:
		_start_roll()

func _handle_dropkick_roll(delta: float) -> void:
	roll_timer -= delta
	velocity.y = 0
	velocity.x = sign(dropkick_direction.x) * WALK_SPEED * 0.3
	
	var player_below = player.global_position.y > global_position.y
	var player_close = abs(player.global_position.x - global_position.x) < 60
	
	if (player_below and player_close) or roll_timer <= 0:
		_start_kick()

func _handle_dropkick_kick(delta: float) -> void:
	kick_timer -= delta
	velocity = dropkick_direction * DROPKICK_SPEED
	
	if kick_timer <= 0 and is_on_floor():
		hitbox.set_deferred("monitoring", false)
		attack_cooldown = ATTACK_COOLDOWN
		current_state = State.IDLE
		has_hit_player = false

func _handle_dash_punch() -> void:
	# Dash quickly toward player for punch
	var direction = sign(player.global_position.x - global_position.x)
	velocity.x = direction * DASH_PUNCH_SPEED
	sprite.play("walk")  # Fast walk animation
	
	# Check if close enough to punch or if we've dashed too far
	var distance = abs(player.global_position.x - global_position.x)
	if distance <= PUNCH_RANGE:
		_start_punch()
	elif distance > DASH_PUNCH_RANGE * 1.2:  # Overshot - be less forgiving
		current_state = State.WALKING

func _handle_tactical_retreat() -> void:
	# Retreat to better position for dropkick
	var direction = sign(starting_position.x - global_position.x)
	velocity.x = direction * WALK_SPEED * 1.2
	sprite.play("walk")
	
	# Stop retreating when at good dropkick distance
	var distance_to_player = abs(player.global_position.x - global_position.x)
	if distance_to_player >= DROPKICK_MIN_RANGE or abs(global_position.x - starting_position.x) > 40:
		current_state = State.IDLE

func _handle_retreat() -> void:
	var direction = sign(starting_position.x - global_position.x)
	velocity.x = direction * WALK_SPEED * 1.5
	sprite.play("walk")
	
	if global_position.distance_to(starting_position) < 20:
		current_state = State.IDLE
		velocity.x = 0

func _start_punch() -> void:
	current_state = State.PUNCHING
	velocity.x = 0
	sprite.play("punch")
	hitbox.set_deferred("monitoring", true)
	action_timer = PUNCH_DURATION
	has_hit_player = false

func _start_jump() -> void:
	if is_on_floor():
		velocity.y = JUMP_VELOCITY
		current_state = State.JUMPING
		sprite.play("jump")

func _start_walking() -> void:
	current_state = State.WALKING

func _start_dropkick() -> void:
	if is_on_floor():
		velocity.y = DROPKICK_JUMP_VELOCITY
		current_state = State.DROPKICK_JUMP
		dropkick_direction = (player.global_position - global_position).normalized()
		sprite.play("jump")
		dropkick_cooldown = DROPKICK_COOLDOWN

func _start_roll() -> void:
	current_state = State.DROPKICK_ROLL
	roll_timer = ROLL_DURATION
	sprite.play("roll")

func _start_kick() -> void:
	current_state = State.DROPKICK_KICK
	sprite.play("kick")
	hitbox.set_deferred("monitoring", true)
	dropkick_direction = (player.global_position - global_position).normalized()
	sprite.flip_h = dropkick_direction.x < 0
	kick_timer = KICK_DURATION
	velocity = dropkick_direction * DROPKICK_SPEED
	has_hit_player = false

func _start_dash_punch() -> void:
	current_state = State.DASH_PUNCH

func _start_tactical_retreat() -> void:
	current_state = State.TACTICAL_RETREAT

func _start_retreat() -> void:
	current_state = State.RETREATING
	hitbox.set_deferred("monitoring", false)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body is Player:
		if current_state != State.PUNCHING and current_state != State.DROPKICK_KICK and current_state != State.DASH_PUNCH:
			return
		
		if has_hit_player:
			return
		
		has_hit_player = true
		
		var knockback_strength = PUNCH_KNOCKBACK
		if current_state == State.DROPKICK_KICK:
			knockback_strength = KICK_KNOCKBACK
		elif current_state == State.DASH_PUNCH:
			knockback_strength = PUNCH_KNOCKBACK * 1.3  # Stronger dash punch
		
		_apply_knockback_to_player(body, knockback_strength)
		
		hitbox.set_deferred("monitoring", false)
		attack_cooldown = ATTACK_COOLDOWN
		current_state = State.IDLE
		velocity.x = 0

func _apply_knockback_to_player(target: Player, knockback_force: float) -> void:
	# Always push leftward (away from guarded right side)
	var knockback_dir = -1
	var knockback_y = -250 if current_state in [State.PUNCHING, State.DASH_PUNCH] else -200
	
	target.apply_knockback(Vector2(knockback_dir * knockback_force, knockback_y))
