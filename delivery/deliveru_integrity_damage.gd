extends Node

# Este nó deve ser filho direto do VehicleBody3D da Motorcycle.tscn.
# As rodas devem ser filhas do VehicleBody3D:
# Motorcycle (VehicleBody3D)
# ├── RodaFrontal
# ├── RodaTraseira
# └── IntegrityDamage

@export_group("Dano ao pousar")
@export_range(0.0, 90.0, 1.0) var safe_angle_degrees: float = 35.0
@export_range(0.0, 180.0, 1.0) var severe_angle_degrees: float = 60.0
@export_range(0.0, 30.0, 0.5) var maximum_landing_damage: float = 15.0
@export_range(0.0, 30.0, 0.5) var minimum_landing_speed: float = 4.0

@export_group("Moto caída")
@export_range(0.0, 10.0, 0.1) var overturned_delay: float = 1.2
@export_range(0.0, 100.0, 1.0) var overturned_damage: float = 25.0
@export_range(0.0, 180.0, 1.0) var overturned_angle_degrees: float = 100.0

var _bike: VehicleBody3D
var _front_wheel: VehicleWheel3D
var _rear_wheel: VehicleWheel3D

var _was_grounded: bool = false
var _overturned_time: float = 0.0
var _damage_applied_while_overturned: bool = false


func _ready() -> void:
	_bike = get_parent() as VehicleBody3D

	if _bike == null:
		push_error(
			"Integridade: IntegrityDamage precisa ser filho direto "
			+ "do VehicleBody3D da Motorcycle."
		)
		set_physics_process(false)
		return

	_front_wheel = _bike.get_node_or_null("RodaFrontal") as VehicleWheel3D
	_rear_wheel = _bike.get_node_or_null("RodaTraseira") as VehicleWheel3D

	if _front_wheel == null:
		push_error(
			"Integridade: não encontrei VehicleWheel3D chamado RodaFrontal "
			+ "dentro da Motorcycle."
		)
		set_physics_process(false)
		return

	if _rear_wheel == null:
		push_error(
			"Integridade: não encontrei VehicleWheel3D chamado RodaTraseira "
			+ "dentro da Motorcycle."
		)
		set_physics_process(false)
		return

	_was_grounded = _is_grounded()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_bike):
		return

	# A moto só carrega comida depois de coletar o pedido.
	if not DeliveryManager.is_carrying():
		_was_grounded = _is_grounded()
		_overturned_time = 0.0
		_damage_applied_while_overturned = false
		return

	var grounded := _is_grounded()
	var angle := _get_tilt_degrees()

	# Dano de pouso é avaliado uma vez quando a moto volta ao chão.
	# Girar no ar não tira integridade.
	if grounded and not _was_grounded:
		_damage_for_landing(angle)

	_was_grounded = grounded

	# Se ficar deitada no chão, espera o jogador ter tempo de se recuperar.
	if grounded and angle >= overturned_angle_degrees:
		_overturned_time += delta

		if (
			_overturned_time >= overturned_delay
			and not _damage_applied_while_overturned
		):
			DeliveryManager.damage_integrity(
				overturned_damage,
				"Moto ficou caída"
			)
			_damage_applied_while_overturned = true
	else:
		_overturned_time = 0.0

		# Para contar outro tombo, a moto precisa primeiro se endireitar.
		if angle < safe_angle_degrees:
			_damage_applied_while_overturned = false


func _is_grounded() -> bool:
	return (
		_front_wheel.is_in_contact()
		or _rear_wheel.is_in_contact()
	)


func _get_tilt_degrees() -> float:
	var bike_up := _bike.global_transform.basis.y.normalized()
	var upright_dot := clampf(bike_up.dot(Vector3.UP), -1.0, 1.0)
	return rad_to_deg(acos(upright_dot))


func _damage_for_landing(angle: float) -> void:
	var horizontal_velocity := Vector3(
		_bike.linear_velocity.x,
		0.0,
		_bike.linear_velocity.z
	)
	var landing_speed := horizontal_velocity.length()

	if landing_speed < minimum_landing_speed:
		return
	if angle <= safe_angle_degrees:
		return

	var damage: float

	if angle < severe_angle_degrees:
		var angle_range := maxf(
			severe_angle_degrees - safe_angle_degrees,
			1.0
		)
		var amount := (angle - safe_angle_degrees) / angle_range
		damage = lerpf(2.0, 5.0, clampf(amount, 0.0, 1.0))
	else:
		var angle_range := maxf(180.0 - severe_angle_degrees, 1.0)
		var amount := (angle - severe_angle_degrees) / angle_range
		damage = lerpf(
			5.0,
			maximum_landing_damage,
			clampf(amount, 0.0, 1.0)
		)

	if damage > 0.0:
		DeliveryManager.damage_integrity(damage, "Pouso torto")
