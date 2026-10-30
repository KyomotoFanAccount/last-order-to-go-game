extends Node
# Sistema de entregas do zFood (autoload "DeliveryManager").
# Guarda os pedidos disponíveis, o pedido ativo, o dinheiro, a integridade da comida
# e a nota do entregador.
#
# Os pontos do mapa são nós nos grupos:
#   "pickup_point"  = restaurantes (ponto A)
#   "dropoff_point" = clientes (ponto B)
# O script delivery_point.gd faz isso sozinho em um bloco (CSGBox3D).

signal offers_changed
signal order_accepted(order: Dictionary)
signal order_picked_up(order: Dictionary)
signal order_completed(order: Dictionary, result: Dictionary)
signal order_cancelled(order: Dictionary)
signal integrity_changed(value: float)
signal integrity_damaged(amount: float, reason: String)

enum State { IDLE, GOING_TO_PICKUP, GOING_TO_DROPOFF }

# --- Ajustes (valores de teste; os valores finais a gente define no grupo) ---
const DEBUG_KEYS: bool = true            # K = tira 10% de integridade (só para testar). Desligue depois.
const OFFER_COUNT: int = 3               # quantos pedidos aparecem no app
const MIN_ORDER_DISTANCE: float = 40.0   # m: distância mínima entre o restaurante e o cliente
const DEFAULT_ARRIVE_RADIUS: float = 6.0 # m: raio de chegada de pontos que não têm "get_arrive_radius"
const REWARD_BASE: float = 8.0           # R$ fixos por entrega
const REWARD_PER_METER: float = 0.04     # R$ por metro entre A e B
const TIME_BASE: float = 45.0            # s de tolerância somados ao prazo
const TIME_AVERAGE_SPEED: float = 12.0   # m/s usados para calcular o prazo (≈ 43 km/h)

# Faixas de qualidade pela integridade da comida:
# [integridade mínima (%), parte do pagamento que é paga, estrelas, nome da faixa]
const QUALITY_TIERS: Array = [
	[95.0, 1.00, 5, "Perfeito"],
	[80.0, 0.90, 4, "Ótimo"],
	[60.0, 0.70, 3, "Bom"],
	[40.0, 0.50, 2, "Amassado"],
	[1.0, 0.25, 1, "Estragado"],
	[0.0, 0.00, 1, "Destruído"],
]

# Gorjeta (parte do pagamento base) por estrelas. Cada cliente multiplica isso pela generosidade dele.
const TIP_BY_STARS: Dictionary = {5: 0.25, 4: 0.12, 3: 0.0, 2: 0.0, 1: 0.0}

const COMMENTS: Dictionary = {
	5: ["Chegou perfeito! Valeu!", "Nota 10! Estava impecável.", "Voltei a ter fé em entregador."],
	4: ["Tudo certo, obrigado!", "Ótimo, só um detalhe ou outro.", "Gostei, pode vir de novo."],
	3: ["Chegou, né...", "Dava pra ser melhor.", "Ok, sem mais."],
	2: ["Chegou todo amassado.", "Isso aqui era pra ser o meu jantar?", "Cuidado na próxima, tá?"],
	1: ["Que desastre!", "Isso não é comida, é sopa!", "Nunca mais."],
}

const FOODS: Array[String] = [
	"Pizza grande", "Combo de hambúrguer", "Sushi combinado", "Açaí 500 ml",
	"Marmita fitness", "Pastel de feira", "Sorvete família", "Lasanha à bolonhesa",
]
const CUSTOMERS: Array[String] = [
	"Ana", "Bruno", "Carla", "Diego", "Elisa", "Fábio", "Gabi", "Hugo", "Iara", "João",
]

var state: State = State.IDLE
var offers: Array[Dictionary] = []
var active_order: Dictionary = {}
var money: float = 0.0
var integrity: float = 100.0             # % da comida dentro da bag
var time_left: float = 0.0               # s até o prazo (negativo = atrasado)
var distance_to_target: float = -1.0     # m que faltam para chegar ao ponto atual (-1 = desconhecida)

# Avaliação do entregador
var rating_sum: int = 0
var rating_count: int = 0
var deliveries_done: int = 0

var _next_id: int = 1
var _marker: MeshInstance3D = null
var _reference: Node3D = null
var _reference_timer: float = 0.0

# ------------------------------------------------------------------
# Consultas simples (o HUD usa estas)
# ------------------------------------------------------------------

func is_busy() -> bool:
	return state != State.IDLE

func is_carrying() -> bool:
	return state == State.GOING_TO_DROPOFF

# Nota média do entregador (0 se ainda não tem avaliações)
func get_rating_average() -> float:
	if rating_count == 0:
		return 0.0
	return float(rating_sum) / float(rating_count)

# ------------------------------------------------------------------
# Gerador de pedidos (A -> B)
# ------------------------------------------------------------------

func generate_offers() -> void:
	offers.clear()

	var pickups = get_tree().get_nodes_in_group("pickup_point")
	var dropoffs = get_tree().get_nodes_in_group("dropoff_point")
	if pickups.is_empty() or dropoffs.is_empty():
		push_warning("zFood: faltam pontos no mapa. Precisa de blocos 'Restaurante' (grupo pickup_point) e 'Casa' (grupo dropoff_point).")
		offers_changed.emit()
		return

	for i in OFFER_COUNT:
		var order = _make_order(pickups, dropoffs)
		if not order.is_empty():
			offers.append(order)

	offers_changed.emit()

func _make_order(pickups: Array, dropoffs: Array) -> Dictionary:
	var pickup: Node3D = null
	var dropoff: Node3D = null

	# Sorteia um par; tenta algumas vezes até achar um com distância boa
	for _attempt in 12:
		var a = pickups.pick_random() as Node3D
		var b = dropoffs.pick_random() as Node3D
		if a == null or b == null or a == b:
			continue
		pickup = a
		dropoff = b
		if _flat_distance(a.global_position, b.global_position) >= MIN_ORDER_DISTANCE:
			break

	if pickup == null or dropoff == null:
		return {}

	var distance = _flat_distance(pickup.global_position, dropoff.global_position)
	var order = {
		"id": _next_id,
		"food": FOODS.pick_random(),
		"customer": CUSTOMERS.pick_random(),
		"generosity": snappedf(randf_range(0.6, 1.5), 0.01),   # quanto este cliente costuma dar de gorjeta
		"pickup_node": pickup,
		"dropoff_node": dropoff,
		"pickup_name": _point_name(pickup),
		"dropoff_name": _point_name(dropoff),
		"pickup_pos": pickup.global_position,
		"dropoff_pos": dropoff.global_position,
		"pickup_radius": _point_radius(pickup),
		"dropoff_radius": _point_radius(dropoff),
		"distance": distance,
		"reward": snappedf(REWARD_BASE + distance * REWARD_PER_METER, 0.01),
		"time_limit": distance / TIME_AVERAGE_SPEED + TIME_BASE,
	}
	_next_id += 1
	return order

# ------------------------------------------------------------------
# Fluxo do pedido: aceitar -> coletar -> entregar
# ------------------------------------------------------------------

func accept_order(order_id: int) -> void:
	if state != State.IDLE:
		return

	for order in offers:
		if order["id"] != order_id:
			continue

		active_order = order
		offers.clear()
		state = State.GOING_TO_PICKUP
		integrity = 100.0

		# Prazo = tempo da entrega + tempo para chegar ao restaurante
		time_left = order["time_limit"]
		var reference = _find_reference()
		if reference != null:
			time_left += _flat_distance(reference.global_position, _point_position(order, "pickup")) / TIME_AVERAGE_SPEED

		_create_marker(_point_position(order, "pickup"), Color(1.0, 0.55, 0.1))
		order_accepted.emit(order)
		offers_changed.emit()
		return

func cancel_order() -> void:
	if state == State.IDLE:
		return

	var cancelled = active_order
	_finish_order()
	order_cancelled.emit(cancelled)

func _pick_up() -> void:
	state = State.GOING_TO_DROPOFF
	integrity = 100.0
	integrity_changed.emit(integrity)
	_create_marker(_point_position(active_order, "dropoff"), Color(0.2, 1.0, 0.4))
	order_picked_up.emit(active_order)

# Conclui a entrega: o pagamento depende da integridade e o cliente avalia e pode dar gorjeta
func _complete() -> void:
	var finished = active_order
	var tier = _get_tier(integrity)
	var factor: float = tier[1]
	var stars: int = tier[2]
	var base_reward: float = finished["reward"]

	var payout = snappedf(base_reward * factor, 0.01)
	var tip_percent: float = TIP_BY_STARS.get(stars, 0.0)
	var tip = snappedf(base_reward * tip_percent * float(finished["generosity"]), 0.01)

	var result = {
		"integrity": integrity,
		"tier_name": tier[3],
		"factor": factor,
		"stars": stars,
		"base_reward": base_reward,
		"payout": payout,
		"tip": tip,
		"total": payout + tip,
		"comment": COMMENTS[stars].pick_random(),
		"late_seconds": maxf(-time_left, 0.0),
	}

	money += payout + tip
	rating_sum += stars
	rating_count += 1
	deliveries_done += 1

	_finish_order()
	order_completed.emit(finished, result)

func _finish_order() -> void:
	state = State.IDLE
	active_order = {}
	offers.clear()          # o app sorteia pedidos novos na próxima vez que abrir
	distance_to_target = -1.0
	_clear_marker()
	offers_changed.emit()

# Acha a faixa de qualidade para uma integridade
func _get_tier(value: float) -> Array:
	for tier in QUALITY_TIERS:
		if value >= tier[0]:
			return tier
	return QUALITY_TIERS[QUALITY_TIERS.size() - 1]

# ------------------------------------------------------------------
# Integridade da comida (os outros sistemas chamam esta função)
# ------------------------------------------------------------------

# Tira "amount" % da integridade. Só vale com a comida dentro da bag.
func damage_integrity(amount: float, reason: String = "") -> void:
	if state != State.GOING_TO_DROPOFF:
		return
	integrity = clampf(integrity - amount, 0.0, 100.0)
	integrity_changed.emit(integrity)
	integrity_damaged.emit(amount, reason)

# Tecla de teste: K tira 10% de integridade (para você ver os pagamentos e as notas)
func _unhandled_input(event: InputEvent) -> void:
	if not DEBUG_KEYS:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_K:
		damage_integrity(10.0, "teste: tecla K")

# ------------------------------------------------------------------
# Atualização a cada quadro: prazo e chegada aos pontos
# ------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if state == State.IDLE:
		return

	time_left -= delta

	var which = "dropoff"
	if state == State.GOING_TO_PICKUP:
		which = "pickup"

	# Lê a posição do ponto a cada quadro (assim funciona mesmo se o prédio mudar de lugar)
	var target = _point_position(active_order, which)
	var radius: float = active_order[which + "_radius"]
	if is_instance_valid(_marker):
		_marker.global_position = target + Vector3(0.0, 40.0, 0.0)

	var reference = _get_reference(delta)
	if reference == null:
		distance_to_target = -1.0
		return

	distance_to_target = maxf(_flat_distance(reference.global_position, target) - radius, 0.0)
	if distance_to_target <= 0.0 and absf(reference.global_position.y - target.y) < 12.0:
		if state == State.GOING_TO_PICKUP:
			_pick_up()
		else:
			_complete()

# Quem conta como "o entregador": a moto montada ou, se não houver, o jogador a pé
func _get_reference(delta: float) -> Node3D:
	_reference_timer -= delta
	if _reference_timer <= 0.0 or not is_instance_valid(_reference):
		_reference_timer = 0.5
		_reference = _find_reference()
	return _reference

func _find_reference() -> Node3D:
	var root = get_tree().current_scene
	if root == null:
		return null

	for node in root.find_children("*", "VehicleBody3D", true, false):
		if node.get("is_mounted") == true:
			return node as Node3D

	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0] as Node3D
	return null

# ------------------------------------------------------------------
# Marcador 3D (coluna colorida no destino)
# ------------------------------------------------------------------

func _create_marker(where: Vector3, color: Color) -> void:
	_clear_marker()

	var root = get_tree().current_scene
	if root == null:
		return

	var mesh = CylinderMesh.new()
	mesh.top_radius = 1.5
	mesh.bottom_radius = 1.5
	mesh.height = 80.0
	mesh.radial_segments = 24

	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = Color(color.r, color.g, color.b, 0.35)
	mesh.material = material

	_marker = MeshInstance3D.new()
	_marker.mesh = mesh
	_marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(_marker)
	_marker.global_position = where + Vector3(0.0, 40.0, 0.0)

func _clear_marker() -> void:
	if is_instance_valid(_marker):
		_marker.queue_free()
	_marker = null

# ------------------------------------------------------------------
# Utilitários
# ------------------------------------------------------------------

func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()

# Posição atual de um ponto do pedido ("pickup" ou "dropoff")
func _point_position(order: Dictionary, which: String) -> Vector3:
	var node = order.get(which + "_node")
	if is_instance_valid(node):
		return (node as Node3D).global_position
	return order[which + "_pos"]

func _point_name(node: Node) -> String:
	if node.has_method("get_point_name"):
		return node.get_point_name()
	return str(node.name).replace("_", " ")

func _point_radius(node: Node) -> float:
	if node.has_method("get_arrive_radius"):
		return node.get_arrive_radius()
	return DEFAULT_ARRIVE_RADIUS
