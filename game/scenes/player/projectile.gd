## Base projectile that handles movement, collisions, pooling, and light emission.
extends Area2D

@export var speed := 420.0
@export var damage := 20
@export var light_power := 0.0

var _direction := Vector2.ZERO
var _lifetime := 4.0

func _ready() -> void:
    add_to_group("projectile")
    set_physics_process(false)
    connect("body_entered", Callable(self, "_on_body_entered"))

func launch(direction: Vector2) -> void:
    _direction = direction
    set_physics_process(true)
    _lifetime = 4.0

func _physics_process(delta: float) -> void:
    position += _direction * speed * delta
    _lifetime -= delta
    if _lifetime <= 0.0:
        queue_free()

func _on_body_entered(body: Node) -> void:
    if body.has_method("receive_attack"):
        body.receive_attack(damage)
    queue_free()
