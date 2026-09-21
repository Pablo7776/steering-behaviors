extends CharacterBody2D

@export var max_speed: float = 100.0
@export var max_force: float = 300.0

# Wander
@export var wander_radius: float = 40.0
@export var wander_distance: float = 60.0
@export var wander_jitter: float = 40.0

# Seek / Arrive
@export var seek_radius: float = 120.0            # distancia para empezar a perseguir
@export var return_to_wander_radius: float = 160.0 # distancia para volver a wander
@export var arrive_radius: float = 40.0            # distancia desde la cual empieza a frenar

var wander_angle: float = 0.0
var velocity_dir: Vector2 = Vector2.RIGHT

enum State { WANDER, SEEK, ARRIVE }
var current_state: State = State.WANDER

@export var player_path: NodePath
var player: Node2D

func _ready():
	wander_angle = randf_range(0, TAU)
	player = get_node(player_path)

func _physics_process(delta):
	update_state()

	var steering: Vector2

	match current_state:
		State.WANDER:
			steering = wander(delta)

		State.SEEK:
			steering = seek(player.global_position)

		State.ARRIVE:
			steering = arrive(player.global_position)

	apply_steering(steering, delta)
	move_and_slide()

func update_state():
	var dist = global_position.distance_to(player.global_position)

	match current_state:

		State.WANDER:
			if dist < seek_radius:
				current_state = State.SEEK

		State.SEEK:
			if dist < arrive_radius:
				current_state = State.ARRIVE
			elif dist > return_to_wander_radius:
				current_state = State.WANDER

		State.ARRIVE:
			if dist > return_to_wander_radius:
				current_state = State.WANDER
			elif dist > arrive_radius + 10.0:
				current_state = State.SEEK

func arrive(target: Vector2) -> Vector2:
	var to_target = target - global_position
	var dist = to_target.length()

	if dist < 1.0:
		return Vector2.ZERO

	# Velocidad deseada: máxima si está lejos del arrive_radius,
	# proporcional a la distancia si está dentro del arrive_radius (frenado)
	var speed = max_speed
	if dist < arrive_radius:
		speed = max_speed * (dist / arrive_radius)

	var desired = to_target.normalized() * speed
	var steer = desired - velocity
	return steer.limit_length(max_force)

func wander(delta: float) -> Vector2:
	wander_angle += randf_range(-1.0, 1.0) * wander_jitter * delta
	var circle_center = velocity_dir.normalized() * wander_distance
	var displacement = Vector2(cos(wander_angle), sin(wander_angle)) * wander_radius
	var target_local = circle_center + displacement
	var target_global = global_position + target_local
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
		rotation = velocity.angle()
