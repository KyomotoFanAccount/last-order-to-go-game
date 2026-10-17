extends RigidBody3D

@export var forca_motor: float = 25.0
@export var forca_viragem: float = 2.0

func _integrate_forces(state: PhysicsDirectBodyState3D):
	# Pega nas teclas de movimento (W/S ou Setas Cima/Baixo para acelerar/recuar)
	var aceleracao = Input.get_axis("ui_down", "ui_up")
	
	if aceleracao != 0:
		# Aplica a força baseada para onde a moto está a apontar
		var direcao_frente = -global_transform.basis.z
		apply_central_force(direcao_frente * aceleracao * forca_motor)

	# Se quiseres que a moto vire para os lados com A/D ou Setas Esquerda/Direita
	var virar = Input.get_axis("ui_right", "ui_left")
	if virar != 0 and linear_velocity.length() > 0.5:
		apply_torque(Vector3(0, virar * forca_viragem, 0))
