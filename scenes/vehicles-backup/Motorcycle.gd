extends CharacterBody3D

@export_group("Velocidade")
@export var max_speed: float = 18.0            ## Velocidade máxima para frente
@export var max_reverse_speed: float = 6.0    ## Velocidade máxima em ré
@export var acceleration: float = 8.0         ## Taxa de aceleração (W)
@export var reverse_acceleration: float = 5.0 ## Taxa de aceleração em ré (S parado)
@export var brake_deceleration: float = 20.0  ## Taxa de frenagem (S em movimento)
@export var auto_deceleration: float = 5.0    ## Desaceleração quando não há input

@export_group("Modelo Cinemático de Bicicleta (Kinematic Bicycle Model)")
@export var max_steer_angle: float = 35.0     ## Ângulo máximo da roda dianteira (em graus)
@export var steer_speed: float = 0.5          ## Velocidade com que o guidão vira ao apertar A/D
@export var wheelbase: float = 1.8            ## Distância entre a roda dianteira e a traseira (L)

@export_group("Câmera")
@export var mouse_sensitivity: float = 0.003  ## Sensibilidade do pitch da câmera
@export var min_pitch: float = -60.0          ## Pitch mínimo (olhar para cima)
@export var max_pitch: float = 50.0           ## Pitch máximo (olhar para baixo)

@export_group("Interação")
@export var interact_distance: float = 3.0    ## Distância máxima para montar

@onready var model: Node3D = $Model
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var spring_arm: SpringArm3D = $CameraRig/SpringArm3D
@onready var camera: Camera3D = $CameraRig/SpringArm3D/Camera3D
@onready var dismount_position: Marker3D = $DismountPosition

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_mounted: bool = false
var current_speed: float = 0.0
var current_steer_angle: float = 0.0          ## Ângulo atual da roda dianteira (δ)

var _player_scene: PackedScene = preload("res://scenes/player/Player.tscn")
var _interact_was_pressed: bool = false

func _ready() -> void:
	camera.current = false


func _unhandled_input(event: InputEvent) -> void:
	if not is_mounted:
		return

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		spring_arm.rotation.x -= event.relative.y * mouse_sensitivity
		spring_arm.rotation.x = clampf(
			spring_arm.rotation.x,
			deg_to_rad(min_pitch),
			deg_to_rad(max_pitch)
		)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if is_mounted:
		_process_acceleration(delta)
		_process_bicycle_steering(delta)
		_check_dismount()
	else:
		_check_mount()
		current_speed = move_toward(current_speed, 0.0, auto_deceleration * delta)
		current_steer_angle = move_toward(current_steer_angle, 0.0, steer_speed * delta)

	_apply_movement()
	move_and_slide()


func _process_acceleration(delta: float) -> void:
	# Aceleração para frente (W) / Ré ou Freio (S)
	if Input.is_action_pressed("move_forward"):
		current_speed = move_toward(current_speed, max_speed, acceleration * delta)
	elif Input.is_action_pressed("move_backward"):
		if current_speed > 0.5:
			current_speed = move_toward(current_speed, 0.0, brake_deceleration * delta)
		else:
			current_speed = move_toward(
				current_speed, -max_reverse_speed, reverse_acceleration * delta
			)
	else:
		current_speed = move_toward(current_speed, 0.0, auto_deceleration * delta)


# ============================================================================
# FÍSICA DO KINEMATIC BICYCLE MODEL
# ============================================================================

func _process_bicycle_steering(delta: float) -> void:
	# 1. Lê o input das teclas A e D para calcular o ângulo do guidão (δ)
	var target_steer := 0.0
	if Input.is_key_pressed(KEY_A):
		target_steer += deg_to_rad(max_steer_angle)
	if Input.is_key_pressed(KEY_D):
		target_steer -= deg_to_rad(max_steer_angle)

	# Suaviza a virada do guidão/roda da frente
	current_steer_angle = move_toward(current_steer_angle, target_steer, steer_speed * delta)

	# 2. Se a velocidade for muito baixa, a moto não vira (evita girar parada no eixo)
	if abs(current_speed) < 0.1 or current_steer_angle == 0.0:
		return

	# 3. FÓRMULA DO MODELO DE BICICLETA: ω = (v / L) * tan(δ)
	var angular_velocity: float = (current_speed / wheelbase) * tan(current_steer_angle)

	# Rotaciona a moto no eixo Y de acordo com a velocidade angular física
	rotate_y(angular_velocity * delta)


func _apply_movement() -> void:
	# A tração vem da roda traseira, empurrando a moto sempre para a frente no eixo local
	var forward_dir := -global_basis.z
	
	velocity.x = forward_dir.x * current_speed
	velocity.z = forward_dir.z * current_speed


func _check_mount() -> void:
	if not _is_interact_just_pressed():
		return

	var player := _find_player()
	if player == null:
		return

	if global_position.distance_to(player.global_position) > interact_distance:
		return

	_mount(player)


func _check_dismount() -> void:
	if not _is_interact_just_pressed():
		return

	_dismount()


func _mount(player: CharacterBody3D) -> void:
	is_mounted = true
	player.queue_free()

	camera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _dismount() -> void:
	is_mounted = false
	camera.current = false

	var new_player: CharacterBody3D = _player_scene.instantiate()
	get_parent().add_child(new_player)
	new_player.global_position = dismount_position.global_position

	var cam_rig: Node3D = new_player.get_node("CameraRig")
	if cam_rig:
		cam_rig.rotation.y = global_rotation.y


func _find_player() -> CharacterBody3D:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0] as CharacterBody3D

	var root := get_tree().current_scene
	if root == null:
		return null

	var player := root.find_child("Player", true, false)
	if player is CharacterBody3D:
		return player

	return null


func _is_interact_just_pressed() -> bool:
	var pressed := Input.is_action_just_pressed("interact")

	if pressed and not _interact_was_pressed:
		_interact_was_pressed = true
		return true

	if not pressed:
		_interact_was_pressed = false

	return false
