extends CharacterBody3D

@export_group("Velocidade")
@export var max_speed: float = 18.0           ## Velocidade máxima para frente
@export var max_reverse_speed: float = 6.0    ## Velocidade máxima em ré
@export var acceleration: float = 8.0         ## Taxa de aceleração ao segurar W
@export var reverse_acceleration: float = 5.0 ## Taxa de aceleração em ré (S parado)
@export var brake_deceleration: float = 20.0  ## Taxa de frenagem forte (S em movimento)
@export var auto_deceleration: float = 5.0    ## Desaceleração quando não há input

@export_group("Direção e Drift")
@export var steering_speed: float = 2.5       ## Velocidade base de curva (A/D)
@export var drift_factor: float = 0.85        ## Retenção de velocidade lateral (0=tração total, 1=gelo)
@export var min_speed_to_turn: float = 0.5    ## Velocidade mínima para poder virar

@export_group("Câmera")
@export var mouse_sensitivity: float = 0.003  ## Sensibilidade do pitch da câmera
@export var min_pitch: float = -60.0          ## Pitch mínimo (graus, olhar para cima)
@export var max_pitch: float = 50.0           ## Pitch máximo (graus, olhar para baixo)

@export_group("Interação")
@export var interact_distance: float = 3.0    ## Distância máxima para montar na moto

@onready var model: Node3D = $Model
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var spring_arm: SpringArm3D = $CameraRig/SpringArm3D
@onready var camera: Camera3D = $CameraRig/SpringArm3D/Camera3D
@onready var dismount_position: Marker3D = $DismountPosition

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_mounted: bool = false
var current_speed: float = 0.0
var _player_scene: PackedScene = preload("res://scenes/player/Player.tscn")
var _interact_was_pressed: bool = false

func _ready() -> void:
	camera.current = false


func _unhandled_input(event: InputEvent) -> void:
	# Só processa input de câmera se estiver montado
	if not is_mounted:
		return

	# ESC libera o cursor do mouse
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Camera é apenas cima/baixo
	# O yaw (esquerda/direita) acompanha a rotação da moto automaticamente,
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
		_process_steering(delta)
		_check_dismount()
	else:
		_check_mount()
		# A moto freia sozinha quando ninguém está pilotando
		current_speed = move_toward(current_speed, 0.0, auto_deceleration * delta)

	# movimento da moto com drift agora
	_apply_movement()

	move_and_slide()

func _process_acceleration(delta: float) -> void:
	# Processa W (acelerar), S (freiar / ré)

	if Input.is_action_pressed("move_forward"):
		current_speed = move_toward(current_speed, max_speed, acceleration * delta)

	elif Input.is_action_pressed("move_backward"):
		if current_speed > 0.5:
			current_speed = move_toward(current_speed, 0.0, brake_deceleration * delta)
		else:
			# Ré
			current_speed = move_toward(
				current_speed, -max_reverse_speed, reverse_acceleration * delta
			)
	else:
		# Perder velocidade se nada estiver sendo pressionado
		current_speed = move_toward(current_speed, 0.0, auto_deceleration * delta)


# ============================================================================
# DIREÇÃO E DRIFT
# ============================================================================

func _process_steering(delta: float) -> void:
	## Processa curvas (A/D) com drift integrado.
	##
	## O drift funciona assim:
	##   - Ao virar em alta velocidade, a velocidade lateral (perpendicular à moto)
	##     não é zerada instantaneamente — ela é retida pelo drift_factor.
	##   - Isso faz a moto "deslizar" lateralmente ao fazer curvas rápidas.
	##   - Quanto maior o drift_factor (0.0 a 1.0), mais a moto derrapa.

	# Lê input de direção
	var turn_input := 0.0
	if Input.is_key_pressed(KEY_A):
		turn_input += 1.0
	if Input.is_key_pressed(KEY_D):
		turn_input -= 1.0

	# Só vira se estiver em movimento suficiente
	if turn_input == 0.0 or abs(current_speed) < min_speed_to_turn:
		return

	# Quanto mais rápido, mais responsiva é a curva (sensação de drift)
	var speed_ratio: float = abs(current_speed) / max_speed
	var effective_steering: float = steering_speed * (0.6 + 0.4 * speed_ratio)

	# Em ré, a direção de curva é invertida (como um carro real)
	if current_speed < 0.0:
		turn_input = -turn_input

	# Rotaciona a moto
	rotate_y(turn_input * effective_steering * delta)


func _apply_movement() -> void:
	var forward_dir := -global_basis.z  # Direção para onde a moto aponta
	var right_dir := global_basis.x     # Direção lateral da moto

	# Componente lateral atual da velocidade (perpendicular à moto)
	var current_lateral := velocity.dot(right_dir)

	# Drift: retém parte da velocidade lateral em vez de zerá-la
	# drift_factor = 0.85 significa que 85% da velocidade lateral é mantida
	var drifted_lateral := current_lateral * drift_factor

	velocity.x = forward_dir.x * current_speed + right_dir.x * drifted_lateral
	velocity.z = forward_dir.z * current_speed + right_dir.z * drifted_lateral


func _check_mount() -> void:
	# Verifica se o jogador pressionou F perto o suficiente para montar.

	if not _is_interact_just_pressed():
		return

	# Procura o jogador na cena
	var player := _find_player()
	if player == null:
		return

	# Verifica se está dentro da distância de interação
	if global_position.distance_to(player.global_position) > interact_distance:
		return

	_mount(player)


func _check_dismount() -> void:
	## Verifica se o jogador pressionou "interact" para desmontar.

	if not _is_interact_just_pressed():
		return

	_dismount()


func _mount(player: CharacterBody3D) -> void:
	## Monta na scooter.
	## Remove o jogador da cena e ativa a câmera da moto.

	is_mounted = true

	# Remove o jogador
	player.queue_free()

	# Ativa a câmera da moto e captura o mouse
	camera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _dismount() -> void:
	## Sai da scooter.
	## Em resumo: desativa a câmera, e instancia o jogador ao lado.

	is_mounted = false

	# Desativa a câmera da moto ANTES de instanciar o jogador
	camera.current = false

	# Re-instancia o jogador no ponto de desmontagem
	var new_player: CharacterBody3D = _player_scene.instantiate()
	get_parent().add_child(new_player)

	# Posiciona ao lado da moto (DismountPosition é um Marker3D à direita)
	new_player.global_position = dismount_position.global_position

	# NÃO rotacionar o CharacterBody3D do jogador — o sistema de movimento
	# dele depende do root ficar em rotação 0. Em vez disso, orienta o
	# CameraRig para que a câmera aponte na mesma direção da moto.
	var cam_rig: Node3D = new_player.get_node("CameraRig")
	if cam_rig:
		cam_rig.rotation.y = global_rotation.y

func _find_player() -> CharacterBody3D:
	## Procura o jogador na cena, primeiro pelo grupo "player", depois pelo nome.

	# Tenta pelo grupo "player"
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0] as CharacterBody3D

	# Fallback: procura pelo nome "Player" na cena atual
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
