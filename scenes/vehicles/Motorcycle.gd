extends VehicleBody3D

@export_group("Força do Veículo")
@export var max_engine_force: float = 300.0  # Aumentado um pouco para garantir força
@export var max_brake_force: float = 20.0
@export var max_steer_angle: float = 0.5  # Radianos (~28 a 30 graus)
@export var steer_speed: float = 2.5

@export_group("Interação")
@export var interact_distance: float = 3.0

@onready var camera: Camera3D = $CameraRig/SpringArm3D/Camera3D
@onready var dismount_position: Marker3D = $DismountPosition
@onready var roda_traseira: VehicleWheel3D = $RodaTraseira

var is_mounted: bool = false
var _player_scene: PackedScene = preload("res://scenes/player/Player.tscn")
var _interact_was_pressed: bool = false

func _ready() -> void:
	if camera:
		camera.current = false

func _physics_process(delta: float) -> void:
	if is_mounted:
		_process_vehicle_inputs(delta)
		_check_dismount()
	else:
		# Quando ninguém está a conduzir, zera a força e trava
		engine_force = 0.0
		brake = 5.0
		_check_mount()

func _process_vehicle_inputs(delta: float) -> void:
	# Aceleração (W para frente, S para trás/travão)
	var accel_input = 0.0
	if Input.is_key_pressed(KEY_W):
		accel_input = 1.0
	elif Input.is_key_pressed(KEY_S):
		accel_input = -1.0

	if accel_input > 0:
		engine_force = accel_input * max_engine_force
		brake = 0.0
	elif accel_input < 0:
		engine_force = 0.0
		brake = abs(accel_input) * max_brake_force
	else:
		engine_force = 0.0
		brake = 0.5 # Atrito natural ao soltar as teclas

	# Direção (A para a esquerda, D para a direita)
	var target_steer = 0.0
	if Input.is_key_pressed(KEY_A):
		target_steer = max_steer_angle
	elif Input.is_key_pressed(KEY_D):
		target_steer = -max_steer_angle

	# Inércia/peso no guiador
	steering = move_toward(steering, target_steer, steer_speed * delta)
	
	# Diagnóstico visual na consola para ver se a roda está a tocar no chão
	if roda_traseira and roda_traseira.is_in_contact():
		# Podes descomentar a linha abaixo se quiseres ver a força a atuar no output
		# print("A pitar o chão! Força: ", engine_force)
		pass
	else:
		print("AVISO: A roda traseira está no ar ou a colisão da moto está a segurá-la!")

func _check_mount() -> void:
	if not _is_interact_just_pressed():
		return

	var player = _find_player()
	if player == null:
		return

	var distancia = global_position.distance_to(player.global_position)
	if distancia <= interact_distance:
		_mount(player)

func _check_dismount() -> void:
	if not _is_interact_just_pressed():
		return
	_dismount()

func _mount(player: Node3D) -> void:
	is_mounted = true
	player.queue_free()  # Remove o personagem do mundo

	if camera:
		camera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _dismount() -> void:
	is_mounted = false
	if camera:
		camera.current = false

	# Recria o jogador na posição de saída
	var new_player = _player_scene.instantiate()
	get_parent().add_child(new_player)
	
	if dismount_position:
		new_player.global_position = dismount_position.global_position
	else:
		new_player.global_position = global_position + Vector3(1, 0, 0)

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _find_player() -> Node3D:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]

	var root = get_tree().current_scene
	if root != null:
		var player = root.find_child("Player", true, false)
		if player:
			return player

	return null

func _is_interact_just_pressed() -> bool:
	var pressed = Input.is_action_just_pressed("interact")
	if pressed and not _interact_was_pressed:
		_interact_was_pressed = true
		return true
	if not pressed:
		_interact_was_pressed = false
	return false
