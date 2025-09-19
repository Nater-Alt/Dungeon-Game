## Heads-up display for stats, inventory, captions, and eclipse updates.
extends Control

@onready var _hp_bar: ProgressBar = $MarginContainer/VBoxContainer/HBoxStats/HP
@onready var _sta_bar: ProgressBar = $MarginContainer/VBoxContainer/HBoxStats/STA
@onready var _lgt_bar: ProgressBar = $MarginContainer/VBoxContainer/HBoxStats/LGT
@onready var _caption_label: Label = $CaptionPanel/CaptionLabel
@onready var _eclipse_label: Label = $MarginContainer/VBoxContainer/EclipseLabel
@onready var _inventory_label: Label = $MarginContainer/VBoxContainer/InventoryLabel
@onready var _message_label: Label = $MessagePanel/MessageLabel
@onready var _caption_timer: Timer = $CaptionTimer

func _ready() -> void:
    GameState.connect("stats_changed", Callable(self, "_on_stats_changed"))
    GameState.connect("inventory_changed", Callable(self, "_on_inventory_changed"))
    _caption_timer.connect("timeout", Callable(self, "_on_caption_timeout"))
    _on_stats_changed(GameState._collect_stats())
    _on_inventory_changed(GameState.inventory)

func _on_stats_changed(stats: Dictionary) -> void:
    _hp_bar.value = stats.get("hp", 0)
    _sta_bar.value = stats.get("sta", 0)
    _lgt_bar.value = stats.get("lgt", 0)
    _eclipse_label.text = "Eclipse: %d" % stats.get("eclipse", 0)

func _on_inventory_changed(inventory: Dictionary) -> void:
    var parts: Array[String] = []
    for key in inventory.keys():
        parts.append("%s:%d" % [key.left(3).to_upper(), inventory[key]])
    parts.sort()
    _inventory_label.text = "Inventory: " + ", ".join(parts)

func show_caption(text: String) -> void:
    _caption_label.text = text
    _caption_panel_visible(true)
    _caption_timer.start(2.0)

func update_eclipse(value: int) -> void:
    _eclipse_label.text = "Eclipse: %d" % value

func announce_shift(changes: Array) -> void:
    if changes.is_empty():
        return
    _message_label.text = "Corridors shifted!"

func show_game_over(reason: String) -> void:
    _message_label.text = reason

func refresh_bindings(_controls: Dictionary) -> void:
    pass

func _on_caption_timeout() -> void:
    _caption_panel_visible(false)

func _caption_panel_visible(state: bool) -> void:
    $CaptionPanel.visible = state
