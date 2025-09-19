## Silent Order infiltrator relying on acute hearing and ambush tactics.
extends "res://scenes/enemies/enemy_base.gd"

func _ready() -> void:
    faction = "Silent Order"
    vision_range = 40.0
    vision_angle = 10.0
    hearing_radius = 320.0
    move_speed = 140.0
    attack_damage = 22
    super._ready()

func _generate_patrol() -> void:
    _patrol_points = [global_position]
