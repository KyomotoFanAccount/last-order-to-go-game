extends VehicleBody3D

@export_group("Força do Veículo")
@export var max_engine_force: float = 300.0
@export var max_brake_force: float = 20.0
@export var max_steer_angle: float = 0.5  # Radianos (~28 a 30 graus)
@export var steer_speed: float = 2.5

@export_group("Empinar (Wheelie)")
@export var wheelie_torque: float = 200.0

@export_group("Câmera")
@export var mouse_sensitivity: float = 0.003
@export var min_pitch: float = -60.0
@export var max_pitch: float = 50.0

@export_group("Interação")
@export var interact_distance: float = 3.0

@onready var camera_rig: Node3D = $CameraRig
@onready var spring_arm: SpringArm3D = $CameraRig/SpringArm3D
@onready var camera: Camera3D = $CameraRig/SpringArm3D/Camera3D
@onready var dismount_position: Marker3D = $DismountPosition
@onready var roda_traseira: VehicleWheel3D = $RodaTraseira

var is_mounted: bool = false
var _player_scene: PackedScene = preload("res://scenes/player/Player.tscn")
var _interact_was_pressed: bool = false

func _ready() -> void:
	if camera:
		camera.current = false

func _unhandled_input(event: InputEvent) -> void:
	if not is_mounted:
		return

	# Liberta o rato com o ESC
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Controlo da câmara com o rato
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Rotação vertical (Pitch) no SpringArm3D
		if spring_arm:
			spring_arm.rotation.x -= event.relative.y * mouse_sensitivity
			spring_arm.rotation.x = clampf(
				spring_arm.rotation.x,
				deg_to_rad(min_pitch),
				deg_to_rad(max_pitch)
			)
			
		# Rotação horizontal (Yaw) apenas no CameraRig (a moto fica a direito)
		if camera_rig:
			camera_rig.rotation.y -= event.relative.x * mouse_sensitivity

func _physics_process(delta: float) -> void:
	if is_mounted:
		_process_vehicle_inputs(delta)
		_check_dismount()
	else:
		engine_force = 0.0
		brake = 5.0
		_check_mount()

func _process_vehicle_inputs(delta: float) -> void:
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
		brake = 0.5

	var target_steer = 0.0
	if Input.is_key_pressed(KEY_A):
		target_steer = max_steer_angle
	elif Input.is_key_pressed(KEY_D):
		target_steer = -max_steer_angle

	steering = move_toward(steering, target_steer, steer_speed * delta)
	
	# Mecânica de Empinar (Wheelie): W + Espaço
	if accel_input > 0 and Input.is_key_pressed(KEY_SPACE):
		apply_torque(global_transform.basis * Vector3(-wheelie_torque, 0, 0))

func _check_mount() -> void:
	if not _is_interact_just_pressed():
		return

	var player = _find_player()
	if player == null:
		return

	if global_position.distance_to(player.global_position) <= interact_distance:
		_mount(player)

func _check_dismount() -> void:
	if not _is_interact_just_pressed():
		return
	_dismount()

func _mount(player: Node3D) -> void:
	is_mounted = true
	player.queue_free()

	if camera:
		camera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _dismount() -> void:
	is_mounted = false
	if camera:
		camera.current = false

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
