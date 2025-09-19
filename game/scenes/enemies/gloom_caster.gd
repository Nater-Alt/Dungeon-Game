## Ranged caster from the Silent Order who launches shadow bolts when alerted.
extends "res://scenes/enemies/enemy_base.gd"

const PROJECTILE_SCENE := preload("res://scenes/enemies/shadow_bolt.tscn")

var _cast_cooldown := 0.0

func _ready() -> void:
    faction = "Silent Order"
    vision_range = 280.0
    vision_angle = 45.0
    hearing_radius = 260.0
    move_speed = 90.0
    attack_damage = 12
    attack_cooldown = 2.2
    super._ready()

func _physics_process(delta: float) -> void:
    _cast_cooldown = max(0.0, _cast_cooldown - delta)
    super._physics_process(delta)
    if _state == State.PURSUE:
        var player := _get_player()
        if player and global_position.distance_to(player.global_position) > 120.0:
            _attempt_cast(player.global_position)

func _attempt_cast(target: Vector2) -> void:
    if _cast_cooldown > 0.0:
        return
    _cast_cooldown = 2.5
    var projectile := PROJECTILE_SCENE.instantiate()
    projectile.global_position = global_position
    projectile.call("launch", (target - global_position).normalized())
    get_tree().get_current_scene().add_child(projectile)
