## Represents a corridor connector with optional locks and occlusion.
extends Node2D

@onready var _area: Area2D = $Area2D
@onready var _sprite: ColorRect = $ColorRect

var _data: Dictionary = {}
var _open := false

func configure(data: Dictionary, from_pos: Vector2, to_pos: Vector2) -> void:
    _data = data
    global_position = (from_pos + to_pos) * 0.5
    var direction := (to_pos - from_pos).normalized()
    rotation = direction.angle()
    _sprite.color = data.get("locked", false) ? Color(0.6, 0.2, 0.2) : Color(0.4, 0.4, 0.45)
    _area.connect("body_entered", Callable(self, "_on_body_entered"))

func is_interactable() -> bool:
    return true

func on_interact(_player: Node) -> void:
    if _open:
        return
    if _data.get("locked", false):
        if GameState.consume_item("keys", 1):
            _data["locked"] = false
            _sprite.color = Color(0.35, 0.6, 0.4)
            _open = true
        else:
            AudioManager.trigger_stinger("detection")
            return
    else:
        _open = true
    queue_free()

func _on_body_entered(body: Node) -> void:
    if body.is_in_group("player") and _data.get("locked", false):
        AudioManager.trigger_stinger("detection")
