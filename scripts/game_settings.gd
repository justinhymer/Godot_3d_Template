extends Node

signal changed

const SAVE_PATH := "user://settings.cfg"

var mouse_sensitivity := 0.22
var field_of_view := 75.0
var master_volume := 80.0
var fullscreen := false
var vsync := true


func _ready() -> void:
	load_settings()
	apply()


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	mouse_sensitivity = float(config.get_value("controls", "mouse_sensitivity", mouse_sensitivity))
	field_of_view = float(config.get_value("display", "field_of_view", field_of_view))
	master_volume = float(config.get_value("audio", "master_volume", master_volume))
	fullscreen = bool(config.get_value("display", "fullscreen", fullscreen))
	vsync = bool(config.get_value("display", "vsync", vsync))


func save() -> void:
	var config := ConfigFile.new()
	config.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	config.set_value("display", "field_of_view", field_of_view)
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("display", "vsync", vsync)
	config.save(SAVE_PATH)
	apply()
	changed.emit()


func reset_defaults() -> void:
	mouse_sensitivity = 0.22
	field_of_view = 75.0
	master_volume = 80.0
	fullscreen = false
	vsync = true
	save()


func apply() -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(master_volume / 100.0))
	AudioServer.set_bus_mute(master_bus, master_volume <= 0.0)
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	)
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED
	)
