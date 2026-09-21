extends CharacterBody2D

@export var max_speed: float = 80.0
@export var max_force: float = 200.0

# Parámetros del wander
@export var wander_radius: float = 40.0    # radio del círculo
@export var wander_distance: float = 60.0  # distancia del círculo al NPC
@export var wander_jitter: float = 40.0    # cuánto varía el ángulo por segundo

var wander_angle: float = 0.0
var velocity_dir: Vector2 = Vector2.RIGHT  # dirección actual (para orientar el círculo)

func _ready():
	wander_angle = randf_range(0, TAU)

func _physics_process(delta):
	var steering = wander(delta)
	apply_steering(steering, delta)
	move_and_slide()

func wander(delta: float) -> Vector2:
	# 1) Mover el ángulo del wander de forma aleatoria (jitter)
	wander_angle += randf_range(-1.0, 1.0) * wander_jitter * delta

	# 2) Centro del círculo: adelante del NPC, en la dirección en que se mueve
	var circle_center = velocity_dir.normalized() * wander_distance

	# 3) Punto objetivo sobre el círculo
	var displacement = Vector2(cos(wander_angle), sin(wander_angle)) * wander_radius

	var target_local = circle_center + displacement
	var target_global = global_position + target_local

	# 4) Seek hacia ese punto
	return seek(target_global)

func seek(target: Vector2) -> Vector2:
	var desired = (target - global_position).normalized() * max_speed
	var steer = desired - velocity
	return steer.limit_length(max_force)

func apply_steering(steering: Vector2, delta: float):
	velocity += steering * delta
	velocity = velocity.limit_length(max_speed)
	if velocity.length() > 1.0:
		velocity_dir = velocity.normalized()
		rotation = velocity.angle()  # opcional, si querés que el sprite mire hacia donde va
