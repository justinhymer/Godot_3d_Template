extends CharacterBody3D

@export_category("Movement")
@export var walk_speed := 5.0
@export var jump_velocity := 6.5
@export var acceleration := 24.0

@export_category("Interaction")
@export var pickup_distance := 3.5
@export var hold_smoothing := 16.0
@export var max_hold_offset := 1.0
@export var blocked_release_delay := 0.25
@export_range(1, 8, 1) var max_hold_slide_collisions := 4
@export var drop_impulse := 1.5

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var interaction_ray: RayCast3D = $Head/Camera3D/InteractionRay
@onready var hold_point: Marker3D = $Head/Camera3D/HoldPoint
@onready var interaction_prompt: Label = get_node("../UI/HUD/InteractionPrompt")

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var held_object: RigidBody3D
var held_collision_layer := 0
var held_collision_mask := 0
var held_blocked_time := 0.0


func _ready() -> void:
	apply_settings()
	GameSettings.changed.connect(apply_settings)


func apply_settings() -> void:
	camera.fov = GameSettings.field_of_view


func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event is InputEventMouseMotion:
		var sensitivity: float = GameSettings.mouse_sensitivity / 100.0
		rotate_y(-event.relative.x * sensitivity)
		head.rotate_x(-event.relative.y * sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-88.0), deg_to_rad(88.0))
	if event.is_action_pressed("interact"):
		interact()
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input.x, 0.0, input.y)).normalized()
	var target := direction * walk_speed
	velocity.x = move_toward(velocity.x, target.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target.z, acceleration * delta)
	move_and_slide()

	update_held_object(delta)
	update_interaction_prompt()


func interact() -> void:
	if is_instance_valid(held_object):
		drop_object()
		return
	interaction_ray.force_raycast_update()
	var target := interaction_ray.get_collider()
	if target is RigidBody3D and target.is_in_group("pickup"):
		pickup_object(target)


func pickup_object(object: RigidBody3D) -> void:
	held_object = object
	held_collision_layer = object.collision_layer
	held_collision_mask = object.collision_mask
	held_blocked_time = 0.0
	object.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	object.freeze = true
	# Keep collisions enabled while carrying. The player is the only exception so
	# the held object cannot trap or shove the character holding it.
	object.collision_mask &= ~collision_layer
	object.add_collision_exception_with(self)
	object.linear_velocity = Vector3.ZERO
	object.angular_velocity = Vector3.ZERO


func drop_object(apply_drop_impulse := true) -> void:
	if not is_instance_valid(held_object):
		held_object = null
		return
	var object := held_object
	held_object = null
	held_blocked_time = 0.0
	object.collision_layer = held_collision_layer
	object.collision_mask = held_collision_mask
	object.remove_collision_exception_with(self)
	object.linear_velocity = Vector3.ZERO
	object.angular_velocity = Vector3.ZERO
	object.freeze = false
	if apply_drop_impulse:
		object.apply_central_impulse(-camera.global_transform.basis.z * drop_impulse)


func update_held_object(delta: float) -> void:
	if not is_instance_valid(held_object):
		held_object = null
		return
	var weight := 1.0 - exp(-hold_smoothing * delta)
	var desired_transform := held_object.global_transform
	desired_transform.basis = camera.global_transform.basis.orthonormalized()
	# Do not rotate into a wall or another physics body.
	if not held_object.test_move(desired_transform, Vector3.ZERO, null, 0.001, true):
		held_object.global_transform = desired_transform
	var motion := (hold_point.global_position - held_object.global_position) * weight
	var collided := move_held_object_with_slide(motion)
	# Measure tether stretch from the intended carry position, not the player's
	# origin. Only sustained collision counts, so a quick camera turn can create a
	# temporary gap without dropping or launching the object.
	if collided and hold_point.global_position.distance_to(held_object.global_position) > max_hold_offset:
		held_blocked_time += delta
	else:
		held_blocked_time = 0.0
	if held_blocked_time >= blocked_release_delay:
		drop_object(false)


func move_held_object_with_slide(motion: Vector3) -> bool:
	var remaining_motion := motion
	var collided := false
	for _iteration in range(max_hold_slide_collisions):
		if remaining_motion.length_squared() <= 0.000001:
			break
		var collision := held_object.move_and_collide(remaining_motion)
		if collision == null:
			break
		collided = true
		# Use the unused part of the requested movement along the contact plane.
		# Repeating this handles a second surface or corner in the same frame.
		remaining_motion = collision.get_remainder().slide(collision.get_normal())
	return collided


func update_interaction_prompt() -> void:
	if is_instance_valid(held_object):
		interaction_prompt.text = "[E]  Drop %s" % held_object.name
		interaction_prompt.visible = true
		return
	interaction_ray.force_raycast_update()
	var target := interaction_ray.get_collider()
	if target is RigidBody3D and target.is_in_group("pickup"):
		interaction_prompt.text = "[E]  Pick up %s" % target.name
		interaction_prompt.visible = true
	else:
		interaction_prompt.visible = false


func reset_player() -> void:
	if is_instance_valid(held_object):
		drop_object()
	global_position = Vector3(0, 1.0, 4.5)
	rotation = Vector3.ZERO
	head.rotation = Vector3.ZERO
	velocity = Vector3.ZERO
