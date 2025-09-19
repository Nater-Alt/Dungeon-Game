## Collectible items that integrate with the inventory and puzzle logic.
extends Area2D

@onready var _sprite: Sprite2D = $Sprite2D

var _data: Dictionary = {}

func _ready() -> void:
    add_to_group("interactable")

func configure(data: Dictionary) -> void:
    _data = data
    var color := Color(0.8, 0.7, 0.4)
    match data.get("type", ""):
        "key": color = Color(0.95, 0.85, 0.3)
        "ration": color = Color(0.6, 0.85, 0.6)
        "flare": color = Color(0.9, 0.35, 0.35)
    _sprite.modulate = color

func is_interactable() -> bool:
    return true

func on_interact(_player: Node) -> void:
    var item_type := _data.get("type", "")
    match item_type:
        "key":
            GameState.add_item("keys", 1)
        "ration":
            GameState.add_item("rations", 1)
        "flare":
            GameState.add_item("flares", 1)
        _:
            GameState.add_item(item_type, 1)
    queue_free()
