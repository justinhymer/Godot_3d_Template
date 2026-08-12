extends Node3D

enum GameState { MAIN_MENU, PLAYING, PAUSED }

const ROOM_SIZE := 16.0
const ROOM_HEIGHT := 5.0

@onready var player: CharacterBody3D = $Player
@onready var hud: Control = $UI/HUD
@onready var main_menu: Control = $UI/MainMenu
@onready var pause_menu: Control = $UI/PauseMenu
@onready var options_menu: Control = $UI/OptionsMenu

var state := GameState.MAIN_MENU
var options_return_state := GameState.MAIN_MENU
var wall_material: StandardMaterial3D
var floor_material: StandardMaterial3D
var accent_material: StandardMaterial3D
var pickup_material: StandardMaterial3D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	create_materials()
	build_room()
	build_lighting()
	build_physics_props()
	connect_menus()
	show_main_menu()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if options_menu.visible:
			close_options()
		elif state == GameState.PLAYING:
			pause_game()
		elif state == GameState.PAUSED:
			resume_game()
		get_viewport().set_input_as_handled()


func connect_menus() -> void:
	$UI/MainMenu/Center/Menu/NewGameButton.pressed.connect(start_game)
	$UI/MainMenu/Center/Menu/OptionsButton.pressed.connect(func(): open_options(GameState.MAIN_MENU))
	$UI/MainMenu/Center/Menu/QuitButton.pressed.connect(get_tree().quit)
	$UI/PauseMenu/Center/Menu/ResumeButton.pressed.connect(resume_game)
	$UI/PauseMenu/Center/Menu/OptionsButton.pressed.connect(func(): open_options(GameState.PAUSED))
	$UI/PauseMenu/Center/Menu/MainMenuButton.pressed.connect(show_main_menu)
	options_menu.closed.connect(close_options)


func start_game() -> void:
	get_tree().paused = false
	state = GameState.PLAYING
	player.reset_player()
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	main_menu.hide()
	pause_menu.hide()
	options_menu.hide()
	hud.show()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func pause_game() -> void:
	state = GameState.PAUSED
	get_tree().paused = true
	pause_menu.show()
	options_menu.hide()
	hud.hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func resume_game() -> void:
	state = GameState.PLAYING
	get_tree().paused = false
	pause_menu.hide()
	options_menu.hide()
	hud.show()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func show_main_menu() -> void:
	state = GameState.MAIN_MENU
	get_tree().paused = true
	main_menu.show()
	pause_menu.hide()
	options_menu.hide()
	hud.hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func open_options(return_state: GameState) -> void:
	options_return_state = return_state
	main_menu.hide()
	pause_menu.hide()
	options_menu.show()
	options_menu.refresh()


func close_options() -> void:
	options_menu.hide()
	if options_return_state == GameState.PAUSED:
		pause_menu.show()
	else:
		main_menu.show()


func create_materials() -> void:
	wall_material = make_material(Color("c8d1dd"), 0.88)
	floor_material = make_material(Color("596675"), 0.72)
	accent_material = make_material(Color("e69b55"), 0.65)
	pickup_material = make_material(Color("58b8d8"), 0.42)
	metallic_setup(pickup_material)


func make_material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material


func metallic_setup(material: StandardMaterial3D) -> void:
	material.metallic = 0.25


func build_room() -> void:
	create_static_box("Floor", Vector3(ROOM_SIZE, 0.2, ROOM_SIZE), Vector3(0, -0.1, 0), floor_material)
	create_static_box("Ceiling", Vector3(ROOM_SIZE, 0.2, ROOM_SIZE), Vector3(0, ROOM_HEIGHT, 0), wall_material)
	create_static_box("NorthWall", Vector3(ROOM_SIZE, ROOM_HEIGHT, 0.25), Vector3(0, ROOM_HEIGHT / 2.0, -ROOM_SIZE / 2.0), wall_material)
	create_static_box("SouthWall", Vector3(ROOM_SIZE, ROOM_HEIGHT, 0.25), Vector3(0, ROOM_HEIGHT / 2.0, ROOM_SIZE / 2.0), wall_material)
	create_static_box("WestWall", Vector3(0.25, ROOM_HEIGHT, ROOM_SIZE), Vector3(-ROOM_SIZE / 2.0, ROOM_HEIGHT / 2.0, 0), wall_material)
	create_static_box("EastWall", Vector3(0.25, ROOM_HEIGHT, ROOM_SIZE), Vector3(ROOM_SIZE / 2.0, ROOM_HEIGHT / 2.0, 0), wall_material)
	create_static_box("LowPlatform", Vector3(2.2, 0.8, 1.4), Vector3(-3.5, 0.4, -2.4), accent_material)
	create_static_box("TallPlatform", Vector3(1.2, 2.2, 1.2), Vector3(3.5, 1.1, -3.0), accent_material)


func create_static_box(label: String, size: Vector3, location: Vector3, material: Material) -> void:
	var body := StaticBody3D.new()
	body.name = label
	body.position = location
	body.collision_layer = 1
	body.collision_mask = 6
	add_child(body)
	add_box_visual_and_collision(body, size, material)


func build_physics_props() -> void:
	create_physics_box("Blue Crate", Vector3(0.8, 0.8, 0.8), Vector3(-1.5, 0.7, 0), 2.0)
	create_physics_box("Small Cube", Vector3(0.45, 0.45, 0.45), Vector3(0, 0.5, -1.5), 0.6)
	create_physics_box("Long Block", Vector3(1.2, 0.35, 0.45), Vector3(1.8, 0.5, 0.5), 1.2)


func create_physics_box(label: String, size: Vector3, location: Vector3, mass: float) -> void:
	var body := RigidBody3D.new()
	body.name = label
	body.position = location
	body.mass = mass
	body.collision_layer = 4
	# Props collide with the room, player, and one another (layers 1-3).
	body.collision_mask = 7
	body.add_to_group("pickup")
	body.continuous_cd = true
	add_child(body)
	add_box_visual_and_collision(body, size, pickup_material)


func add_box_visual_and_collision(body: CollisionObject3D, size: Vector3, material: Material) -> void:
	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	box_mesh.material = material
	mesh_instance.mesh = box_mesh
	body.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)


func build_lighting() -> void:
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("18202c")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("a9c2e0")
	settings.ambient_light_energy = 0.32
	settings.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = settings
	add_child(environment)
	for x in [-4.5, 4.5]:
		var light := OmniLight3D.new()
		light.position = Vector3(x, 4.2, 0)
		light.light_color = Color("fff0d5")
		light.light_energy = 3.1
		light.omni_range = 10.0
		light.shadow_enabled = true
		add_child(light)
