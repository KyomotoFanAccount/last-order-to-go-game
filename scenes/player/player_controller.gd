
extends CharacterBody3D
class_name DeliveryPlayer

@export_group("Movimentação")
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var acceleration: float = 18.0
@export var deceleration: float = 22.0
@export var jump_velocity: float = 6.0
@export var gravity: float = 24.0
@export var rotation_speed: float = 12.0

@export_group("Câmera")
@export var mouse_sensitivity: float = 0.0025
@export var min_pitch: float = -60.0
@export var max_pitch: float = 50.0

@export_group("Animações")
@export var animation_player: AnimationPlayer
@export var idle_animation: String = "Idle"
@export var walk_animation: String = "Walk"
@export var run_animation: String = "Run"

@export_group("Interação")
@export var interaction_distance: float = 2.8

@onready var visual: Node3D = $VisualPivot
@onready var camera_rig: Node3D = $CameraRig
@onready var spring_arm: SpringArm3D = \
	$CameraRig/SpringArm3D
@onready var camera: Camera3D = \
	$CameraRig/SpringArm3D/Camera3D
@onready var collision: CollisionShape3D = \
	$CollisionShape3D

var current_vehicle: CharacterBody3D = null
var current_animation: String = ""


func _ready() -> void:
	camera.make_current()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			return

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if current_vehicle != null:
		return

	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			camera_rig.rotation.y -= (
				event.screen_relative.x * mouse_sensitivity
			)

			spring_arm.rotation.x -= (
				event.screen_relative.y * mouse_sensitivity
			)

			spring_arm.rotation.x = clampf(
				spring_arm.rotation.x,
				deg_to_rad(min_pitch),
				deg_to_rad(max_pitch)
			)


func _physics_process(delta: float) -> void:
	if current_vehicle != null:
		return

	handle_movement(delta)
	handle_animation()

	if Input.is_action_just_pressed("interact"):
		try_enter_vehicle()


func handle_movement(delta: float) -> void:
	var input_vector := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward"
	)

	var cam_forward := -camera.global_basis.z
	var cam_right := camera.global_basis.x

	cam_forward.y = 0.0
	cam_right.y = 0.0

	cam_forward = cam_forward.normalized()
	cam_right = cam_right.normalized()

	var direction := (
		cam_right * input_vector.x
		- cam_forward * input_vector.y
	).normalized()

	var speed := walk_speed

	if Input.is_action_pressed("sprint"):
		speed = sprint_speed

	var target := direction * speed

	var rate := acceleration
	if direction.length_squared() < 0.01:
		rate = deceleration

	velocity.x = move_toward(
		velocity.x, target.x, rate * delta
	)
	velocity.z = move_toward(
		velocity.z, target.z, rate * delta
	)

	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
		else:
			velocity.y = 0.0
	else:
		velocity.y -= gravity * delta

	move_and_slide()

	if direction.length_squared() > 0.01:
		var target_angle := atan2(
			-direction.x, -direction.z
		)

		visual.rotation.y = lerp_angle(
			visual.rotation.y,
			target_angle,
			clampf(rotation_speed * delta, 0.0, 1.0)
		)


func handle_animation() -> void:
	var horizontal_speed := Vector2(
		velocity.x, velocity.z
	).length()

	var target_animation := idle_animation

	if horizontal_speed > 0.2:
		if Input.is_action_pressed("sprint"):
			target_animation = run_animation
		else:
			target_animation = walk_animation

	play_animation(target_animation)


func play_animation(anim_name: String) -> void:
	if animation_player == null:
		return

	if not animation_player.has_animation(anim_name):
		return

	if current_animation == anim_name:
		return

	animation_player.play(anim_name, 0.15)
	current_animation = anim_name


func try_enter_vehicle() -> void:
	var nearest: Node3D = null
	var nearest_distance := interaction_distance

	for vehicle in get_tree().get_nodes_in_group("vehicles"):
		if not vehicle is Node3D:
			continue

		var distance := global_position.distance_to(
			vehicle.global_position
		)

		if distance < nearest_distance:
			nearest = vehicle
			nearest_distance = distance

	if nearest != null and nearest.has_method("mount"):
		nearest.mount(self)


func set_riding(enabled: bool) -> void:
	visible = not enabled

	collision.set_deferred("disabled", enabled)
	set_collision_layer_value(1, not enabled)
	set_collision_mask_value(1, not enabled)

	velocity = Vector3.ZERO

	if not enabled:
		camera.make_current()
