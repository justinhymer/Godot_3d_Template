extends SceneTree


func _initialize() -> void:
	call_deferred("run_tests")


func run_tests() -> void:
	var packed := load("res://main.tscn") as PackedScene
	assert(packed != null, "Main scene should load")
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame

	assert(main.state == main.GameState.MAIN_MENU, "Project should start at the main menu")
	assert(main.get_node("UI/MainMenu").visible, "Main menu should be visible")
	assert(main.get_node("UI/HUD").visible == false, "HUD should be hidden at the main menu")

	main.start_game()
	assert(paused == false, "Starting should unpause the game")
	assert(main.get_node("UI/HUD").visible, "Starting should show the HUD")

	main.pause_game()
	assert(paused, "Pause menu should pause the scene tree")
	assert(main.get_node("UI/PauseMenu").visible, "Pause menu should be visible")

	main.resume_game()
	assert(paused == false, "Resume should unpause the scene tree")

	var pickups := get_nodes_in_group("pickup")
	assert(pickups.size() >= 3, "The test room should contain physics pickups")
	var player := main.get_node("Player")
	var object := pickups[0] as RigidBody3D
	var original_layer := object.collision_layer
	var original_mask := object.collision_mask
	player.pickup_object(object)
	assert(player.held_object == object, "Player should hold a pickup")
	assert(object.freeze, "Held pickup should be controlled kinematically")
	assert(object.collision_layer == original_layer, "Held pickup should remain collidable")
	assert(object.collision_mask != 0, "Held pickup should keep detecting scene collisions")
	assert((object.collision_mask & 4) != 0, "Pickups should collide with other pickups")
	assert(object.get_collision_exceptions().has(player), "Held pickup should only ignore its player")

	object.global_position = player.hold_point.global_position
	for _step in range(30):
		player.global_position.z -= player.walk_speed / 60.0
		player.update_held_object(1.0 / 60.0)
	assert(player.held_object == object, "Normal carry lag while walking should not release a pickup")

	player.global_position = Vector3(0.0, 1.0, 4.5)
	object.global_position = player.hold_point.global_position
	player.rotate_y(PI)
	player.update_held_object(1.0 / 60.0)
	assert(player.held_object == object, "A fast camera turn should not release a pickup")

	player.rotation = Vector3.ZERO
	var blocker := pickups[1] as RigidBody3D
	blocker.freeze = true
	blocker.global_position = Vector3(0.0, 1.44, 3.2)
	object.global_position = Vector3(0.0, 1.44, 4.0)
	player.global_position = Vector3(1.5, 1.0, 4.5)
	await physics_frame
	player.update_held_object(1.0 / 60.0)
	assert(object.global_position.x > 0.3, "A held pickup should slide sideways around an obstruction")
	assert(player.held_object == object, "Sliding around an obstruction should keep the pickup held")

	player.global_position = Vector3(0.0, 1.0, 4.5)
	object.global_position = Vector3(0.0, 1.44, 4.0)
	await physics_frame
	for _step in range(20):
		player.update_held_object(1.0 / 60.0)
	assert(object.global_position.z >= 3.69, "Held pickup should stop before passing through another prop")

	for _step in range(30):
		player.global_position.z -= player.walk_speed / 60.0
		player.update_held_object(1.0 / 60.0)
		if player.held_object == null:
			break
	assert(player.held_object == null, "A pickup stuck too far behind should be released")
	assert(object.freeze == false, "An out-of-range pickup should return to rigid-body physics")
	assert(object.linear_velocity.is_zero_approx(), "Automatic release should not throw the pickup")
	assert(player.held_object == null, "Player should release a dropped pickup")
	assert(object.freeze == false, "Dropped pickup should return to rigid-body physics")
	assert(object.collision_layer == original_layer, "Dropping should restore the collision layer")
	assert(object.collision_mask == original_mask, "Dropping should restore the collision mask")
	assert(not object.get_collision_exceptions().has(player), "Dropping should restore player collisions")

	print("SMOKE TEST PASSED: menus, pause, settings, and collision-aware pickup/drop")
	quit(0)
