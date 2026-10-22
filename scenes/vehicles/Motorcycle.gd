extends VehicleBody3D
# Moto estilo GTA 5 em cima do VehicleBody3D, com drift estilo Mario Kart.
# Controles:
#   F = montar / desmontar
#   W = acelerar | S = frear / ré | A / D = virar
#   Espaço (com W) = empinar | Mouse = câmera | ESC = soltar o mouse
#   Shift (segurando) + A/D em velocidade = drift (solte para ganhar turbo)
#   No ar: W/S = inclinar o nariz | Q/E = rolar de lado | A/D = girar no próprio eixo (estilo GTA)
#   ↑ / ↓ = aumenta / diminui a velocidade máxima (teste)

@export_group("Força do Veículo")
@export var max_engine_force: float = 2000.0
@export var max_speed: float = 40.0           # m/s (40 m/s = 144 km/h)
@export var brake_strength: float = 6.0       # força máxima do freio (sobe aos poucos)
@export var brake_ramp_time: float = 0.7      # segundos até o freio chegar na força máxima
@export var idle_brake: float = 0.4           # freio-motor ao soltar o acelerador
@export var allow_reverse: bool = true
@export var reverse_speed: float = 10.0       # m/s (36 km/h)
@export var reverse_force_mult: float = 1.0   # força do motor na ré (1 = igual à frente)
@export var reverse_accel: float = 6.0        # m/s²: empurrão extra direto para trás

@export_group("Direção (estilo GTA)")
@export var max_steer_deg: float = 35.0       # ângulo máximo da roda em baixa velocidade
@export var steer_speed: float = 3.0          # rad/s: rapidez com que o guidão vira
@export var steer_multiplier: float = 1.0     # multiplica o ângulo real da roda em todas as velocidades (1 = como está)
@export var steer_hard_limit_deg: float = 60.0 # trava de segurança: o ângulo real nunca passa disso
@export var lateral_accel_low: float = 3.5    # m/s² de força lateral em baixa velocidade (pouca inclinação)
@export var lateral_accel_high: float = 14.0  # m/s² na velocidade de referência (muita inclinação)
@export var handling_ref_speed: float = 40.0  # m/s: referência do grip (não muda com o max_speed)
@export var yaw_response: float = 15.0        # quão rápido a moto acompanha a curva
@export var lateral_grip: float = 6.0         # quanto maior, menos a moto escorrega de lado

@export_group("Inclinação nas Curvas (visual)")
@export var lean_enabled: bool = true
@export var lean_factor: float = 1.0
@export var max_lean_deg: float = 35.0
@export var lean_stiffness: float = 40.0      # rigidez da inclinação (maior = responde mais rápido)
@export var lean_damping: float = 10.0        # amortecimento (evita balançar)

@export_group("Empinar (Wheelie Arcade)")
@export var wheelie_torque: float = 1500.0    # torque máximo para levantar a roda
@export var wheelie_gain: float = 400.0       # força para segurar a moto no ângulo
@export var wheelie_rise_speed: float = 2.0   # rad/s: velocidade com que a roda sobe
@export var wheelie_max_angle_deg: float = 55.0
@export var wheelie_needs_throttle: bool = true  # false = empina só com Espaço (até parado)

@export_group("Drift (estilo Mario Kart)")
@export var drift_enabled: bool = true
@export var drift_min_speed: float = 8.0      # m/s (≈ 29 km/h) para poder entrar no drift
@export var drift_turn_boost: float = 2.4     # curva mais fechada durante o drift
@export var drift_grip_mult: float = 0.05     # grip lateral durante o drift (menor = escorrega mais)
@export var drift_rear_friction: float = 0.2  # fricção da roda traseira durante o drift
@export var drift_hop_velocity: float = 1.2   # pulinho ao entrar no drift (0 = sem pulo)
@export var drift_turbo_enabled: bool = false # true = ganha turbo ao soltar o drift
@export var drift_level1_time: float = 0.8    # segundos de drift para o turbo azul
@export var drift_level2_time: float = 1.6    # turbo laranja
@export var drift_level3_time: float = 2.5    # turbo roxo
@export var boost_time_1: float = 0.6         # duração do turbo de cada nível (s)
@export var boost_time_2: float = 1.0
@export var boost_time_3: float = 1.5
@export var boost_engine_mult: float = 1.8    # força do motor durante o turbo
@export var boost_speed_mult: float = 1.3     # a velocidade máxima sobe nessa proporção
@export var boost_accel: float = 10.0         # empurrão extra do turbo (m/s²)

@export_group("Roda da Frente (só visual)")
@export var front_visual: Node3D                  # arraste aqui o nó do garfo/guidão do modelo
@export var visual_max_deg: float = 45.0          # ângulo visual máximo (não afeta a física)
@export var visual_high_speed_factor: float = 0.35 # em alta velocidade o ângulo visual cai para essa fração
@export var visual_ref_speed: float = 30.0        # m/s: velocidade em que vale o fator acima
@export var visual_steer_speed: float = 8.0       # rad/s: rapidez do giro visual
@export var visual_steer_axis: Vector3 = Vector3.UP # eixo de giro (local do nó)
@export var visual_invert: bool = false           # marque se o garfo girar para o lado errado

@export_group("Controle no Ar (estilo GTA)")
@export var air_min_time: float = 0.15        # s no ar antes de liberar o controle (evita ativar em trepidação)
@export var air_pitch_speed: float = 3.0      # rad/s: W/S inclinam o nariz
@export var air_roll_speed: float = 4.0       # rad/s: Q/E rolam a moto de lado
@export var air_yaw_speed: float = 3.0        # rad/s: A/D giram a moto no próprio eixo (vertical)
@export var air_accel: float = 14.0           # rad/s²: rapidez para atingir a rotação desejada
@export var air_brake: float = 3.0            # rad/s²: quanto a rotação freia sozinha sem input (0 = gira para sempre)
@export var ground_level_speed: float = 8.0   # quão rápido a moto se endireita ao pousar
@export var ground_level_max: float = 6.0     # rad/s: limite dessa correção

@export_group("Teste de Velocidade")
@export var speed_step_kmh: float = 10.0       # quanto muda a cada toque em ↑ / ↓
@export var min_test_speed_kmh: float = 10.0
@export var max_test_speed_kmh: float = 300.0
@export var hard_speed_limit: bool = true      # trava de verdade a velocidade em max_speed

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
@onready var model: Node3D = get_node_or_null("Model") as Node3D
@onready var front_wheel: VehicleWheel3D = get_node_or_null("RodaFrontal") as VehicleWheel3D
@onready var rear_wheel: VehicleWheel3D = get_node_or_null("RodaTraseira") as VehicleWheel3D

var is_mounted: bool = false
var camera_yaw: float = 0.0
var _player_scene: PackedScene = preload("res://scenes/player/Player.tscn")
var _interact_was_pressed: bool = false

var _wheelbase: float = 1.4
var _lean_current: float = 0.0
var _lean_velocity: float = 0.0
var _brake_current: float = 0.0
var _model_base_transform: Transform3D = Transform3D.IDENTITY

var _drifting: bool = false
var _drift_dir: float = 0.0
var _drift_charge: float = 0.0
var _boost_time_left: float = 0.0
var _rear_friction_base: float = 10.5

var _front_visual_base: Transform3D = Transform3D.IDENTITY
var _front_visual_angle: float = 0.0
var _last_turn_input: float = 0.0

var _grounded: bool = false
var _air_time: float = 0.0
var _in_air: bool = false

var _speed_label: Label
var _drift_label: Label

func _ready() -> void:
	can_sleep = false

	if camera:
		camera.current = false

	if camera_rig:
		camera_rig.top_level = true

	# Garante a configuração das rodas (não depende do Inspetor)
	if rear_wheel:
		rear_wheel.use_as_traction = true
		rear_wheel.use_as_steering = false
		_rear_friction_base = rear_wheel.wheel_friction_slip
	if front_wheel:
		front_wheel.use_as_steering = true
		front_wheel.use_as_traction = false

	# Distância entre eixos, usada para calcular a curva
	if front_wheel and rear_wheel:
		_wheelbase = absf(front_wheel.position.z - rear_wheel.position.z)
		if _wheelbase < 0.2:
			_wheelbase = 1.4

	if model:
		_model_base_transform = model.transform

	if front_visual:
		_front_visual_base = front_visual.transform

	_create_hud()

func _unhandled_input(event: InputEvent) -> void:
	if not is_mounted:
		return

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# ↑ / ↓ = aumenta / diminui a velocidade máxima (segure para repetir)
	if event is InputEventKey and event.pressed:
		var max_kmh = max_speed * 3.6
		if event.keycode == KEY_UP:
			max_kmh = minf(max_kmh + speed_step_kmh, max_test_speed_kmh)
		elif event.keycode == KEY_DOWN:
			max_kmh = maxf(max_kmh - speed_step_kmh, min_test_speed_kmh)
		max_speed = max_kmh / 3.6

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if spring_arm:
			spring_arm.rotation.x -= event.relative.y * mouse_sensitivity
			spring_arm.rotation.x = clampf(
				spring_arm.rotation.x,
				deg_to_rad(min_pitch),
				deg_to_rad(max_pitch)
			)

		camera_yaw -= event.relative.x * mouse_sensitivity

func _physics_process(delta: float) -> void:
	_update_air_state(delta)

	if is_mounted:
		_process_vehicle_inputs(delta)
		_air_control(delta)
		_limit_speed()
		_check_dismount()
	else:
		engine_force = 0.0
		brake = 5.0
		steering = 0.0
		_brake_current = 0.0
		_last_turn_input = 0.0
		_check_mount()

	_stabilize_roll()
	_update_lean(delta)
	_update_front_visual(delta)
	_update_hud()

	if is_mounted and camera_rig:
		camera_rig.global_position = global_position
		camera_rig.rotation.y = camera_yaw

# ------------------------------------------------------------------
# Física da moto
# ------------------------------------------------------------------

# Velocidade máxima atual (sobe durante o turbo do drift)
func _effective_max_speed() -> float:
	if _boost_time_left > 0.0:
		return max_speed * boost_speed_mult
	return max_speed

func _process_vehicle_inputs(delta: float) -> void:
	var forward_speed = -global_transform.basis.z.dot(linear_velocity)

	var front_contact = front_wheel != null and front_wheel.is_in_contact()
	var rear_contact = rear_wheel != null and rear_wheel.is_in_contact()
	var grounded = front_contact or rear_contact

	var w_pressed = Input.is_key_pressed(KEY_W)
	var s_pressed = Input.is_key_pressed(KEY_S)

	var boosting = _boost_time_left > 0.0
	if boosting:
		_boost_time_left = maxf(_boost_time_left - delta, 0.0)

	# --- Aceleração / freio / ré ---
	var speed_ratio = clampf(forward_speed / _effective_max_speed(), 0.0, 1.0)
	var power_factor = 1.0 - speed_ratio * speed_ratio
	var brake_target = 0.0

	if w_pressed and not s_pressed:
		if forward_speed < -1.0:
			# Está de ré: freia antes de acelerar para frente
			engine_force = 0.0
			brake_target = brake_strength
		else:
			var boost_mult = boost_engine_mult if boosting else 1.0
			engine_force = max_engine_force * power_factor * boost_mult
	elif s_pressed and not w_pressed:
		if forward_speed > 1.0:
			engine_force = 0.0
			brake_target = brake_strength
		elif allow_reverse:
			var reverse_ratio = clampf(-forward_speed / reverse_speed, 0.0, 1.0)
			var reverse_power = 1.0 - reverse_ratio * reverse_ratio
			engine_force = -max_engine_force * reverse_force_mult * reverse_power
			# Empurrão direto para trás: garante que a ré ande mesmo se a roda não tracionar
			if grounded:
				apply_central_force(global_transform.basis.z * mass * reverse_accel * reverse_power)
		else:
			engine_force = 0.0
			brake_target = brake_strength
	else:
		engine_force = 0.0
		brake_target = idle_brake

	# Empurrão extra do turbo (funciona mesmo na velocidade máxima normal)
	if boosting and grounded:
		apply_central_force(-global_transform.basis.z * mass * boost_accel)
		brake_target = 0.0

	# O freio sobe aos poucos (não trava de uma vez) e solta na hora
	if brake_target <= _brake_current:
		_brake_current = brake_target
	else:
		var ramp_rate = brake_strength / maxf(brake_ramp_time, 0.05)
		_brake_current = move_toward(_brake_current, brake_target, ramp_rate * delta)
	brake = _brake_current

	# --- Direção estilo GTA ---
	var turn_input = 0.0
	if Input.is_key_pressed(KEY_A):
		turn_input = 1.0
	elif Input.is_key_pressed(KEY_D):
		turn_input = -1.0

	# Drift: trava a direção da curva e só deixa fechar ou abrir um pouco
	turn_input = _update_drift(delta, turn_input, forward_speed, grounded)
	_last_turn_input = clampf(turn_input, -1.0, 1.0)

	# Em velocidade alta o ângulo máximo diminui (limite de grip lateral)
	var speed_t = clampf(absf(forward_speed) / handling_ref_speed, 0.0, 1.0)
	var lateral_accel_limit = lerpf(lateral_accel_low, lateral_accel_high, speed_t * speed_t)
	if _drifting:
		lateral_accel_limit *= drift_turn_boost
	var grip_limit = atan(_wheelbase * lateral_accel_limit / maxf(forward_speed * forward_speed, 1.0))
	var max_steer_rad = deg_to_rad(max_steer_deg)
	var steer_limit = minf(max_steer_rad, grip_limit) * steer_multiplier
	var steer_cap = minf(max_steer_rad * steer_multiplier, deg_to_rad(steer_hard_limit_deg))
	var steer_target = clampf(turn_input * steer_limit, -steer_cap, steer_cap)
	steering = move_toward(steering, steer_target, steer_speed * delta)

	# A moto gira conforme a geometria da roda (modelo de bicicleta):
	# raio pequeno em baixa velocidade, raio grande em alta
	if rear_contact:
		var up = global_transform.basis.y
		var target_yaw = forward_speed * tan(steering) / _wheelbase
		var current_yaw = angular_velocity.dot(up)
		var new_yaw = move_toward(current_yaw, target_yaw, yaw_response * delta)
		angular_velocity += up * (new_yaw - current_yaw)

		# Grip lateral: evita escorregar de lado (menor durante o drift)
		var grip = lateral_grip
		if _drifting:
			grip *= drift_grip_mult
		var lateral_speed = global_transform.basis.x.dot(linear_velocity)
		apply_central_force(-global_transform.basis.x * lateral_speed * mass * grip)

	# --- Empinar (Espaço, com W por padrão) ---
	# Só aplica um torque de inclinação (sem força linear), então não muda a
	# velocidade da moto e não depende dela.
	var wheelie_throttle_ok = w_pressed or not wheelie_needs_throttle
	if wheelie_throttle_ok and Input.is_key_pressed(KEY_SPACE) and rear_contact:
		var is_right_side_up = global_transform.basis.y.dot(Vector3.UP) > 0.4

		if is_right_side_up:
			var forward_vector = -global_transform.basis.z
			var pitch_rad = asin(clampf(forward_vector.y, -1.0, 1.0))
			var target_rad = deg_to_rad(maxf(wheelie_max_angle_deg, 1.0))
			var pitch_rate = angular_velocity.dot(global_transform.basis.x)

			# Sobe suave até o ângulo alvo e segura a moto lá
			var desired_rate = clampf((target_rad - pitch_rad) * 4.0, -wheelie_rise_speed, wheelie_rise_speed)
			var torque = clampf((desired_rate - pitch_rate) * wheelie_gain, -wheelie_torque, wheelie_torque)
			apply_torque(global_transform.basis.x * torque)

# ------------------------------------------------------------------
# Controle no ar (estilo GTA)
# ------------------------------------------------------------------

func _update_air_state(delta: float) -> void:
	var front_contact = front_wheel != null and front_wheel.is_in_contact()
	var rear_contact = rear_wheel != null and rear_wheel.is_in_contact()
	_grounded = front_contact or rear_contact
	if _grounded:
		_air_time = 0.0
	else:
		_air_time += delta
	_in_air = _air_time >= air_min_time

# W/S = inclina o nariz (pitch), Q/E = rola de lado (roll), A/D = gira no próprio eixo (yaw).
# Controla a velocidade angular direto, então a resposta é firme e previsível.
func _air_control(delta: float) -> void:
	if not _in_air:
		return

	var pitch_in = 0.0
	if Input.is_key_pressed(KEY_S):
		pitch_in += 1.0   # S levanta o nariz
	if Input.is_key_pressed(KEY_W):
		pitch_in -= 1.0   # W abaixa o nariz

	var roll_in = 0.0
	if Input.is_key_pressed(KEY_E):
		roll_in += 1.0    # E rola para a direita
	if Input.is_key_pressed(KEY_Q):
		roll_in -= 1.0    # Q rola para a esquerda

	var yaw_in = 0.0
	if Input.is_key_pressed(KEY_A):
		yaw_in += 1.0     # A gira para a esquerda
	if Input.is_key_pressed(KEY_D):
		yaw_in -= 1.0     # D gira para a direita

	var b = global_transform.basis
	_apply_air_rate(b.x, pitch_in * air_pitch_speed, pitch_in != 0.0, delta)
	_apply_air_rate(-b.z, roll_in * air_roll_speed, roll_in != 0.0, delta)
	_apply_air_rate(b.y, yaw_in * air_yaw_speed, yaw_in != 0.0, delta)

func _apply_air_rate(axis: Vector3, target: float, has_input: bool, delta: float) -> void:
	var current = angular_velocity.dot(axis)
	var rate = air_accel if has_input else air_brake
	angular_velocity += axis * (move_toward(current, target, rate * delta) - current)

# No chão: trava a rolagem e endireita a moto (importante ao pousar torta).
# No ar: deixa a rolagem livre.
func _stabilize_roll() -> void:
	if _in_air:
		return

	var fwd = -global_transform.basis.z
	var up = global_transform.basis.y

	# Zera só a rolagem (eixo local Z) sem mexer na transform do corpo físico
	angular_velocity -= fwd * angular_velocity.dot(fwd)

	# Se está de ponta-cabeça, não corrige (isso vira "queda" depois)
	if up.dot(Vector3.UP) > 0.3:
		var target_up = Vector3.UP - fwd * Vector3.UP.dot(fwd)
		if target_up.length() > 0.2:
			var angle = up.signed_angle_to(target_up.normalized(), fwd)
			angular_velocity += fwd * clampf(angle * ground_level_speed, -ground_level_max, ground_level_max)

# ------------------------------------------------------------------
# Drift estilo Mario Kart
# ------------------------------------------------------------------

# Devolve o "turn_input" a usar (no drift ele fica preso na direção escolhida)
func _update_drift(delta: float, turn_input: float, forward_speed: float, grounded: bool) -> float:
	if not drift_enabled:
		return turn_input

	var shift_pressed = Input.is_key_pressed(KEY_SHIFT)

	if not _drifting:
		if shift_pressed and grounded and forward_speed > drift_min_speed and turn_input != 0.0:
			_start_drift(turn_input)
	else:
		if not shift_pressed or forward_speed < drift_min_speed * 0.6:
			_end_drift(true)

	if not _drifting:
		return turn_input

	# Carga do mini-turbo
	if grounded:
		_drift_charge += delta * (0.7 + 0.3 * absf(turn_input))

	# Apertar para o lado do drift fecha a curva; para o outro lado, abre
	var factor = clampf(1.0 + 0.5 * turn_input * _drift_dir, 0.5, 1.5)
	return _drift_dir * factor

func _start_drift(direction: float) -> void:
	_drifting = true
	_drift_dir = signf(direction)
	_drift_charge = 0.0

	# Pulinho de entrada
	if drift_hop_velocity > 0.0:
		apply_central_impulse(global_transform.basis.y * mass * drift_hop_velocity)

	# Roda traseira com menos fricção para a moto deslizar
	if rear_wheel:
		rear_wheel.wheel_friction_slip = _rear_friction_base * drift_rear_friction

func _end_drift(give_boost: bool) -> void:
	if _drifting and give_boost and drift_turbo_enabled:
		match _drift_level():
			1:
				_boost_time_left = boost_time_1
			2:
				_boost_time_left = boost_time_2
			3:
				_boost_time_left = boost_time_3

	_drifting = false
	_drift_dir = 0.0
	_drift_charge = 0.0

	if rear_wheel:
		rear_wheel.wheel_friction_slip = _rear_friction_base

func _drift_level() -> int:
	if _drift_charge >= drift_level3_time:
		return 3
	if _drift_charge >= drift_level2_time:
		return 2
	if _drift_charge >= drift_level1_time:
		return 1
	return 0

# Trava a velocidade horizontal na máxima atual (a queda vertical não é afetada)
func _limit_speed() -> void:
	if not hard_speed_limit:
		return

	var limit = _effective_max_speed()
	var horizontal = Vector3(linear_velocity.x, 0.0, linear_velocity.z)
	if horizontal.length() > limit:
		horizontal = horizontal.normalized() * limit
		linear_velocity = Vector3(horizontal.x, linear_velocity.y, horizontal.z)

# Gira só o visual do garfo/roda da frente. Não altera steering nem a física.
func _update_front_visual(delta: float) -> void:
	if front_visual == null:
		return

	var speed = absf(-global_transform.basis.z.dot(linear_velocity))
	var speed_t = clampf(speed / maxf(visual_ref_speed, 0.1), 0.0, 1.0)
	var direction = -1.0 if visual_invert else 1.0
	var target = _last_turn_input * direction * deg_to_rad(visual_max_deg) * lerpf(1.0, visual_high_speed_factor, speed_t)
	_front_visual_angle = move_toward(_front_visual_angle, target, visual_steer_speed * delta)

	var angle = _front_visual_angle
	# Se o nó está dentro da RodaFrontal, ele já herda o ângulo real da física
	if front_wheel and front_wheel.is_ancestor_of(front_visual):
		angle -= steering

	var axis = visual_steer_axis.normalized()
	front_visual.transform = Transform3D(_front_visual_base.basis * Basis(axis, angle), _front_visual_base.origin)

# Inclina só o modelo visual nas curvas, com inércia (mola amortecida)
func _update_lean(delta: float) -> void:
	if model == null:
		return

	var target = 0.0
	if lean_enabled and is_mounted and not _in_air:
		var forward_speed = -global_transform.basis.z.dot(linear_velocity)
		var yaw_rate = angular_velocity.dot(global_transform.basis.y)
		target = atan(forward_speed * yaw_rate / 9.8) * lean_factor
		var max_lean = deg_to_rad(max_lean_deg)
		target = clampf(target, -max_lean, max_lean)

	# Mola amortecida: a moto tem inércia e não troca de lado de uma vez
	var lean_accel = lean_stiffness * (target - _lean_current) - lean_damping * _lean_velocity
	_lean_velocity += lean_accel * delta
	_lean_current += _lean_velocity * delta

	var roll_basis = Basis(Vector3(0, 0, 1), _lean_current)
	model.transform = Transform3D(roll_basis, Vector3.ZERO) * _model_base_transform

# ------------------------------------------------------------------
# HUD (velocímetro, velocidade máxima e drift)
# ------------------------------------------------------------------

func _create_hud() -> void:
	var layer = CanvasLayer.new()
	add_child(layer)

	_speed_label = Label.new()
	_speed_label.position = Vector2(30, 30)
	_speed_label.add_theme_font_size_override("font_size", 36)
	_speed_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_speed_label.add_theme_constant_override("outline_size", 8)
	_speed_label.visible = false
	layer.add_child(_speed_label)

	_drift_label = Label.new()
	_drift_label.position = Vector2(30, 140)
	_drift_label.add_theme_font_size_override("font_size", 40)
	_drift_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_drift_label.add_theme_constant_override("outline_size", 8)
	_drift_label.visible = false
	layer.add_child(_drift_label)

func _update_hud() -> void:
	if _speed_label == null or _drift_label == null:
		return

	_speed_label.visible = is_mounted
	_drift_label.visible = false

	if not is_mounted:
		return

	var speed_kmh = linear_velocity.length() * 3.6
	_speed_label.text = "%d km/h\nmáx: %d km/h  (↑ / ↓)" % [roundi(speed_kmh), roundi(_effective_max_speed() * 3.6)]

	if _boost_time_left > 0.0:
		_drift_label.visible = true
		_drift_label.text = "TURBO!"
		_drift_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	elif _drifting:
		_drift_label.visible = true
		var shown_level = _drift_level() if drift_turbo_enabled else 0
		match shown_level:
			0:
				_drift_label.text = "DRIFT"
				_drift_label.add_theme_color_override("font_color", Color.WHITE)
			1:
				_drift_label.text = "DRIFT ▲"
				_drift_label.add_theme_color_override("font_color", Color(0.3, 0.6, 1.0))
			2:
				_drift_label.text = "DRIFT ▲▲"
				_drift_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.15))
			3:
				_drift_label.text = "DRIFT ▲▲▲"
				_drift_label.add_theme_color_override("font_color", Color(0.75, 0.35, 1.0))

# ------------------------------------------------------------------
# Montar / desmontar (tecla F)
# ------------------------------------------------------------------

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
	engine_force = 0.0
	steering = 0.0
	_end_drift(false)
	_boost_time_left = 0.0
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

# Detecta o toque na tecla F (só dispara uma vez por aperto)
func _is_interact_just_pressed() -> bool:
	var pressed = Input.is_key_pressed(KEY_F)
	if pressed and not _interact_was_pressed:
		_interact_was_pressed = true
		return true
	if not pressed:
		_interact_was_pressed = false
	return false
