## Adds screen shake and smooth follow behaviour for the main camera.
extends Camera2D

var _trauma := 0.0
const TRAUMA_DECAY := 1.5
const MAX_SHAKE := 18.0

func _ready() -> void:
    set_process(true)

func _process(delta: float) -> void:
    if _trauma > 0.0:
        _trauma = max(_trauma - TRAUMA_DECAY * delta, 0.0)
        var shake := pow(_trauma, 2.0) * MAX_SHAKE
        var offset_vec := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake
        offset = offset_vec
    else:
        offset = offset.lerp(Vector2.ZERO, delta * 5.0)

func add_trauma(value: float) -> void:
    _trauma = clamp(_trauma + value, 0.0, 1.0)
