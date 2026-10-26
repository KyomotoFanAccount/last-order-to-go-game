extends VehicleBody3D
# Moto estilo GTA 5 em cima do VehicleBody3D, com drift estilo Mario Kart.
# Controles:
#   F = montar / desmontar
#   W = acelerar | S = frear / ré | A / D = virar
#   Espaço = empinar a roda da frente para cima (com W, ou sozinho se a moto já estiver em movimento)
#   Ctrl (segurando, em movimento) = empinar a traseira (stoppie: freia e levanta a bunda da moto)
#   C = pular
#   Corrimão: no ar, com a frente ou a traseira da moto apontando para o corrimão (zona da ponta ou do lado),
#             a moto cai suave até ele, vira de lado (estilo skate) e desliza até o fim (A/D escolhem o lado)
#   Mouse = câmera | ESC = soltar o mouse
#   Shift (segurando) + A/D em velocidade = drift (solte para ganhar turbo)
#   No ar: W/S = inclinar o nariz | Q/E = rolar de lado | A/D = girar no próprio eixo (estilo GTA)
#   Pouso de lado = a moto derrapa um pouco antes de recuperar a aderência
#   ↑ / ↓ = aumenta / diminui a velocidade máxima (teste)
# As teclas de pular e de stoppie podem ser trocadas no Inspetor.
# Pontuação: manobras (tempo no ar, giros, empinar, stoppie, drift, grind) formam um combo com
# multiplicador. O combo é guardado quando você fica um tempo sem fazer manobras
# e perdido se pousar muito torto.

@export_group("Força do Veículo")
@export var max_engine_force: float = 600.0
@export var max_speed: float = 70.0           # m/s (40 m/s = 144 km/h)
@export var brake_strength: float = 6.0       # força máxima do freio (sobe aos poucos)
@export var brake_ramp_time: float = 0.7      # segundos até o freio chegar na força máxima
@export var idle_brake: float = 0.4           # freio-motor ao soltar o acelerador
@export var allow_reverse: bool = true
@export var reverse_speed: float = 10.0       # m/s (36 km/h)
@export var reverse_force_mult: float = 1.0   # força do motor na ré (1 = igual à frente)
@export var reverse_accel: float = 6.0        # m/s²: empurrão extra direto para trás

@export_group("Direção")
@export var max_steer_deg: float = 45.0       # ângulo máximo da roda em baixa velocidade
@export var steer_speed: float = 3.0          # rad/s: rapidez com que o guidão vira
@export var steer_multiplier: float = 1.0     # multiplica o ângulo real da roda em todas as velocidades (1 = como está)
@export var steer_hard_limit_deg: float = 60.0 # trava de segurança: o ângulo real nunca passa disso
@export var lateral_accel_low: float = 5.5    # m/s² de força lateral em baixa velocidade (pouca inclinação)
@export var lateral_accel_high: float = 45.0  # m/s² na velocidade de referência (muita inclinação)
@export var handling_ref_speed: float = 40.0  # m/s: referência do grip (não muda com o max_speed)
@export var yaw_response: float = 22.0        # quão rápido a moto acompanha a curva
@export var lateral_grip: float = 10.0         # quanto maior, menos a moto escorrega de lado

@export_group("Inclinação nas Curvas (visual)")
@export var lean_enabled: bool = true
@export var lean_factor: float = 1.0
@export var max_lean_deg: float = 35.0
@export var lean_stiffness: float = 40.0      # rigidez da inclinação (maior = responde mais rápido)
@export var lean_damping: float = 10.0        # amortecimento (evita balançar)

@export_group("Pulo")
@export var jump_key: Key = KEY_C             # tecla do pulo (troque aqui se preferir outra)
@export var jump_velocity: float = 8.5        # m/s para cima (6 ≈ 1,8 m de altura; suba para pular mais alto)
@export var jump_cooldown: float = 0.4        # s de espera entre um pulo e outro
@export var jump_coyote_time: float = 0.12    # s depois de sair do chão em que ainda dá para pular

@export_group("Empinar (Wheelie Arcade)")
@export var wheelie_torque: float = 1500.0    # torque máximo para levantar a roda
@export var wheelie_gain: float = 400.0       # força para segurar a moto no ângulo
@export var wheelie_rise_speed: float = 2.0   # rad/s: velocidade com que a roda sobe
@export var wheelie_max_angle_deg: float = 55.0
@export var wheelie_min_speed: float = 4.0    # m/s (≈ 14 km/h): velocidade mínima para empinar só com Espaço (sem W)

@export_group("Empinar a Traseira (Stoppie)")
@export var stoppie_key: Key = KEY_CTRL          # tecla do stoppie (troque aqui se preferir outra)
@export var stoppie_torque: float = 2000.0       # torque máximo para levantar a traseira
@export var stoppie_gain: float = 400.0          # força para segurar a moto no ângulo
@export var stoppie_rise_speed: float = 2.0      # rad/s: velocidade com que a traseira sobe
@export var stoppie_max_angle_deg: float = 70.0  # inclinação máxima do nariz para baixo
@export var stoppie_min_speed: float = 6.0       # m/s (≈ 22 km/h): velocidade mínima para fazer stoppie
@export var stoppie_brake_fraction: float = 0.5  # fração da força de freio aplicada durante o stoppie

@export_group("Grind (corrimões)")
@export var grind_enabled: bool = true
@export var grind_needs_air: bool = true         # true = só engata se a moto estiver no ar
@export var grind_probe_length: float = 6.0       # m: alcance das linhas que saem da frente e de trás da moto
@export var grind_probe_tolerance: float = 0.3   # m: folga extra (além da metade da largura do corrimão) para a linha "tocar" nele
@export var grind_end_zone_angle_deg: float = 35.0 # graus: abertura do funil azul (zona das pontas do corrimão)
@export var grind_end_distance: float = 3.5      # m: zona AZUL: distância máxima do centro da moto até a ponta do corrimão
@export var grind_side_distance: float = 2.5     # m: zona LARANJA: distância máxima do centro da moto até o corrimão
@export var grind_must_approach: bool = true     # true = só engata se a moto estiver indo em direção ao corrimão (ou já em cima dele)
@export var grind_debug: bool = false            # true = escreve na aba Saída qual zona engatou (para ajustar)
@export var grind_grab_height: float = 8.0    # m: altura máxima da moto acima da linha do corrimão para engatar (quanto mais alto, mais tempo a queda leva)
@export var grind_max_rise_speed: float = 8.0    # m/s: se estiver subindo mais rápido que isso, ainda não engata (baixe para só engatar na descida)
@export var grind_max_pitch_deg: float = 55.0    # graus: inclinação máxima do nariz (X) para engatar (+ ou -). Mesmo valor do Rotation X no Inspetor
@export var grind_max_roll_deg: float = 45.0     # graus: inclinação máxima de lado (Z) para engatar (+ ou -). Mesmo valor do Rotation Z no Inspetor
@export var grind_height: float = 1.1            # m: altura do centro da moto acima da linha do corrimão (se flutuar ou afundar, ajuste aqui)
@export var grind_min_speed: float = 5.0         # m/s (≈ 18 km/h): velocidade mínima para engatar
@export var grind_min_time: float = 0.3         # s: duração mínima da entrada (quando a moto já está na altura do corrimão)
@export var grind_max_approach_time: float = 3.0 # s: tempo máximo de queda até o corrimão (mais alto que isso, não engata)
@export var grind_land_margin: float = 1.0       # m: o pouso previsto precisa ficar pelo menos isso longe das pontas do corrimão
@export var grind_exit_time: float = 0.25        # s: tempo da moto para girar de volta para a frente ao sair do corrimão
@export var grind_friction: float = 0.0          # m/s²: velocidade perdida por segundo durante o grind (0 = mantém a velocidade)
@export var grind_cooldown: float = 0.5          # s sem poder engatar de novo depois de sair
@export var grind_allow_jump_exit: bool = false  # true = dá para sair do corrimão pulando (C); false = só sai no fim
@export var grind_points_per_sec: float = 200.0  # pontos por segundo de grind (entra no combo)

@export_group("Drift")
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

@export_group("Controle no Ar")
@export var air_min_time: float = 0.15        # s no ar antes de liberar o controle (evita ativar em trepidação)
@export var air_pitch_speed: float = 4.5      # rad/s: W/S inclinam o nariz
@export var air_roll_speed: float = 5.5       # rad/s: Q/E rolam a moto de lado
@export var air_yaw_speed: float = 4.5        # rad/s: A/D giram a moto no próprio eixo (vertical)
@export var air_accel: float = 14.0           # rad/s²: rapidez para atingir a rotação desejada
@export var air_brake: float = 1.5            # rad/s²: quanto a rotação freia sozinha sem input (0 = gira para sempre)
@export var ground_level_speed: float = 8.0   # quão rápido a moto se endireita ao pousar
@export var ground_level_max: float = 6.0     # rad/s: limite dessa correção

@export_group("Pouso (derrapagem)")
@export var landing_slide_duration: float = 1.0       # s para a aderência voltar ao normal depois do pouso de lado
@export var landing_slide_grip_mult: float = 0.1      # grip lateral logo após o pouso (menor = desliza mais)
@export var landing_slide_friction_mult: float = 0.25 # fricção das duas rodas logo após o pouso (menor = desliza mais)
@export var landing_slide_min_sideways: float = 0.3   # quão de lado a moto precisa estar (0 a 1) para derrapar
@export var landing_slide_min_speed: float = 6.0      # m/s: velocidade mínima para derrapar no pouso

@export_group("Pontuação (manobras)")
@export var score_enabled: bool = true
@export var combo_timeout: float = 2.0            # s sem manobra até o combo ser guardado
@export var multiplier_per_trick: float = 0.5     # quanto o multiplicador sobe a cada manobra nova no combo
@export var max_multiplier: float = 8.0
@export var score_min_air_time: float = 0.5       # s no ar antes de começar a pontuar tempo de voo
@export var air_time_points_per_sec: float = 100.0
@export var flip_points: float = 500.0            # cada giro completo para frente/trás (frontflip/backflip)
@export var roll_points: float = 400.0            # cada giro completo de lado (barrel roll)
@export var spin_points: float = 300.0            # cada giro completo no próprio eixo (A/D no ar)
@export var rotation_threshold_deg: float = 330.0 # graus para contar uma volta completa (perdoa um pouco)
@export var wheelie_points_per_sec: float = 150.0
@export var wheelie_min_angle_deg: float = 15.0   # inclinação mínima para valer como empinar
@export var stoppie_points_per_sec: float = 150.0
@export var drift_points_per_sec: float = 100.0
@export var trick_min_hold: float = 0.5           # s fazendo empinar/stoppie/drift antes de começar a pontuar
@export var lose_combo_on_bad_landing: bool = true # true = pousar muito torto perde o combo
@export var bad_landing_up_dot: float = 0.5       # 1 = reto, 0 = de lado; abaixo disso é pouso ruim

@export_group("Colisão")
@export var wall_slide_friction: float = 0.05 # fricção do corpo (baixa = desliza na parede em vez de grudar)
@export var wall_push_accel: float = 3.0      # m/s²: empurrãozinho para longe da parede (0 = desligado)
@export var hit_min_impact: float = 5.0       # batidas mais fracas que isso não fazem tremer a câmera
@export var shake_per_impact: float = 0.004   # força do tremor da câmera por ponto de impacto
@export var shake_max: float = 0.18           # tremor máximo da câmera
@export var shake_decay: float = 0.6          # quão rápido o tremor some
@export var show_impact_debug: bool = false   # true = escreve o impacto no painel "Saída" (para ajustar)

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
var _front_friction_base: float = 10.5

var _front_visual_base: Transform3D = Transform3D.IDENTITY
var _front_visual_angle: float = 0.0
var _last_turn_input: float = 0.0

var _grounded: bool = false
var _air_time: float = 0.0
var _in_air: bool = false

# --- Pulo ---
var _jump_was_pressed: bool = false
var _jump_cooldown_left: float = 0.0

# --- Grind (corrimões) ---
var _grinding: bool = false
var _grind_rail: Node3D = null
var _grind_s: float = 0.0             # distância (m) já percorrida desde a ponta de trás do corrimão
var _grind_way: float = 1.0           # +1 = indo para a ponta da frente, -1 = para a de trás
var _grind_speed: float = 0.0
var _grind_slide_dir: Vector3 = Vector3.FORWARD  # direção do deslize ao longo do corrimão
var _grind_side: float = 1.0          # qual lado da moto fica virado para a frente (+1 ou -1)
var _grind_capturing: bool = false    # true durante a queda/giro até o corrimão
var _grind_cap_time: float = 0.0      # tempo já gasto na queda (s)
var _grind_cap_duration: float = 0.3  # tempo total da queda (s): o que a moto levaria para chegar ao corrimão
var _grind_cap_ballistic: bool = false # true = queda natural (gravidade); false = subida/ajuste suave
var _grind_cap_gravity: float = 9.8
var _grind_cap_p0: Vector3 = Vector3.ZERO     # posição ao engatar
var _grind_cap_v0: Vector3 = Vector3.ZERO     # velocidade ao engatar
var _grind_cap_land: Vector3 = Vector3.ZERO   # ponto de pouso no corrimão
var _grind_cap_v1h: Vector2 = Vector2.ZERO    # velocidade horizontal ao pousar (ao longo do corrimão)
var _grind_land_s: float = 0.0        # posição no corrimão (m) onde a moto pousa
var _grind_start_quat: Quaternion = Quaternion.IDENTITY
var _grind_exit_left: float = 0.0     # s restantes do giro de volta ao sair do corrimão
var _grind_exit_from: Quaternion = Quaternion.IDENTITY
var _grind_exit_to: Quaternion = Quaternion.IDENTITY
var _grind_cooldown_left: float = 0.0
var _grind_scoring: bool = false
var _gravity_scale_base: float = 1.0

# --- Derrapagem no pouso ---
var _landing_slide_time: float = 0.0
var _landing_grip_factor: float = 1.0

# --- Colisão (suave) ---
var _last_velocity: Vector3 = Vector3.ZERO
var _dv_history: Array[float] = []
var _wall_touching: bool = false
var _impact_cooldown_left: float = 0.0
var _shake: float = 0.0

# --- Pontuação ---
var total_score: float = 0.0          # pontos já guardados (esta é a pontuação do jogador)
var _combo_points: float = 0.0        # pontos do combo atual (ainda não guardados)
var _multiplier: float = 1.0
var _combo_active: bool = false
var _combo_timer: float = 0.0
var _rot_pitch: float = 0.0
var _rot_roll: float = 0.0
var _rot_yaw: float = 0.0
var _air_scoring: bool = false
var _wheelie_time: float = 0.0
var _wheelie_scoring: bool = false
var _stoppie_time: float = 0.0
var _stoppie_scoring: bool = false
var _drift_time: float = 0.0
var _drift_scoring: bool = false
var _trick_text: String = ""
var _trick_color: Color = Color.WHITE
var _trick_timer: float = 0.0

var _speed_label: Label
var _drift_label: Label
var _score_label: Label
var _combo_label: Label
var _trick_label: Label

func _ready() -> void:
	can_sleep = false
	_gravity_scale_base = gravity_scale

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
		_front_friction_base = front_wheel.wheel_friction_slip

	# Distância entre eixos, usada para calcular a curva
	if front_wheel and rear_wheel:
		_wheelbase = absf(front_wheel.position.z - rear_wheel.position.z)
		if _wheelbase < 0.2:
			_wheelbase = 1.4

	if model:
		_model_base_transform = model.transform

	if front_visual:
		_front_visual_base = front_visual.transform

	# Colisão suave: a moto "sente" paredes, desliza nelas e não atravessa em alta velocidade
	contact_monitor = true
	max_contacts_reported = 4
	continuous_cd = true
	var body_material := PhysicsMaterial.new()
	body_material.friction = wall_slide_friction
	body_material.bounce = 0.0
	physics_material_override = body_material

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
	_track_impacts(delta)

	if is_mounted:
		if _grinding:
			_process_grind(delta)
		else:
			_process_vehicle_inputs(delta)
			_air_control(delta)
			_try_start_grind(delta)
			_limit_speed()
		_check_dismount()
	else:
		engine_force = 0.0
		brake = 5.0
		steering = 0.0
		_brake_current = 0.0
		_last_turn_input = 0.0
		_check_mount()

	_update_grind_exit(delta)
	_update_wheel_friction(delta)
	_update_score(delta)
	if not _grinding:
		_stabilize_roll()
	_update_lean(delta)
	_update_front_visual(delta)
	_update_shake(delta)
	_update_hud()

	if is_mounted and camera_rig:
		camera_rig.global_position = global_position
		camera_rig.rotation.y = camera_yaw

	# Guarda a velocidade do fim deste quadro (usada para medir batidas no próximo)
	_last_velocity = linear_velocity

# ------------------------------------------------------------------
# Pulo
# ------------------------------------------------------------------

# Dá um impulso para cima (misturando a direção "para cima" do mundo com a da moto,
# para o pulo em rampa sair na direção da rampa)
func _do_jump() -> void:
	var direction = (global_transform.basis.y + Vector3.UP).normalized()

	# Se estava caindo, zera a queda para o pulo sempre ter a mesma força
	if linear_velocity.y < 0.0:
		linear_velocity = Vector3(linear_velocity.x, 0.0, linear_velocity.z)

	apply_central_impulse(direction * mass * jump_velocity)
	_jump_cooldown_left = jump_cooldown

# ------------------------------------------------------------------
# Grind em corrimões (estilo skate / Bomb Rush)
# Engata quando a moto está no ar, perto de um corrimão (nó do grupo "grind_rail"), e a linha
# que sai da frente/traseira da moto toca nele. Duas zonas:
#   AZUL (pontas do corrimão): vale a distância do centro da moto até a ponta.
#   LARANJA (lados): vale a distância do centro da moto até o corrimão.
# 1) APROXIMAÇÃO: sem controle, a moto cai naturalmente (gravidade normal) até o corrimão. O giro de lado
#    e o ajuste horizontal levam exatamente o tempo dessa queda: quanto mais alto, mais devagar ela se prepara.
# 2) DESLIZE: de lado (estilo skate), até o FIM do corrimão.
# 3) SAÍDA: na ponta a moto gira de volta para a frente e a física normal volta.
# ------------------------------------------------------------------

# Menor distância entre dois segmentos no plano horizontal (0 = se cruzam)
func _segment_distance_2d(a1: Vector2, a2: Vector2, b1: Vector2, b2: Vector2) -> float:
	if Geometry2D.segment_intersects_segment(a1, a2, b1, b2) != null:
		return 0.0
	var best = a1.distance_to(Geometry2D.get_closest_point_to_segment(a1, b1, b2))
	best = minf(best, a2.distance_to(Geometry2D.get_closest_point_to_segment(a2, b1, b2)))
	best = minf(best, b1.distance_to(Geometry2D.get_closest_point_to_segment(b1, a1, a2)))
	best = minf(best, b2.distance_to(Geometry2D.get_closest_point_to_segment(b2, a1, a2)))
	return best

# Procura um corrimão perto da moto e engata se as condições forem boas
func _try_start_grind(delta: float) -> void:
	_grind_cooldown_left = maxf(_grind_cooldown_left - delta, 0.0)
	if not grind_enabled or _grind_cooldown_left > 0.0 or _grind_exit_left > 0.0:
		return
	if grind_needs_air and not _in_air:
		return
	if linear_velocity.y > grind_max_rise_speed:
		return

	# Só engata com a moto numa inclinação aceitável:
	# X = nariz para cima/baixo, Z = inclinada de lado (a direção para onde ela olha, Y, não importa)
	var tilt = global_transform.basis.orthonormalized().get_euler()
	var pitch_deg = rad_to_deg(tilt.x)
	var roll_deg = rad_to_deg(tilt.z)
	if absf(pitch_deg) > grind_max_pitch_deg or absf(roll_deg) > grind_max_roll_deg:
		return

	var velocity2 = Vector2(linear_velocity.x, linear_velocity.z)
	var speed_h = velocity2.length()
	if speed_h < grind_min_speed:
		return

	# Linha reta que sai da frente e de trás da moto (no plano horizontal)
	var forward3 = -global_transform.basis.z
	var forward2 = Vector2(forward3.x, forward3.z)
	if forward2.length() < 0.2:
		return   # moto muito empinada/de nariz para baixo: sem direção horizontal confiável
	forward2 = forward2.normalized()
	var position2 = Vector2(global_position.x, global_position.z)
	var probe_rear = position2 - forward2 * grind_probe_length
	var probe_front = position2 + forward2 * grind_probe_length
	var end_zone_slope = tan(deg_to_rad(clampf(grind_end_zone_angle_deg, 1.0, 85.0)))

	for rail in get_tree().get_nodes_in_group("grind_rail"):
		if not rail.has_method("get_start"):
			continue

		var rail_start: Vector3 = rail.get_start()
		var rail_end: Vector3 = rail.get_end()
		var start2 = Vector2(rail_start.x, rail_start.z)
		var end2 = Vector2(rail_end.x, rail_end.z)
		var rail_len2 = start2.distance_to(end2)
		if rail_len2 < 0.5:
			continue   # corrimão praticamente vertical
		var axis2 = (end2 - start2) / rail_len2

		var half_width = 0.25
		if rail.has_method("get_half_width"):
			half_width = rail.get_half_width()

		# Altura da moto em relação ao corrimão (por cima, e não muito alto)
		var closest = Geometry3D.get_closest_point_to_segment(global_position, rail_start, rail_end)
		var height = global_position.y - closest.y
		if height < -0.2 or height > grind_grab_height:
			continue

		# 1) A linha da frente ou de trás da moto precisa tocar o corrimão
		var touch = _segment_distance_2d(probe_rear, probe_front, start2, end2)
		if touch > half_width + grind_probe_tolerance:
			continue

		# 2) A moto precisa estar indo em direção ao corrimão (ou já em cima dele)
		var near_point = Geometry2D.get_closest_point_to_segment(position2, start2, end2)
		var to_rail = near_point - position2
		if grind_must_approach and to_rail.length() > 0.5:
			if velocity2.dot(to_rail.normalized()) <= 0.0:
				continue

		# 3) Em qual zona a moto está?
		var relative = position2 - (start2 + end2) * 0.5
		var along = relative.dot(axis2)
		var lateral = absf(relative.dot(Vector2(-axis2.y, axis2.x)))
		var beyond = absf(along) - rail_len2 * 0.5
		var zone = ""
		var zone_distance = 0.0
		if beyond > 0.0 and lateral <= half_width + beyond * end_zone_slope:
			# Zona AZUL (pontas): só importa a distância do centro da moto até a ponta
			var near_end = end2 if along > 0.0 else start2
			zone_distance = position2.distance_to(near_end)
			if zone_distance > grind_end_distance:
				continue
			zone = "AZUL (ponta)"
		else:
			# Zona LARANJA (lados): distância do centro da moto até o corrimão
			zone_distance = to_rail.length()
			if zone_distance > grind_side_distance:
				continue
			zone = "LARANJA (lado)"

		# Sentido do deslize: o do movimento; se a moto vem de lado, vai para a ponta mais distante
		var along_speed = velocity2.dot(axis2)
		var way = 1.0
		if absf(along_speed) >= speed_h * 0.3:
			way = signf(along_speed)
		elif along != 0.0:
			way = -signf(along)

		var direction = (rail_end - rail_start).normalized()
		if _start_grind(rail, rail_start, closest, direction, way):
			if grind_debug:
				print("GRIND: zona ", zone, " | distancia=", snappedf(zone_distance, 0.1), " | toque=", snappedf(touch, 0.01), " | altura=", snappedf(height, 0.1), " | queda=", snappedf(_grind_cap_duration, 0.01), "s", " | X=", roundi(pitch_deg), " Z=", roundi(roll_deg))
			return

# Tenta engatar. Devolve false (sem mudar nada) se o pouso previsto não cair dentro do corrimão.
func _start_grind(rail: Node3D, rail_start: Vector3, closest: Vector3, direction: Vector3, way: float) -> bool:
	var rail_end: Vector3 = rail.get_end()
	var rail_length = rail_start.distance_to(rail_end)
	var axis2 = Vector2(direction.x, direction.z)
	if axis2.length() < 0.01:
		return false
	axis2 = axis2.normalized()

	var slide_dir = direction * way
	var entry_velocity = linear_velocity
	var horizontal_speed = maxf(Vector2(entry_velocity.x, entry_velocity.z).length(), grind_min_speed)

	# Escolhe qual lado da moto fica virado para a frente do deslize.
	# A / D = escolhem o lado | sem tecla = o lado que pede o giro mais curto.
	var perp = slide_dir.cross(Vector3.UP)
	var turn = 0.0
	if Input.is_key_pressed(KEY_A):
		turn += 1.0
	if Input.is_key_pressed(KEY_D):
		turn -= 1.0
	var side = 1.0
	if turn != 0.0:
		var wanted = -global_transform.basis.x * turn
		side = 1.0 if perp.dot(wanted) >= 0.0 else -1.0
	else:
		var current_forward = -global_transform.basis.z
		side = 1.0 if perp.dot(current_forward) >= 0.0 else -1.0
	_grind_slide_dir = slide_dir
	_grind_side = side

	var target_basis = _grind_target_basis()

	# Quanto tempo a moto levaria para chegar à altura do corrimão? (queda natural)
	var gravity = maxf(float(ProjectSettings.get_setting("physics/3d/default_gravity")) * _gravity_scale_base, 0.1)
	var y_start = global_position.y
	var y_land = closest.y + target_basis.y.y * grind_height
	var vy = entry_velocity.y
	var ballistic = false
	var duration = maxf(grind_min_time, 0.1)
	if y_start > y_land + 0.05:
		var fall_time = (vy + sqrt(vy * vy + 2.0 * gravity * (y_start - y_land))) / gravity
		if fall_time > grind_max_approach_time:
			return false   # alto demais: ainda não dá para engatar
		if fall_time >= grind_min_time:
			ballistic = true
			duration = fall_time

	# Onde ela vai pousar no corrimão: anda na horizontal à mesma velocidade durante a queda
	var from_start = Vector2(global_position.x - rail_start.x, global_position.z - rail_start.z)
	var lateral = absf(from_start.dot(Vector2(-axis2.y, axis2.x)))
	var along_now = (global_position - rail_start).dot(direction)
	var margin = minf(grind_land_margin, rail_length * 0.25)
	var travel = horizontal_speed * duration
	var along_travel = maxf(sqrt(maxf(travel * travel - lateral * lateral, 0.0)), 0.5)
	var land_s = along_now + way * along_travel

	if land_s < margin or land_s > rail_length - margin:
		if ballistic:
			return false   # a queda natural passaria do corrimão: espera ficar mais baixo
		# Entrada rápida e sem queda: encurta o tempo para ainda caber no corrimão
		var room = (rail_length - margin - along_now) if way > 0.0 else (along_now - margin)
		if room < 0.3:
			return false
		duration = sqrt(room * room + lateral * lateral) / horizontal_speed
		if duration < 0.12:
			return false
		land_s = along_now + way * room
	land_s = clampf(land_s, margin, maxf(rail_length - margin, margin))

	# Tudo certo: engata
	_grinding = true
	_grind_rail = rail
	_grind_way = way
	_grind_speed = horizontal_speed   # a velocidade horizontal se mantém no corrimão

	_grind_land_s = land_s
	_grind_cap_p0 = global_position
	_grind_cap_v0 = entry_velocity
	_grind_cap_land = rail_start + direction * land_s + target_basis.y * grind_height
	var slide_flat = Vector2(slide_dir.x, slide_dir.z).normalized()
	_grind_cap_v1h = slide_flat * horizontal_speed
	_grind_cap_duration = duration
	_grind_cap_time = 0.0
	_grind_cap_ballistic = ballistic
	_grind_cap_gravity = gravity
	_grind_start_quat = Quaternion(global_transform.basis.orthonormalized())
	_grind_capturing = true

	_end_drift(false)
	_boost_time_left = 0.0
	gravity_scale = 0.0
	engine_force = 0.0
	brake = 0.0
	_brake_current = 0.0

	# Encerra a contagem de voo e dá fôlego ao combo
	_rot_pitch = 0.0
	_rot_roll = 0.0
	_rot_yaw = 0.0
	_air_scoring = false
	if _combo_active:
		_combo_timer = combo_timeout
	return true

# Orientação da moto no corrimão: de lado (perpendicular à direção do deslize), estilo skate
func _grind_target_basis() -> Basis:
	var perp = _grind_slide_dir.cross(Vector3.UP).normalized() * _grind_side
	return Basis.looking_at(perp, Vector3.UP)

# Roda a cada quadro enquanto a moto está no corrimão
func _process_grind(delta: float) -> void:
	if not is_instance_valid(_grind_rail):
		_end_grind(false)
		return

	var rail_start: Vector3 = _grind_rail.get_start()
	var rail_end: Vector3 = _grind_rail.get_end()
	var rail_length = rail_start.distance_to(rail_end)
	var direction = (rail_end - rail_start).normalized()
	_grind_slide_dir = direction * _grind_way

	# Velocidade do deslize (só perde se grind_friction for maior que zero)
	_grind_speed = maxf(_grind_speed - grind_friction * delta, 1.0)

	var old_position = global_position
	var target_basis = _grind_target_basis()
	var new_basis = target_basis
	var new_position = old_position
	var finished = false

	if _grind_capturing:
		# Queda natural até o corrimão. O giro e o ajuste horizontal levam o MESMO tempo da queda.
		_grind_cap_time += delta
		var total = maxf(_grind_cap_duration, 0.05)
		var t = minf(_grind_cap_time, total)
		var u = t / total
		var u2 = u * u
		var u3 = u2 * u

		# Horizontal: curva (Hermite) que sai com a velocidade que a moto já tinha
		# e chega com a velocidade do deslize, sem tranco nas duas pontas
		var p0h = Vector2(_grind_cap_p0.x, _grind_cap_p0.z)
		var v0h = Vector2(_grind_cap_v0.x, _grind_cap_v0.z)
		var p1h = Vector2(_grind_cap_land.x, _grind_cap_land.z)
		var position_h = p0h * (2.0 * u3 - 3.0 * u2 + 1.0) + v0h * (total * (u3 - 2.0 * u2 + u)) + p1h * (-2.0 * u3 + 3.0 * u2) + _grind_cap_v1h * (total * (u3 - u2))

		# Vertical: queda com a gravidade normal (ou um ajuste suave se a moto já está na altura)
		var y = _grind_cap_land.y
		if u < 1.0:
			if _grind_cap_ballistic:
				y = _grind_cap_p0.y + _grind_cap_v0.y * t - 0.5 * _grind_cap_gravity * t * t
			else:
				y = lerpf(_grind_cap_p0.y, _grind_cap_land.y, u * u * (3.0 - 2.0 * u))
		new_position = Vector3(position_h.x, y, position_h.y)

		# Giro de lado: começa e termina suave, durante toda a queda
		var rotation_weight = u * u * (3.0 - 2.0 * u)
		new_basis = Basis(_grind_start_quat.slerp(Quaternion(target_basis), rotation_weight))

		if _grind_cap_time >= total:
			_grind_capturing = false
			_grind_s = _grind_land_s
	else:
		# Deslize ao longo do corrimão
		_grind_s += _grind_way * _grind_speed * delta
		finished = _grind_s <= 0.0 or _grind_s >= rail_length
		_grind_s = clampf(_grind_s, 0.0, rail_length)
		new_position = rail_start + direction * _grind_s + target_basis.y * grind_height

	global_transform = Transform3D(new_basis, new_position)

	if _grind_capturing:
		linear_velocity = (new_position - old_position) / maxf(delta, 0.0001)
	else:
		linear_velocity = _grind_slide_dir * _grind_speed
	angular_velocity = Vector3.ZERO
	engine_force = 0.0
	brake = 0.0
	steering = 0.0
	_last_turn_input = 0.0

	# Pulo (C) = sai do corrimão pulando (só se grind_allow_jump_exit estiver ligado)
	var jump_now = Input.is_key_pressed(jump_key)
	if grind_allow_jump_exit and jump_now and not _jump_was_pressed:
		_jump_was_pressed = true
		_end_grind(true)
		return
	_jump_was_pressed = jump_now

	if finished:
		_end_grind(false)

# Sai do corrimão: devolve a física normal e começa a girar a moto de volta para a frente
func _end_grind(with_jump: bool) -> void:
	if not _grinding:
		return

	_grinding = false
	_grind_capturing = false
	_grind_rail = null
	_grind_cooldown_left = grind_cooldown
	gravity_scale = _gravity_scale_base

	var flat = Vector3(_grind_slide_dir.x, 0.0, _grind_slide_dir.z)
	if flat.length() < 0.01:
		flat = -global_transform.basis.z
	flat = flat.normalized()

	linear_velocity = _grind_slide_dir * _grind_speed
	angular_velocity = Vector3.ZERO
	_last_velocity = linear_velocity

	# Giro de volta para a direção do movimento (controle do ar fica travado nesse tempo)
	_grind_exit_left = grind_exit_time
	_grind_exit_from = Quaternion(global_transform.basis.orthonormalized())
	_grind_exit_to = Quaternion(Basis.looking_at(flat, Vector3.UP))

	if with_jump:
		_do_jump()

# Gira a moto suavemente de volta para a frente depois de sair do corrimão
func _update_grind_exit(delta: float) -> void:
	if _grinding or _grind_exit_left <= 0.0:
		return

	_grind_exit_left = maxf(_grind_exit_left - delta, 0.0)
	var k = 1.0 - _grind_exit_left / maxf(grind_exit_time, 0.05)
	var weight = k * k * (3.0 - 2.0 * k)
	var new_basis = Basis(_grind_exit_from.slerp(_grind_exit_to, weight))
	global_transform = Transform3D(new_basis, global_position)
	angular_velocity = Vector3.ZERO

# ------------------------------------------------------------------
# Pontuação de manobras (estilo Tony Hawk / Bomb Rush)
# - Cada manobra soma pontos ao COMBO.
# - Cada manobra nova no combo aumenta o multiplicador.
# - Ficando combo_timeout segundos sem manobras, o combo é GUARDADO
#   (pontos x multiplicador somam em total_score).
# - Pousar muito torto PERDE o combo.
# ------------------------------------------------------------------

func _update_score(delta: float) -> void:
	_trick_timer = maxf(_trick_timer - delta, 0.0)

	if not score_enabled or not is_mounted:
		return

	var busy = false   # true enquanto alguma manobra está acontecendo

	# --- Grind ---
	if _grinding:
		busy = true
		if not _grind_scoring:
			_grind_scoring = true
			_start_trick("GRIND")
		_add_points(grind_points_per_sec * delta)
	else:
		_grind_scoring = false

	# --- Tempo no ar + giros ---
	if _in_air:
		busy = true
		_track_air_rotations(delta)
		if _air_time >= score_min_air_time:
			if not _air_scoring:
				_air_scoring = true
				_start_trick("TEMPO NO AR")
			_add_points(air_time_points_per_sec * delta)

	# --- Empinar (roda da frente para cima) e stoppie (traseira para cima) ---
	var front_contact = front_wheel != null and front_wheel.is_in_contact()
	var rear_contact = rear_wheel != null and rear_wheel.is_in_contact()
	var nose_y = -global_transform.basis.z.y
	var angle_min_sin = sin(deg_to_rad(wheelie_min_angle_deg))

	if rear_contact and not front_contact and nose_y > angle_min_sin:
		_wheelie_time += delta
		if _wheelie_time >= trick_min_hold:
			busy = true
			if not _wheelie_scoring:
				_wheelie_scoring = true
				_start_trick("EMPINANDO")
			_add_points(wheelie_points_per_sec * delta)
	else:
		_wheelie_time = 0.0
		_wheelie_scoring = false

	if front_contact and not rear_contact and nose_y < -angle_min_sin:
		_stoppie_time += delta
		if _stoppie_time >= trick_min_hold:
			busy = true
			if not _stoppie_scoring:
				_stoppie_scoring = true
				_start_trick("STOPPIE")
			_add_points(stoppie_points_per_sec * delta)
	else:
		_stoppie_time = 0.0
		_stoppie_scoring = false

	# --- Drift ---
	if _drifting and _grounded:
		_drift_time += delta
		if _drift_time >= trick_min_hold:
			busy = true
			if not _drift_scoring:
				_drift_scoring = true
				_start_trick("DRIFT")
			_add_points(drift_points_per_sec * delta)
	else:
		_drift_time = 0.0
		_drift_scoring = false

	# --- Relógio do combo ---
	if _combo_active:
		if busy:
			_combo_timer = combo_timeout
		else:
			_combo_timer -= delta
			if _combo_timer <= 0.0:
				_bank_combo()

# Soma as voltas completas da moto no ar (frontflip, backflip, barrel roll, spin)
func _track_air_rotations(delta: float) -> void:
	var b = global_transform.basis
	_rot_pitch += angular_velocity.dot(b.x) * delta
	_rot_roll += angular_velocity.dot(-b.z) * delta
	_rot_yaw += angular_velocity.dot(b.y) * delta

	var threshold = deg_to_rad(rotation_threshold_deg)

	if absf(_rot_pitch) >= threshold:
		var flip_name = "BACKFLIP" if _rot_pitch > 0.0 else "FRONTFLIP"
		_rot_pitch -= signf(_rot_pitch) * threshold
		_trick_done(flip_points, flip_name)

	if absf(_rot_roll) >= threshold:
		_rot_roll -= signf(_rot_roll) * threshold
		_trick_done(roll_points, "BARREL ROLL")

	if absf(_rot_yaw) >= threshold:
		_rot_yaw -= signf(_rot_yaw) * threshold
		_trick_done(spin_points, "SPIN")

# Manobra instantânea (uma volta completa): sobe o multiplicador e soma os pontos
func _trick_done(points: float, trick_name: String) -> void:
	_start_trick(trick_name)
	_add_points(points)

# Chamada no começo de cada manobra nova. O multiplicador só sobe se o combo já existe.
func _start_trick(trick_name: String) -> void:
	if _combo_active:
		_multiplier = minf(_multiplier + multiplier_per_trick, max_multiplier)
	_show_trick(trick_name, Color(1.0, 0.9, 0.3))

func _add_points(points: float) -> void:
	_combo_points += points
	if not _combo_active:
		_combo_active = true
		_combo_timer = combo_timeout

# Guarda o combo: pontos x multiplicador vão para a pontuação total
func _bank_combo() -> void:
	if not _combo_active:
		return
	var gained = roundi(_combo_points * _multiplier)
	total_score += gained
	_show_trick("+%d" % gained, Color(0.4, 1.0, 0.5))
	_reset_combo()

# Perde o combo (pouso ruim)
func _bust_combo() -> void:
	if not _combo_active:
		return
	_show_trick("COMBO PERDIDO", Color(1.0, 0.35, 0.3))
	_reset_combo()

func _reset_combo() -> void:
	_combo_points = 0.0
	_multiplier = 1.0
	_combo_active = false
	_combo_timer = 0.0

func _show_trick(text: String, color: Color) -> void:
	_trick_text = text
	_trick_color = color
	_trick_timer = 1.5

# Decolou: zera a contagem de voltas e o "pontuando tempo no ar"
func _score_on_takeoff() -> void:
	_rot_pitch = 0.0
	_rot_roll = 0.0
	_rot_yaw = 0.0
	_air_scoring = false

# Pousou: confere se foi um pouso bom
func _score_on_landed() -> void:
	_air_scoring = false
	_rot_pitch = 0.0
	_rot_roll = 0.0
	_rot_yaw = 0.0

	if not score_enabled or not is_mounted:
		return

	var upright = global_transform.basis.y.dot(Vector3.UP)
	if lose_combo_on_bad_landing and upright < bad_landing_up_dot:
		_bust_combo()
	elif _combo_active:
		_combo_timer = combo_timeout   # dá tempo para emendar empinar/drift depois do pouso

# ------------------------------------------------------------------
# Derrapagem no pouso: se a moto pousa de lado, ela desliza um pouco e
# a aderência volta aos poucos (em vez de parar de uma vez).
# ------------------------------------------------------------------

# Chamado uma vez no instante em que a moto toca o chão depois de ficar no ar
func _on_landed() -> void:
	_damage_delivery_integrity_on_landing()

	var horizontal = Vector3(linear_velocity.x, 0.0, linear_velocity.z)
	var speed = horizontal.length()
	if speed < landing_slide_min_speed:
		return

	# Quanto da velocidade é "de lado" em relação à direção da moto (0 = reto, 1 = totalmente de lado)
	var sideways = absf(global_transform.basis.x.dot(horizontal)) / speed
	if sideways >= landing_slide_min_sideways:
		_landing_slide_time = landing_slide_duration

# Dano à comida: avalia apenas a inclinação no instante do pouso.
# A velocidade foi intencionalmente retirada como requisito para não bloquear
# pousos tortos que acontecem em baixa velocidade.
func _damage_delivery_integrity_on_landing() -> void:
	if not DeliveryManager.is_carrying():
		return

	var bike_up := global_transform.basis.y.normalized()
	var upright_dot := clampf(bike_up.dot(Vector3.UP), -1.0, 1.0)
	var angle := rad_to_deg(acos(upright_dot))

	print("Pouso detectado: ângulo %.1f graus" % angle)

	# Pousos quase retos não causam dano.
	if angle <= 25.0:
		return

	var damage: float

	if angle < 45.0:
		# Inclinação leve: dano pequeno.
		var amount := (angle - 25.0) / 20.0
		damage = lerpf(1.0, 5.0, clampf(amount, 0.0, 1.0))
	elif angle < 75.0:
		# Inclinação intermediária: dano moderado.
		var amount := (angle - 45.0) / 30.0
		damage = lerpf(5.0, 15.0, clampf(amount, 0.0, 1.0))
	else:
		# Pouso muito torto ou de cabeça para baixo: dano alto.
		var amount := (angle - 75.0) / 105.0
		damage = lerpf(15.0, 25.0, clampf(amount, 0.0, 1.0))

	print("Dano de integridade aplicado: %.1f%%" % damage)
	DeliveryManager.damage_integrity(damage, "Pouso torto")
# Controla a fricção das rodas (drift + derrapagem do pouso) e o grip lateral
func _update_wheel_friction(delta: float) -> void:
	_landing_slide_time = maxf(_landing_slide_time - delta, 0.0)
	var slide_t = clampf(_landing_slide_time / maxf(landing_slide_duration, 0.05), 0.0, 1.0)
	_landing_grip_factor = lerpf(1.0, landing_slide_grip_mult, slide_t)
	var friction_factor = lerpf(1.0, landing_slide_friction_mult, slide_t)

	if rear_wheel:
		var rear = _rear_friction_base
		if _drifting:
			rear *= drift_rear_friction
		rear_wheel.wheel_friction_slip = rear * friction_factor
	if front_wheel:
		front_wheel.wheel_friction_slip = _front_friction_base * friction_factor

# ------------------------------------------------------------------
# Colisão suave (estilo Burnout / GTA): você nunca perde o controle.
# A parede só desliza, empurra a moto para longe e balança a câmera.
# ------------------------------------------------------------------

# O Godot chama esta função a cada passo da física. Aqui descobrimos se o corpo da
# moto encosta em algo que NÃO é chão (parede, carro...) e damos um empurrãozinho
# para longe, para a moto não ficar grudada.
func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	for i in state.get_contact_count():
		var normal = state.get_contact_local_normal(i)
		if absf(normal.y) >= 0.7:
			continue   # superfície deitada = chão, ignora

		_wall_touching = true

		if is_mounted and wall_push_accel > 0.0:
			# Escolhe o lado da normal que aponta da parede para a moto
			var contact_pos = state.get_contact_local_position(i)
			var away = normal
			if away.dot(state.transform.origin - contact_pos) < 0.0:
				away = -away
			away.y = 0.0
			if away.length() > 0.01:
				state.apply_central_force(away.normalized() * mass * wall_push_accel)

# Mede a força da batida pela velocidade horizontal perdida de repente.
# Serve só para o tremor da câmera (não tira o controle de você).
func _track_impacts(delta: float) -> void:
	_impact_cooldown_left = maxf(_impact_cooldown_left - delta, 0.0)

	var lost_x = _last_velocity.x - linear_velocity.x
	var lost_z = _last_velocity.z - linear_velocity.z
	_dv_history.append(Vector2(lost_x, lost_z).length())
	if _dv_history.size() > 6:
		_dv_history.pop_front()

	if _wall_touching and is_mounted and _impact_cooldown_left <= 0.0:
		var impact: float = _dv_history.max()
		_dv_history.clear()
		if impact >= hit_min_impact:
			_impact_cooldown_left = 0.3
			_shake = minf(maxf(_shake, impact * shake_per_impact), shake_max)
			if show_impact_debug:
				print("Impacto: ", snappedf(impact, 0.1))

	_wall_touching = false

# Tremor da câmera depois de uma batida
func _update_shake(delta: float) -> void:
	if camera == null:
		return

	if _shake > 0.001:
		camera.h_offset = randf_range(-1.0, 1.0) * _shake
		camera.v_offset = randf_range(-1.0, 1.0) * _shake
		_shake = maxf(_shake - shake_decay * delta * (shake_max / 0.18), 0.0)
	else:
		_shake = 0.0
		camera.h_offset = 0.0
		camera.v_offset = 0.0

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

	# --- Pulo (uma vez por aperto) ---
	_jump_cooldown_left = maxf(_jump_cooldown_left - delta, 0.0)
	var jump_pressed = Input.is_key_pressed(jump_key)
	if jump_pressed and not _jump_was_pressed and _jump_cooldown_left <= 0.0:
		if grounded or _air_time < jump_coyote_time:
			_do_jump()
	_jump_was_pressed = jump_pressed

	var boosting = _boost_time_left > 0.0
	if boosting:
		_boost_time_left = maxf(_boost_time_left - delta, 0.0)

	# Stoppie ativo: tecla segurada, roda da frente no chão e moto em movimento
	var stoppie_active = Input.is_key_pressed(stoppie_key) and front_contact and forward_speed > stoppie_min_speed

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

	# Stoppie: corta o motor e freia (é o freio que "levanta a bunda" da moto)
	if stoppie_active:
		engine_force = 0.0
		brake_target = maxf(brake_target, brake_strength * stoppie_brake_fraction)

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

		# Grip lateral: evita escorregar de lado (menor durante o drift e logo após pouso de lado)
		var grip = lateral_grip * _landing_grip_factor
		if _drifting:
			grip *= drift_grip_mult
		var lateral_speed = global_transform.basis.x.dot(linear_velocity)
		apply_central_force(-global_transform.basis.x * lateral_speed * mass * grip)

	# --- Empinar (Espaço) ---
	# Com W: empina sempre (até parado).
	# Sem W: só empina se a moto já estiver em movimento (inércia), acima de wheelie_min_speed.
	# Só aplica um torque de inclinação (sem força linear), então não muda a
	# velocidade da moto e não depende dela.
	var wheelie_throttle_ok = w_pressed or forward_speed > wheelie_min_speed
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

	# --- Stoppie (empinar a traseira) ---
	# Igual ao empinar, mas ao contrário: empurra o nariz PARA BAIXO até o ângulo máximo
	# e segura lá, com a roda da frente no chão.
	if stoppie_active:
		var upright_ok = global_transform.basis.y.dot(Vector3.UP) > 0.4

		if upright_ok:
			var forward_vec = -global_transform.basis.z
			var pitch_now = asin(clampf(forward_vec.y, -1.0, 1.0))
			var target_down = -deg_to_rad(maxf(stoppie_max_angle_deg, 1.0))
			var pitch_speed = angular_velocity.dot(global_transform.basis.x)

			var wanted_rate = clampf((target_down - pitch_now) * 4.0, -stoppie_rise_speed, stoppie_rise_speed)
			var stoppie_torque_now = clampf((wanted_rate - pitch_speed) * stoppie_gain, -stoppie_torque, stoppie_torque)
			apply_torque(global_transform.basis.x * stoppie_torque_now)

# ------------------------------------------------------------------
# Controle no ar (estilo GTA)
# ------------------------------------------------------------------

func _update_air_state(delta: float) -> void:
	# Durante o grind a moto conta como "no chão" (sem pontos de tempo no ar)
	if _grinding:
		_grounded = true
		_air_time = 0.0
		_in_air = false
		return

	var was_in_air = _in_air

	var front_contact = front_wheel != null and front_wheel.is_in_contact()
	var rear_contact = rear_wheel != null and rear_wheel.is_in_contact()
	_grounded = front_contact or rear_contact
	if _grounded:
		_air_time = 0.0
	else:
		_air_time += delta
	_in_air = _air_time >= air_min_time

	# Acabou de decolar
	if not was_in_air and _in_air:
		_score_on_takeoff()

	# Acabou de pousar
	if was_in_air and not _in_air and _grounded:
		_score_on_landed()
		_on_landed()

# W/S = inclina o nariz (pitch), Q/E = rola de lado (roll), A/D = gira no próprio eixo (yaw).
# Controla a velocidade angular direto, então a resposta é firme e previsível.
func _air_control(delta: float) -> void:
	if not _in_air or _grind_exit_left > 0.0:
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

	# (A fricção da roda traseira é ajustada em _update_wheel_friction)

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
	if lean_enabled and is_mounted and not _in_air and not _grinding:
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
# HUD (velocímetro, drift e pontuação)
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

	# Pontuação: canto superior direito
	_score_label = _make_right_label(layer, 30.0, 40, Color(1.0, 1.0, 1.0))
	_combo_label = _make_right_label(layer, 90.0, 44, Color(1.0, 0.85, 0.25))
	_trick_label = _make_right_label(layer, 215.0, 36, Color(1.0, 0.9, 0.3))

# Cria um texto alinhado à direita no topo da tela
func _make_right_label(parent: Node, top: float, font_size: int, color: Color) -> Label:
	var label = Label.new()
	label.anchor_left = 1.0
	label.anchor_right = 1.0
	label.offset_left = -600.0
	label.offset_right = -30.0
	label.offset_top = top
	label.offset_bottom = top + font_size * 2.5
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)
	label.visible = false
	parent.add_child(label)
	return label

func _update_hud() -> void:
	if _speed_label == null or _drift_label == null:
		return
	if _score_label == null or _combo_label == null or _trick_label == null:
		return

	_speed_label.visible = is_mounted
	_drift_label.visible = false
	_score_label.visible = false
	_combo_label.visible = false
	_trick_label.visible = false

	if not is_mounted:
		return

	var speed_kmh = Vector2(linear_velocity.x, linear_velocity.z).length() * 3.6   # velocidade horizontal (não conta a queda/subida)
	_speed_label.text = "%d km/h\nmáx: %d km/h  (↑ / ↓)" % [roundi(speed_kmh), roundi(_effective_max_speed() * 3.6)]

	if _grinding:
		_drift_label.visible = true
		_drift_label.text = "GRIND"
		_drift_label.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	elif _boost_time_left > 0.0:
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

	if not score_enabled:
		return

	# Pontuação total
	_score_label.visible = true
	_score_label.text = "PONTOS  %d" % roundi(total_score)

	# Combo em andamento (pontos x multiplicador = quanto vai ser guardado)
	if _combo_active:
		_combo_label.visible = true
		_combo_label.text = "COMBO  x%.1f\n%d" % [_multiplier, roundi(_combo_points * _multiplier)]

	# Nome da última manobra / aviso
	if _trick_timer > 0.0:
		_trick_label.visible = true
		_trick_label.text = _trick_text
		_trick_label.add_theme_color_override("font_color", _trick_color)

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
	_shake = 0.0
	_landing_slide_time = 0.0
	_end_grind(false)
	_bank_combo()   # desmontar guarda o combo em andamento
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
