## Eclipse Warden miniboss with two phases reacting to the global timer.
extends "res://scenes/enemies/enemy_base.gd"

var _hp := 180
var _phase := 1
var _phase_timer := 0.0

func _ready() -> void:
    faction = "Lantern-Bearer"
    vision_range = 400.0
    vision_angle = 90.0
    hearing_radius = 300.0
    move_speed = 120.0
    attack_damage = 28
    attack_cooldown = 1.2
    super._ready()
    GameState.connect("eclipse_tick", Callable(self, "_on_eclipse_tick"))

func _physics_process(delta: float) -> void:
    _phase_timer += delta
    if _phase == 2 and _phase_timer > 5.0:
        _phase_timer = 0.0
        _emit_shadow_wave()
    super._physics_process(delta)

func receive_attack(damage: int) -> void:
    _hp -= damage
    if _hp <= 90 and _phase == 1:
        _transition_phase_two()
    if _hp <= 0:
        queue_free()

func _attempt_attack(player: Node) -> void:
    if _phase == 2:
        attack_damage = 36
    super._attempt_attack(player)

func _transition_phase_two() -> void:
    _phase = 2
    attack_cooldown = 0.9
    move_speed = 150.0
    AudioManager.trigger_stinger("eclipse")

func _emit_shadow_wave() -> void:
    var bolt := preload("res://scenes/enemies/shadow_bolt.tscn").instantiate()
    bolt.global_position = global_position
    bolt.call("launch", Vector2.RIGHT.rotated(randf() * TAU))
    get_tree().get_current_scene().add_child(bolt)

func _on_eclipse_tick(value: int) -> void:
    if value <= 4:
        _phase = 2
