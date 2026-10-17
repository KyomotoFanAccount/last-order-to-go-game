extends CharacterBody3D

@export var speed: float = 5.0
@export var gravity: float = 9.8
@export var jump_force: float = 4.5  # <--- Força do pulo

@export_group("Câmera")
@export var mouse_sensitivity: float = 0.003
@export var min_pitch: float = -60.0
@export var max_pitch: float = 50.0

@onready var visual: Node3D = $VisualPivot
@onready var camera_rig: Node3D = $CameraRig
@onready var spring_arm: SpringArm3D = $CameraRig/SpringArm3D
@onready var camera: Camera3D = $CameraRig/SpringArm3D/Camera3D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	
	# Garante que a câmera do jogador fica ativa ao entrar na cena
	# (essencial para quando o jogador é re-instanciado ao desmontar da moto)
	camera.current = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_rig.rotation.y -= event.relative.x * mouse_sensitivity
		spring_arm.rotation.x -= event.relative.y * mouse_sensitivity
		spring_arm.rotation.x = clampf(
			spring_arm.rotation.x,
			deg_to_rad(min_pitch),
			deg_to_rad(max_pitch)
		)

func _physics_process(delta: float) -> void:
	# Aplica gravidade se não estiver no chão
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		# Pula se estiver no chão e apertar a barra de espaço (ou a ação ui_accept)
		if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE):
			velocity.y = jump_force

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	var cam_forward := -camera_rig.global_basis.z
	var cam_right := camera_rig.global_basis.x
	cam_forward.y = 0.0
	cam_right.y = 0.0
	cam_forward = cam_forward.normalized()
	cam_right = cam_right.normalized()

	var direction := (cam_right * input_dir.x - cam_forward * input_dir.y).normalized()

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		
		var target_angle := atan2(-direction.x, -direction.z)
		visual.rotation.y = lerp_angle(visual.rotation.y, target_angle, 15.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)

	move_and_slide()
