## Environmental torch that can be toggled and affects local light level.
extends Node2D

@onready var _light: Light2D = $Light2D
@onready var _area: Area2D = $Area2D

var _lit := true

func _ready() -> void:
    _area.connect("body_entered", Callable(self, "_on_body_entered"))
    _area.connect("body_exited", Callable(self, "_on_body_exited"))

func is_interactable() -> bool:
    return true

func on_interact(_player: Node) -> void:
    _lit = not _lit
    _light.visible = _lit

func _on_body_entered(body: Node) -> void:
    if body.is_in_group("player"):
        AudioManager.trigger_stinger("detection")

func _on_body_exited(_body: Node) -> void:
    pass
