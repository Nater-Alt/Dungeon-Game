## Provides access to hot-reloadable configuration stored in config/game.json.
extends Node

const CONFIG_RELATIVE_PATH := "res://../config/game.json"
const CHECK_INTERVAL := 1.5

signal config_changed(data)

var _config := {}
var _last_modified := 0
var _timer := 0.0

func _ready() -> void:
    load_config()
    set_process(true)

func _process(delta: float) -> void:
    _timer += delta
    if _timer < CHECK_INTERVAL:
        return
    _timer = 0.0
    var modified := _get_file_modified_time()
    if modified != 0 and modified != _last_modified:
        load_config()

func load_config() -> void:
    var path := ProjectSettings.globalize_path(CONFIG_RELATIVE_PATH)
    var file := FileAccess.open(path, FileAccess.READ)
    if file:
        var text := file.get_as_text()
        file.close()
        var data := JSON.parse_string(text)
        if typeof(data) == TYPE_DICTIONARY:
            _config = data
            _last_modified = _get_file_modified_time()
            emit_signal("config_changed", _config)
            return
    _config = {
        "difficulty": "normal",
        "light_radius": 320.0,
        "enemy_density": 0.75,
        "drop_rates": {},
        "stretch_goals": {}
    }
    emit_signal("config_changed", _config)

func get_value(path: String, default_value: Variant = null) -> Variant:
    var keys := path.split(".")
    var cursor: Variant = _config
    for key in keys:
        if typeof(cursor) != TYPE_DICTIONARY or not cursor.has(key):
            return default_value
        cursor = cursor[key]
    return cursor

func _get_file_modified_time() -> int:
    var path := ProjectSettings.globalize_path(CONFIG_RELATIVE_PATH)
    if FileAccess.file_exists(path):
        return FileAccess.get_modified_time(path)
    return 0
