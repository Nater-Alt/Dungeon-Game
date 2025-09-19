## Updates the fog-of-war shader with player vision and explored rooms.
extends ColorRect

const MAX_POINTS := 32

var _camera: Camera2D
var _revealed: Array[Vector2] = []

func _ready() -> void:
    set_process(true)

func set_camera(camera: Camera2D) -> void:
    _camera = camera

func update_revealed(points: Array) -> void:
    _revealed = points.duplicate()

func _process(_delta: float) -> void:
    if not material or not _camera:
        return
    var shader := material as ShaderMaterial
    var viewport_size := get_viewport_rect().size
    var camera_pos := _camera.global_position
    var player_pos := _camera.get_parent().global_position
    var screen_pos := (player_pos - camera_pos) + viewport_size * 0.5
    shader.set_shader_parameter("player_pos", screen_pos / viewport_size)
    var radius_world := ConfigService.get_value("light_radius", 320.0)
    shader.set_shader_parameter("light_radius", radius_world / max(viewport_size.x, viewport_size.y))
    var points := PackedVector2Array()
    var count := min(_revealed.size(), MAX_POINTS)
    for i in range(count):
        var world_pos: Vector2 = _revealed[i]
        var projected := (world_pos - camera_pos) + viewport_size * 0.5
        points.append(projected / viewport_size)
    shader.set_shader_parameter("revealed_points", points)
    shader.set_shader_parameter("revealed_count", count)
