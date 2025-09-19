## Persists and restores run data using JSON slots stored under user://saves.
extends Node

const SAVE_DIR := "user://saves"
const SLOT_COUNT := 3

signal save_completed(success, slot)
signal load_completed(success, slot)

func save(slot: int) -> void:
    if slot < 0 or slot >= SLOT_COUNT:
        emit_signal("save_completed", false, slot)
        return
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))
    var path := "%s/slot_%d.json" % [SAVE_DIR, slot]
    var file := FileAccess.open(path, FileAccess.WRITE)
    if not file:
        emit_signal("save_completed", false, slot)
        return
    var payload := {
        "timestamp": Time.get_datetime_dict_from_system(),
        "game_state": GameState.capture_state(),
        "dungeon": DungeonGenerator.capture_state(),
        "player": _capture_player()
    }
    file.store_string(JSON.stringify(payload, "  "))
    file.close()
    emit_signal("save_completed", true, slot)

func load(slot: int) -> void:
    var path := "%s/slot_%d.json" % [SAVE_DIR, slot]
    if not FileAccess.file_exists(path):
        emit_signal("load_completed", false, slot)
        return
    var file := FileAccess.open(path, FileAccess.READ)
    if not file:
        emit_signal("load_completed", false, slot)
        return
    var payload := JSON.parse_string(file.get_as_text())
    file.close()
    if typeof(payload) != TYPE_DICTIONARY:
        emit_signal("load_completed", false, slot)
        return
    GameState.restore_state(payload.get("game_state", {}))
    DungeonGenerator.restore_state(payload.get("dungeon", {}))
    _restore_player(payload.get("player", {}))
    emit_signal("load_completed", true, slot)

func list_saves() -> Array:
    var entries: Array = []
    for slot in range(SLOT_COUNT):
        var path := "%s/slot_%d.json" % [SAVE_DIR, slot]
        var exists := FileAccess.file_exists(path)
        var modified := exists ? FileAccess.get_modified_time(path) : 0
        entries.append({
            "slot": slot,
            "exists": exists,
            "modified": modified
        })
    return entries

func _capture_player() -> Dictionary:
    var players := get_tree().get_nodes_in_group("player")
    if players.size() > 0:
        return {"position": players[0].global_position}
    return {}

func _restore_player(data: Dictionary) -> void:
    var players := get_tree().get_nodes_in_group("player")
    if players.size() == 0:
        return
    var player := players[0]
    if data.has("position"):
        player.global_position = data["position"]
