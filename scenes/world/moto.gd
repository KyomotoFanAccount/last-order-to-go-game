extends CharacterBody3D

# Configurações de velocidade e física
@export var SPEED : float = 12.0
@export var ACCELERATION : float = 6.0
@export var BRAKE_SPEED : float = 10.0
@export var ROTATION_SPEED : float = 2.5

# Gravidade padrão do projeto
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta):
	# Aplica a gravidade se estiver no ar
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Controles de Entrada (Acelerar/Ré)
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Direção da aceleração (ui_up para frente, ui_down para trás)
	var forward_dir = -transform.basis.z
	
	if input_dir.y < 0:
		# Acelerar para a frente
		velocity.x = move_toward(velocity.x, forward_dir.x * SPEED, ACCELERATION * delta * 10)
		velocity.z = move_toward(velocity.z, forward_dir.z * SPEED, ACCELERATION * delta * 10)
	elif input_dir.y > 0:
		# Marcha-atrás
		velocity.x = move_toward(velocity.x, -forward_dir.x * (SPEED / 2), BRAKE_SPEED * delta * 10)
		velocity.z = move_toward(velocity.z, -forward_dir.z * (SPEED / 2), BRAKE_SPEED * delta * 10)
	else:
		# Desacelerar/Parar
		velocity.x = move_toward(velocity.x, 0, BRAKE_SPEED * delta * 5)
		velocity.z = move_toward(velocity.z, 0, BRAKE_SPEED * delta * 5)

	# Fazer a moto virar para os lados ao andar (ui_left / ui_right)
	if input_dir.x != 0 and velocity.length() > 0.5:
		rotate_y(-input_dir.x * ROTATION_SPEED * delta)

	# Aplica o movimento final
	move_and_slide()
