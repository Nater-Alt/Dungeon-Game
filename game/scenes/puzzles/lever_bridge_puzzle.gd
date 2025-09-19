## Timed lever puzzle that opens bridges briefly, challenging sprint management.
extends Node2D

@onready var _timer: Timer = $Timer
@onready var _bridge_container: Node2D = $Bridges

var _duration := 10.0
var _bridge_count := 2
var _active := false

func _ready() -> void:
    _timer.connect("timeout", Callable(self, "_on_timeout"))

func configure(data: Dictionary) -> void:
    _duration = data.get("state", {}).get("timer", 10.0)
    _bridge_count = data.get("state", {}).get("bridges", 2)
    _spawn_bridges()

func is_interactable() -> bool:
    return true

func on_interact(_player: Node) -> void:
    _active = true
    _timer.start(_duration)
    _set_bridge_visibility(true)

func _spawn_bridges() -> void:
    for child in _bridge_container.get_children():
        child.queue_free()
    for i in range(_bridge_count):
        var rect := ColorRect.new()
        rect.size = Vector2(40, 6)
        rect.position = Vector2(-20 + i * 44, -3)
        rect.color = Color(0.3, 0.6, 0.9, 0.9)
        _bridge_container.add_child(rect)
    _set_bridge_visibility(false)

func _set_bridge_visibility(visible: bool) -> void:
    for bridge in _bridge_container.get_children():
        bridge.visible = visible

func _on_timeout() -> void:
    _active = false
    _set_bridge_visibility(false)
    GameState.clues.append("Bridges respond swiftly")
