## Lantern-Bearer guard that patrols and reacts strongly to darkness.
extends "res://scenes/enemies/enemy_base.gd"

func _ready() -> void:
    faction = "Lantern-Bearer"
    vision_range = 360.0
    vision_angle = 75.0
    hearing_radius = 220.0
    move_speed = 110.0
    attack_damage = 20
    super._ready()
