extends Control

signal closed

@onready var sensitivity_slider: HSlider = %SensitivitySlider
@onready var sensitivity_value: Label = %SensitivityValue
@onready var fov_slider: HSlider = %FovSlider
@onready var fov_value: Label = %FovValue
@onready var volume_slider: HSlider = %VolumeSlider
@onready var volume_value: Label = %VolumeValue
@onready var fullscreen_check: CheckButton = %FullscreenCheck
@onready var vsync_check: CheckButton = %VsyncCheck


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	fov_slider.value_changed.connect(_on_fov_changed)
	volume_slider.value_changed.connect(_on_volume_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	vsync_check.toggled.connect(_on_vsync_toggled)
	%DefaultsButton.pressed.connect(_on_defaults_pressed)
	%BackButton.pressed.connect(_on_back_pressed)
	refresh()


func refresh() -> void:
	sensitivity_slider.set_value_no_signal(GameSettings.mouse_sensitivity)
	fov_slider.set_value_no_signal(GameSettings.field_of_view)
	volume_slider.set_value_no_signal(GameSettings.master_volume)
	fullscreen_check.set_pressed_no_signal(GameSettings.fullscreen)
	vsync_check.set_pressed_no_signal(GameSettings.vsync)
	update_value_labels()


func _on_visibility_changed() -> void:
	if visible and is_node_ready():
		refresh()


func update_value_labels() -> void:
	sensitivity_value.text = "%.2f" % GameSettings.mouse_sensitivity
	fov_value.text = "%d°" % int(GameSettings.field_of_view)
	volume_value.text = "%d%%" % int(GameSettings.master_volume)


func _on_sensitivity_changed(value: float) -> void:
	GameSettings.mouse_sensitivity = value
	GameSettings.save()
	update_value_labels()


func _on_fov_changed(value: float) -> void:
	GameSettings.field_of_view = value
	GameSettings.save()
	update_value_labels()


func _on_volume_changed(value: float) -> void:
	GameSettings.master_volume = value
	GameSettings.save()
	update_value_labels()


func _on_fullscreen_toggled(enabled: bool) -> void:
	GameSettings.fullscreen = enabled
	GameSettings.save()


func _on_vsync_toggled(enabled: bool) -> void:
	GameSettings.vsync = enabled
	GameSettings.save()


func _on_defaults_pressed() -> void:
	GameSettings.reset_defaults()
	refresh()


func _on_back_pressed() -> void:
	closed.emit()
