## Coordinates scene loading, dungeon generation, fog-of-war, and eclipse events.
extends Node2D

const MAX_NOISE_MARKERS := 8

@onready var _world_root: Node2D = $WorldRoot
@onready var _player_container: Node2D = $WorldRoot/PlayerContainer
@onready var _light_group: Node2D = $WorldRoot/LightGroup
@onready var _camera: Camera2D = $WorldRoot/Camera2D
@onready var _hud: CanvasItem = $Effects/HUD
@onready var _pause_menu: Control = $Effects/PauseMenu
@onready var _debug_overlay: Control = $Effects/DebugOverlay
@onready var _fog_mask: ColorRect = $Effects/FogMask
@onready var _vignette: ColorRect = $Effects/Vignette
@onready var _eclipse_timer: Timer = $EclipseTimer

var _player_scene := preload("res://scenes/player/player.tscn")
var _room_scene := preload("res://scenes/props/room.tscn")
var _door_scene := preload("res://scenes/props/door.tscn")
var _torch_scene := preload("res://scenes/props/torch.tscn")
var _light_puzzle_scene := preload("res://scenes/puzzles/light_angle_puzzle.tscn")
var _rune_puzzle_scene := preload("res://scenes/puzzles/rune_circuit_puzzle.tscn")
var _lever_puzzle_scene := preload("res://scenes/puzzles/lever_bridge_puzzle.tscn")
var _enemy_scenes := {
    "lantern_patroller": preload("res://scenes/enemies/lantern_patroller.tscn"),
    "silent_ambusher": preload("res://scenes/enemies/silent_ambusher.tscn"),
    "gloom_caster": preload("res://scenes/enemies/gloom_caster.tscn"),
    "miniboss": preload("res://scenes/enemies/eclipse_warden.tscn")
}

var _current_layout: Dictionary = {}
var _player: Node2D
var _noise_markers: Array = []
var _reveal_points: Array[Vector2] = []

func _ready() -> void:
    _pause_menu.connect("resume_requested", Callable(self, "_on_resume_requested"))
    _pause_menu.connect("quit_requested", Callable(self, "_on_quit_requested"))
    _pause_menu.connect("settings_changed", Callable(self, "_on_settings_changed"))
    _debug_overlay.visible = false
    AudioManager.connect("caption_emitted", Callable(_hud, "show_caption"))
    DungeonGenerator.connect("dungeon_ready", Callable(self, "_on_dungeon_ready"))
    DungeonGenerator.connect("corridors_shifted", Callable(self, "_on_corridors_shifted"))
    GameState.connect("room_discovered", Callable(self, "_on_room_discovered"))
    GameState.connect("eclipse_tick", Callable(self, "_on_eclipse_tick"))
    GameState.connect("stats_changed", Callable(self, "_on_stats_update"))
    _hud.set_process(false)
    _eclipse_timer.connect("timeout", Callable(self, "_on_eclipse_timeout"))
    _start_new_run()

func _start_new_run() -> void:
    randomize()
    var seed := int(Time.get_ticks_msec()) % int(1e9)
    if ConfigService.get_value("stretch_goals.enable_daily_seed", false):
        var date := Time.get_date_dict_from_system()
        seed = int("%04d%02d%02d" % [date.year, date.month, date.day])
    GameState.initialize_run(seed)
    DungeonGenerator.generate(seed)
    _spawn_player()
    _eclipse_timer.wait_time = 75.0
    _eclipse_timer.start()

func _spawn_player() -> void:
    if _player:
        _player.queue_free()
    _player = _player_scene.instantiate()
    _player_container.add_child(_player)
    _camera.set_follow_smoothing(0.15)
    _camera.reparent(_player)
    _camera.position = Vector2.ZERO
    _fog_mask.call("set_camera", _camera)
    if _current_layout.size() > 0:
        _place_enemies()

func _on_dungeon_ready(layout: Dictionary) -> void:
    _current_layout = layout
    _normalize_layout(_current_layout)
    for child in _world_root.get_children():
        if child != _player_container and child != _light_group and child != _camera:
            child.queue_free()
    _reveal_points.clear()
    for room_data in layout.get("rooms", {}).values():
        var room := _room_scene.instantiate()
        _world_root.add_child(room)
        room.global_position = room_data["position"]
        room.call("configure", room_data)
        if room_data["puzzles"].size() > 0:
            for puzzle in room_data["puzzles"]:
                _spawn_puzzle(room, puzzle)
        if room_data["items"].size() > 0:
            room.call("populate_items", room_data["items"])
    for corridor in layout.get("corridors", []):
        _spawn_corridor(corridor)
    _place_enemies()

func _spawn_puzzle(room: Node, data: Dictionary) -> void:
    var scene
    match data.get("type", ""):
        "light_angle": scene = _light_puzzle_scene
        "rune_circuit": scene = _rune_puzzle_scene
        "lever_bridge": scene = _lever_puzzle_scene
        _:
            return
    if scene:
        var instance := scene.instantiate()
        room.add_child(instance)
        instance.call("configure", data)

func _spawn_corridor(data: Dictionary) -> void:
    var door := _door_scene.instantiate()
    _world_root.add_child(door)
    door.call("configure", data, _rooms_to_world(data["from"]), _rooms_to_world(data["to"]))

func _rooms_to_world(room_id: String) -> Vector2:
    return _current_layout.get("rooms", {}).get(room_id, {}).get("position", Vector2.ZERO)

func _place_enemies() -> void:
    if not _player:
        return
    for child in _player_container.get_parent().get_children():
        if child.is_in_group("enemy"):
            child.queue_free()
    var rooms := _current_layout.get("rooms", {})
    var room_keys := rooms.keys()
    room_keys.shuffle()
    var enemy_list := [
        _enemy_scenes["lantern_patroller"],
        _enemy_scenes["silent_ambusher"],
        _enemy_scenes["gloom_caster"]
    ]
    var density := ConfigService.get_value("enemy_density", 0.75)
    var count := clamp(int(round(room_keys.size() * density * 0.5)), 3, 6)
    for i in range(min(room_keys.size(), count)):
        var room_id := room_keys[i]
        var room_pos := _rooms_to_world(room_id)
        var enemy_scene := enemy_list[i % enemy_list.size()]
        var enemy := enemy_scene.instantiate()
        enemy.global_position = room_pos + Vector2(_randf_range(-80, 80), _randf_range(-80, 80))
        _world_root.add_child(enemy)
    for room_id in rooms.keys():
        var data := rooms[room_id]
        if data.get("archetype") == "Sanctum":
            var boss := _enemy_scenes["miniboss"].instantiate()
            boss.global_position = _rooms_to_world(room_id)
            _world_root.add_child(boss)

func _on_room_discovered(room_id: String) -> void:
    var world_pos := _rooms_to_world(room_id)
    _reveal_points.append(world_pos)
    _fog_mask.call("update_revealed", _reveal_points)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("action_pause"):
        _toggle_pause()
    elif event.is_action_pressed("action_debug_overlay"):
        _debug_overlay.visible = not _debug_overlay.visible

func _toggle_pause() -> void:
    if get_tree().paused:
        _on_resume_requested()
    else:
        get_tree().paused = true
        _pause_menu.show_pause()

func _on_resume_requested() -> void:
    get_tree().paused = false
    _pause_menu.hide()

func _on_quit_requested() -> void:
    get_tree().quit()

func _on_settings_changed(settings: Dictionary) -> void:
    if settings.has("controls"):
        _hud.call("refresh_bindings", settings["controls"])
    if settings.has("audio"):
        var audio := settings["audio"]
        _set_bus("Master", audio.get("master", 0.8))
        _set_bus("Music", audio.get("music", 0.6))
        _set_bus("SFX", audio.get("sfx", 0.7))
    if settings.has("accessibility"):
        var cb := settings["accessibility"].get("colorblind", 0)
        _apply_colorblind_mode(cb)

func _on_eclipse_timeout() -> void:
    GameState.advance_eclipse()
    _eclipse_timer.start()

func _on_eclipse_tick(value: int) -> void:
    _hud.call("update_eclipse", value)
    if value <= 0:
        _hud.call("show_game_over", "Eclipse consumed Gloamkeep")

func _on_corridors_shifted(changes: Array) -> void:
    _hud.call("announce_shift", changes)
    AudioManager.trigger_stinger("eclipse")

func add_noise_marker(position: Vector2, intensity: float) -> void:
    _noise_markers.append({"pos": position, "intensity": intensity, "time": 2.5})
    while _noise_markers.size() > MAX_NOISE_MARKERS:
        _noise_markers.pop_front()
    _debug_overlay.call("show_noise", _noise_markers)
    get_tree().call_group("enemy", "register_noise", position, intensity)

func _randf_range(min_value: float, max_value: float) -> float:
    return randf() * (max_value - min_value) + min_value

func _normalize_layout(layout: Dictionary) -> void:
    var rooms := layout.get("rooms", {})
    for id in rooms.keys():
        var pos := rooms[id].get("position", Vector2.ZERO)
        if pos is Array:
            rooms[id]["position"] = Vector2(pos[0], pos[1])

func _set_bus(name: String, value: float) -> void:
    var index := AudioServer.get_bus_index(name)
    if index >= 0:
        AudioServer.set_bus_volume_db(index, linear_to_db(clamp(value, 0.0, 1.0)))

func _apply_colorblind_mode(mode: int) -> void:
    var material := _fog_mask.material as ShaderMaterial
    if not material:
        return
    match mode:
        1:
            material.set_shader_parameter("shadow_strength", 0.75)
        2:
            material.set_shader_parameter("shadow_strength", 0.8)
        3:
            material.set_shader_parameter("shadow_strength", 0.7)
        _:
            material.set_shader_parameter("shadow_strength", 0.85)

func _on_stats_update(stats: Dictionary) -> void:
    var material := _vignette.material as ShaderMaterial
    if not material:
        return
    var light_ratio := clamp(stats.get("lgt", 100) / 100.0, 0.0, 1.0)
    material.set_shader_parameter("intensity", 0.4 + (1.0 - light_ratio) * 0.6)
