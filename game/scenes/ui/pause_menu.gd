## Pause and settings menu supporting audio sliders and accessibility toggles.
extends Control

signal resume_requested
signal quit_requested
signal settings_changed(settings)

@onready var _master_slider: HSlider = $Panel/VBoxContainer/MasterSlider
@onready var _music_slider: HSlider = $Panel/VBoxContainer/MusicSlider
@onready var _sfx_slider: HSlider = $Panel/VBoxContainer/SFXSlider
@onready var _colorblind_option: OptionButton = $Panel/VBoxContainer/ColorblindOption
@onready var _status_label: Label = $Panel/VBoxContainer/StatusLabel
@onready var _resume_button: Button = $Panel/VBoxContainer/ResumeButton
@onready var _quit_button: Button = $Panel/VBoxContainer/QuitButton
@onready var _save1_button: Button = $Panel/VBoxContainer/SaveSlot1
@onready var _save2_button: Button = $Panel/VBoxContainer/SaveSlot2
@onready var _save3_button: Button = $Panel/VBoxContainer/SaveSlot3
@onready var _load1_button: Button = $Panel/VBoxContainer/LoadSlot1
@onready var _load2_button: Button = $Panel/VBoxContainer/LoadSlot2
@onready var _load3_button: Button = $Panel/VBoxContainer/LoadSlot3

func _ready() -> void:
    visible = false
    _resume_button.pressed.connect(_on_resume_pressed)
    _quit_button.pressed.connect(_on_quit_pressed)
    _master_slider.value_changed.connect(_on_slider_value_changed)
    _music_slider.value_changed.connect(_on_slider_value_changed)
    _sfx_slider.value_changed.connect(_on_slider_value_changed)
    _colorblind_option.clear()
    _colorblind_option.add_item("None", 0)
    _colorblind_option.add_item("Deuteranopia", 1)
    _colorblind_option.add_item("Protanopia", 2)
    _colorblind_option.add_item("Tritanopia", 3)
    _colorblind_option.item_selected.connect(func(_index): _on_settings_changed())
    _save1_button.pressed.connect(func(): _on_save_pressed(0))
    _save2_button.pressed.connect(func(): _on_save_pressed(1))
    _save3_button.pressed.connect(func(): _on_save_pressed(2))
    _load1_button.pressed.connect(func(): _on_load_pressed(0))
    _load2_button.pressed.connect(func(): _on_load_pressed(1))
    _load3_button.pressed.connect(func(): _on_load_pressed(2))

func show_pause() -> void:
    visible = true

func _on_resume_pressed() -> void:
    emit_signal("resume_requested")

func _on_quit_pressed() -> void:
    emit_signal("quit_requested")

func _on_settings_changed() -> void:
    var settings := {
        "audio": {
            "master": _master_slider.value,
            "music": _music_slider.value,
            "sfx": _sfx_slider.value
        },
        "accessibility": {
            "colorblind": _colorblind_option.get_selected_id()
        }
    }
    emit_signal("settings_changed", settings)

func _on_slider_value_changed(_value: float) -> void:
    _on_settings_changed()

func _on_save_pressed(slot: int) -> void:
    SaveManager.save(slot)
    _status_label.text = "Saved to slot %d" % slot

func _on_load_pressed(slot: int) -> void:
    SaveManager.load(slot)
    _status_label.text = "Loaded slot %d" % slot
