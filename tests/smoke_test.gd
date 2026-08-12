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
	player.pickup_object(object)
	assert(player.held_object == object, "Player should hold a pickup")
	assert(object.freeze, "Held pickup should be controlled kinematically")
	player.drop_object()
	assert(player.held_object == null, "Player should release a dropped pickup")
	assert(object.freeze == false, "Dropped pickup should return to rigid-body physics")

	print("SMOKE TEST PASSED: menus, pause, settings, and pickup/drop")
	quit(0)
