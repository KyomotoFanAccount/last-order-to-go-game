extends Node
# Integridade da comida (versão 2).
#
# Este nó deve ser filho direto do VehicleBody3D da Motorcycle:
# Motorcycle (VehicleBody3D)
# ├── RodaFrontal
# ├── RodaTraseira
# └── IntegrityDamage   <- este script
#
# O QUE TIRA INTEGRIDADE (só depois de coletar o pedido):
#   1) POUSO TORTO: ao voltar ao chão depois de um voo, quanto mais torta a moto, mais perde.
#   2) POUSO FORTE: queda muito alta, mesmo com a moto reta.
#   3) TOMBO: moto caída de lado ou de cabeça para baixo (perde de uma vez e continua
#      perdendo um pouco enquanto ficar caída).
#   4) BATIDA: bater forte numa parede ou obstáculo.
#
# O QUE NÃO TIRA: giros, flips, empinar, stoppie, drift, grind e tempo no ar.
# Fazer manobra é livre; só errar o pouso ou cair custa comida.
#
# IMPORTANTE: o pouso e o tombo são detectados pelo CORPO da moto e por um raio para baixo,
# e não só pelas rodas. (As rodas olham "para baixo da moto"; quando a moto cai torta elas
# não encostam no chão, e era por isso que quase nunca dava penalidade.)

@export_group("Geral")
@export var enabled: bool = true
@export_range(0.0, 5.0, 0.1) var pickup_grace: float = 1.5     # s sem dano logo depois de coletar o pedido
@export var debug_print: bool = false                          # true = escreve na aba Saída o que está acontecendo

@export_group("Pouso (ângulo da moto ao voltar ao chão)")
@export_range(0.0, 3.0, 0.05) var landing_min_air_time: float = 0.25   # s no ar para valer como "pouso" (pulinhos não contam)
@export_range(0.0, 90.0, 1.0) var perfect_angle_degrees: float = 20.0  # até este ângulo: pouso perfeito, sem dano
@export_range(0.0, 180.0, 1.0) var light_angle_degrees: float = 35.0
@export_range(0.0, 100.0, 0.5) var light_damage: float = 6.0           # dano (%) neste ângulo
@export_range(0.0, 180.0, 1.0) var medium_angle_degrees: float = 60.0
@export_range(0.0, 100.0, 0.5) var medium_damage: float = 15.0
@export_range(0.0, 180.0, 1.0) var heavy_angle_degrees: float = 90.0   # moto de lado
@export_range(0.0, 100.0, 0.5) var heavy_damage: float = 30.0
@export_range(0.0, 100.0, 0.5) var upside_down_damage: float = 55.0    # dano (%) com a moto de cabeça para baixo (180°)
@export_range(0.0, 60.0, 0.5) var hard_landing_speed: float = 9.0      # m/s de queda a partir dos quais o pouso é "forte"
@export_range(0.0, 10.0, 0.1) var hard_landing_per_ms: float = 2.0     # % perdida por cada m/s acima disso
@export_range(0.0, 100.0, 0.5) var hard_landing_max: float = 20.0      # máximo extra por pouso forte

@export_group("Tombo (moto caída)")
@export_range(10.0, 170.0, 1.0) var fall_angle_degrees: float = 60.0   # a partir desta inclinação a moto conta como caída
@export_range(0.0, 3.0, 0.05) var fall_delay: float = 0.3              # s caída até contar o tombo
@export_range(0.0, 100.0, 0.5) var fall_damage: float = 20.0           # dano (%) do tombo
@export_range(0.0, 50.0, 0.5) var fall_drain_per_second: float = 6.0   # % perdida por segundo enquanto continua caída
@export_range(0.0, 100.0, 0.5) var fall_drain_max: float = 30.0        # máximo perdido dessa forma em uma mesma queda

@export_group("Batida")
@export_range(0.0, 60.0, 0.5) var crash_min_impact: float = 7.0        # m/s perdidos de repente para valer como batida
@export_range(0.0, 100.0, 0.5) var crash_base_damage: float = 5.0      # dano mínimo de uma batida
@export_range(0.0, 10.0, 0.1) var crash_damage_per_ms: float = 1.8     # % extra por cada m/s acima do mínimo
@export_range(0.0, 100.0, 0.5) var crash_max_damage: float = 35.0
@export_range(0.0, 3.0, 0.05) var crash_cooldown: float = 0.6          # s entre uma batida e a próxima poderem contar

@export_group("Levantar a moto")
@export var allow_stand_up_key: bool = true
@export var stand_up_key: Key = KEY_R                                  # tecla para desvirar a moto
@export_range(0.0, 10.0, 0.1) var auto_stand_up_after: float = 2.5     # s caída até levantar sozinha (0 = desligado)

const LANDING_WINDOW: float = 0.15       # s depois de tocar o chão em que se mede o pior ângulo
const GROUND_PROBE_DEPTH: float = 1.6    # m: até onde o raio para baixo procura o chão
const DRAIN_STEP: float = 3.0            # % por aviso enquanto a moto fica caída (evita spam de mensagens)
const STAND_UP_PROTECTION: float = 1.0   # s sem dano depois de levantar a moto
const CRASH_HISTORY_FRAMES: int = 5      # quadros somados para medir a força da batida

var _bike: VehicleBody3D
var _front_wheel: VehicleWheel3D
var _rear_wheel: VehicleWheel3D

var _since_pickup: float = 999.0
var _prev_velocity: Vector3 = Vector3.ZERO
var _air_time: float = 0.0
var _peak_fall_speed: float = 0.0
var _landing_left: float = 0.0
var _landing_peak_speed: float = 0.0
var _worst_tilt: float = 0.0
var _fall_time: float = 0.0
var _fall_hit_done: bool = false
var _drain_accum: float = 0.0
var _drain_total: float = 0.0
var _dv_history: Array[float] = []
var _crash_cooldown_left: float = 0.0
var _protection_left: float = 0.0
var _stand_key_was_pressed: bool = false


func _ready() -> void:
	_bike = get_parent() as VehicleBody3D

	if _bike == null:
		push_error("Integridade: este nó precisa ser filho direto do VehicleBody3D da Motorcycle.")
		set_physics_process(false)
		return

	_front_wheel = _bike.get_node_or_null("RodaFrontal") as VehicleWheel3D
	_rear_wheel = _bike.get_node_or_null("RodaTraseira") as VehicleWheel3D

	if _front_wheel == null or _rear_wheel == null:
		push_error("Integridade: não encontrei RodaFrontal e RodaTraseira dentro da Motorcycle.")
		set_physics_process(false)
		return

	# Ao coletar o pedido começa uma folga curtinha (para sair do restaurante sem susto)
	DeliveryManager.order_picked_up.connect(_on_order_picked_up)


func _on_order_picked_up(_order: Dictionary) -> void:
	_since_pickup = 0.0
	_reset_all()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_bike):
		return

	# Só vale com a moto montada
	if _bike.get("is_mounted") != true:
		_reset_all()
		return

	_since_pickup += delta
	_crash_cooldown_left = maxf(_crash_cooldown_left - delta, 0.0)
	_protection_left = maxf(_protection_left - delta, 0.0)

	# No grind a comida está segura
	if _bike.get("_grinding") == true:
		_air_time = 0.0
		_peak_fall_speed = 0.0
		_landing_left = 0.0
		_dv_history.clear()
		_prev_velocity = _bike.linear_velocity
		return

	var up_y := _bike.global_transform.basis.y.y   # 1 = em pé, 0 = de lado, -1 = de cabeça para baixo
	var wheel_contact := _front_wheel.is_in_contact() or _rear_wheel.is_in_contact()
	var body_contact := _bike.get_colliding_bodies().size() > 0
	var ground := _probe_ground()
	# "No chão" = alguma roda encostou, OU o corpo da moto encostou em algo com chão logo abaixo
	var on_ground := wheel_contact or (body_contact and not ground.is_empty())

	_update_landing(delta, on_ground, ground)
	_update_fall(delta, on_ground, up_y)
	_update_crash(body_contact)
	_update_stand_up()

	_prev_velocity = _bike.linear_velocity


# ------------------------------------------------------------------
# 1) e 2) Pouso
# ------------------------------------------------------------------

func _update_landing(delta: float, on_ground: bool, ground: Dictionary) -> void:
	if on_ground:
		# Acabou de tocar o chão depois de um voo de verdade?
		if _air_time >= landing_min_air_time and _landing_left <= 0.0:
			_landing_left = LANDING_WINDOW
			_worst_tilt = 0.0
			_landing_peak_speed = _peak_fall_speed
			_dv_history.clear()
		_air_time = 0.0
		_peak_fall_speed = 0.0
	else:
		_air_time += delta
		_peak_fall_speed = maxf(_peak_fall_speed, -_bike.linear_velocity.y)

	# Nos primeiros instantes depois do pouso, guarda o pior ângulo (em relação ao chão)
	if _landing_left > 0.0:
		var ground_normal: Vector3 = ground.get("normal", Vector3.UP)
		var tilt := rad_to_deg(_bike.global_transform.basis.y.angle_to(ground_normal))
		_worst_tilt = maxf(_worst_tilt, tilt)
		_landing_left -= delta
		if _landing_left <= 0.0:
			_apply_landing_damage()


func _apply_landing_damage() -> void:
	var angle_damage := _angle_damage(_worst_tilt)
	var hard_damage := clampf((_landing_peak_speed - hard_landing_speed) * hard_landing_per_ms, 0.0, hard_landing_max)
	var total := angle_damage + hard_damage

	if debug_print:
		print("Pouso: ângulo ", snappedf(_worst_tilt, 0.1), "°  queda ", snappedf(_landing_peak_speed, 0.1), " m/s  dano ", snappedf(total, 0.1), "%")

	if total < 1.0:
		return

	var reason := "Pouso forte"
	if _worst_tilt >= 120.0:
		reason = "Pouso de cabeça pra baixo"
	elif _worst_tilt >= 70.0:
		reason = "Pouso de lado"
	elif _worst_tilt > perfect_angle_degrees:
		reason = "Pouso torto"
	_hurt(total, reason)


# Ângulo (graus) -> dano (%), ligando os pontos configurados em linha reta
func _angle_damage(angle: float) -> float:
	var points: Array = [
		[perfect_angle_degrees, 0.0],
		[light_angle_degrees, light_damage],
		[medium_angle_degrees, medium_damage],
		[heavy_angle_degrees, heavy_damage],
		[180.0, upside_down_damage],
	]

	var first_x: float = points[0][0]
	if angle <= first_x:
		return 0.0

	for i in range(1, points.size()):
		var a_x: float = points[i - 1][0]
		var a_y: float = points[i - 1][1]
		var b_x: float = points[i][0]
		var b_y: float = points[i][1]
		if angle <= b_x:
			var span := maxf(b_x - a_x, 0.001)
			return lerpf(a_y, b_y, (angle - a_x) / span)

	return upside_down_damage


# ------------------------------------------------------------------
# 3) Tombo (moto caída)
# ------------------------------------------------------------------

func _update_fall(delta: float, on_ground: bool, up_y: float) -> void:
	var fall_limit := cos(deg_to_rad(fall_angle_degrees))
	var fallen := on_ground and up_y < fall_limit

	if fallen:
		_fall_time += delta

		if _fall_time >= fall_delay and not _fall_hit_done:
			_fall_hit_done = true
			if debug_print:
				print("Tombo!")
			_hurt(fall_damage, "Tombo")
		elif _fall_hit_done and _drain_total < fall_drain_max:
			# Continua perdendo um pouco enquanto fica caída
			var step := minf(fall_drain_per_second * delta, fall_drain_max - _drain_total)
			_drain_accum += step
			_drain_total += step
			if _drain_accum >= DRAIN_STEP:
				_drain_accum -= DRAIN_STEP
				var why := "Moto caída"
				if up_y < 0.0:
					why = "Moto de cabeça pra baixo"
				_hurt(DRAIN_STEP, why)
	else:
		_fall_time = maxf(_fall_time - delta * 2.0, 0.0)
		# Só libera um novo tombo depois que a moto estiver bem em pé
		if up_y > 0.85:
			_fall_hit_done = false
			_drain_accum = 0.0
			_drain_total = 0.0


# ------------------------------------------------------------------
# 4) Batida (parede, obstáculo)
# ------------------------------------------------------------------

# Mede a força da batida pela velocidade que a moto perde de repente (somada em poucos quadros)
func _update_crash(body_contact: bool) -> void:
	var now_h := Vector2(_bike.linear_velocity.x, _bike.linear_velocity.z)
	var before_h := Vector2(_prev_velocity.x, _prev_velocity.z)
	_dv_history.append((before_h - now_h).length())
	while _dv_history.size() > CRASH_HISTORY_FRAMES:
		_dv_history.pop_front()

	# Pouso e tombo já têm seus próprios danos (não conta duas vezes)
	if not body_contact or _crash_cooldown_left > 0.0 or _landing_left > 0.0 or _fall_hit_done:
		return

	var impact := 0.0
	for value in _dv_history:
		impact += value
	if impact < crash_min_impact:
		return

	_dv_history.clear()
	_crash_cooldown_left = crash_cooldown

	var amount := clampf(
		crash_base_damage + (impact - crash_min_impact) * crash_damage_per_ms,
		crash_base_damage,
		crash_max_damage
	)
	if debug_print:
		print("Batida: impacto ", snappedf(impact, 0.1), "  dano ", snappedf(amount, 0.1), "%")
	_hurt(amount, "Batida")


# ------------------------------------------------------------------
# Levantar a moto (tecla R, ou sozinha depois de ficar caída um tempo)
# ------------------------------------------------------------------

func _update_stand_up() -> void:
	var pressed := Input.is_key_pressed(stand_up_key)
	var wants := false

	if allow_stand_up_key and pressed and not _stand_key_was_pressed:
		wants = true
	_stand_key_was_pressed = pressed

	if auto_stand_up_after > 0.0 and _fall_time >= auto_stand_up_after:
		wants = true

	if wants:
		_stand_up()


# Coloca a moto em pé no mesmo lugar, olhando para onde ela já olhava
func _stand_up() -> void:
	var forward := -_bike.global_transform.basis.z
	forward.y = 0.0
	if forward.length() < 0.1:
		forward = Vector3.FORWARD
	forward = forward.normalized()

	_bike.global_transform = Transform3D(
		Basis.looking_at(forward, Vector3.UP),
		_bike.global_position + Vector3.UP * 0.6
	)
	_bike.linear_velocity = Vector3.ZERO
	_bike.angular_velocity = Vector3.ZERO

	_reset_all()
	_protection_left = STAND_UP_PROTECTION
	_prev_velocity = Vector3.ZERO


# ------------------------------------------------------------------
# Utilitários
# ------------------------------------------------------------------

# Aplica o dano (só com o pedido coletado, depois da folga inicial)
func _hurt(amount: float, reason: String) -> void:
	if not enabled or not DeliveryManager.is_carrying():
		return
	if _since_pickup < pickup_grace or _protection_left > 0.0:
		return

	var rounded := roundf(amount)
	if rounded < 1.0:
		return

	if debug_print:
		print("Integridade -", rounded, "%  (", reason, ")")
	DeliveryManager.damage_integrity(rounded, reason)


# Raio para baixo a partir da moto: devolve o ponto/normal do chão (vazio se não há chão perto)
func _probe_ground() -> Dictionary:
	var space := _bike.get_world_3d().direct_space_state
	var from := _bike.global_position + Vector3.UP * 0.3
	var to := _bike.global_position + Vector3.DOWN * GROUND_PROBE_DEPTH
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [_bike.get_rid()]
	return space.intersect_ray(query)


func _reset_all() -> void:
	_air_time = 0.0
	_peak_fall_speed = 0.0
	_landing_left = 0.0
	_worst_tilt = 0.0
	_fall_time = 0.0
	_fall_hit_done = false
	_drain_accum = 0.0
	_drain_total = 0.0
	_dv_history.clear()
