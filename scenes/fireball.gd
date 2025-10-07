extends CharacterBody2D
class_name Fireball

var direction: Vector2
var speed: float
var shooter: Node2D
var lifetime = 3.0

@onready var sprite: AnimatedSprite2D
@onready var hitbox: Area2D

func _ready():
	# Create sprite and hitbox dynamically if they don't exist
	if not sprite:
		sprite = AnimatedSprite2D.new()
		add_child(sprite)
		# You can set a simple colored rectangle for now
		sprite.modulate = Color.ORANGE_RED
	
	if not hitbox:
		hitbox = Area2D.new()
		var collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 8
		collision.shape = shape
		hitbox.add_child(collision)
		add_child(hitbox)
		hitbox.connect("body_entered", Callable(self, "_on_body_entered"))

func setup(dir: Vector2, spd: float, source: Node2D):
	direction = dir
	speed = spd
	shooter = source
	
	# Flip sprite based on direction
	if sprite:
		sprite.flip_h = direction.x < 0

func _physics_process(delta: float):
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		return
	
	# Move fireball
	velocity = direction * speed
	move_and_slide()
	
	# Remove if hit wall
	if get_slide_collision_count() > 0:
		var collision = get_slide_collision(0)
		if not (collision.get_collider() is Player):
			queue_free()

func _on_body_entered(body: Node2D):
	if body is Player and body != shooter:
		# Apply knockback to player
		var knockback_force = 300.0
		var knockback_vector = Vector2(direction.x * knockback_force, -150)
		body.apply_knockback(knockback_vector)
		
		# Remove fireball
		queue_free()
