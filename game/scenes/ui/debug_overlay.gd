## Developer overlay showing performance metrics and AI state summaries.
extends Control

@onready var _label: Label = $Panel/Label
@onready var _timer: Timer = $Timer

var _noise_data: Array = []

func _ready() -> void:
    visible = false
    _timer.connect("timeout", Callable(self, "_on_tick"))
    _timer.start(0.5)

func show_noise(noise: Array) -> void:
    _noise_data = noise

func _on_tick() -> void:
    if not visible:
        return
    var fps := Engine.get_frames_per_second()
    var stats := "FPS: %.1f\n" % fps
    stats += "Draw Calls: %d\n" % RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
    stats += "Enemies:\n"
    for enemy in get_tree().get_nodes_in_group("enemy"):
        if enemy.has_method("get_state_name"):
            stats += " - %s: %s\n" % [enemy.name, enemy.get_state_name()]
    stats += "Noise: %d markers\n" % _noise_data.size()
    _label.text = stats
