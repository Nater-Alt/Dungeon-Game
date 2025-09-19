## Procedurally builds and mutates the Gloamkeep dungeon layout.
extends Node

const MIN_ROOMS := 12
const MAX_ROOMS := 18
const ROOM_ARCHETYPES := [
    "Antechamber",
    "Fungal Grove",
    "Mechanist Hall",
    "Catacombs",
    "Puzzle Lock",
    "Refuge",
    "Sanctum"
]
const EXTRA_ARCHETYPES := [
    "Archive",
    "Collapsed Way",
    "Watch Post",
    "Sluice",
    "Shrine"
]
const CONNECTOR_TYPES := ["door", "crawlspace", "rope_shaft"]
const LOCK_COUNT := 2

signal dungeon_ready(layout)
signal corridors_shifted(changes)

var _rng := RandomNumberGenerator.new()
var _rooms: Dictionary = {}
var _corridors: Array = []
var _current_seed := 0

func _ready() -> void:
    GameState.connect("eclipse_tick", Callable(self, "_on_eclipse_tick"))

func generate(new_seed: int) -> void:
    _current_seed = new_seed
    _rng.seed = new_seed
    _rooms.clear()
    _corridors.clear()
    _create_rooms()
    _connect_rooms()
    _ensure_loops_and_shortcuts()
    _place_puzzles()
    _place_keys_and_locks()
    emit_signal("dungeon_ready", capture_state())

func capture_state() -> Dictionary:
    var room_copy := {}
    for id in _rooms.keys():
        var room := _rooms[id]
        room_copy[id] = {
            "id": id,
            "archetype": room["archetype"],
            "position": [room["position"].x, room["position"].y],
            "items": room["items"],
            "puzzles": room["puzzles"]
        }
    var corridor_copy := []
    for corridor in _corridors:
        corridor_copy.append(corridor.duplicate(true))
    return {
        "seed": _current_seed,
        "rooms": room_copy,
        "corridors": corridor_copy
    }

func restore_state(state: Dictionary) -> void:
    _current_seed = state.get("seed", 0)
    _rooms.clear()
    var stored_rooms := state.get("rooms", {})
    for id in stored_rooms.keys():
        var room := stored_rooms[id]
        var stored_pos := room.get("position", [0, 0])
        var pos := stored_pos is Array and stored_pos.size() >= 2 ? Vector2(stored_pos[0], stored_pos[1]) : stored_pos
        _rooms[id] = {
            "id": id,
            "archetype": room.get("archetype", "Unknown"),
            "position": pos,
            "connectors": [],
            "items": room.get("items", []),
            "puzzles": room.get("puzzles", [])
        }
    _corridors = state.get("corridors", []).duplicate(true)
    for corridor in _corridors:
        if not _rooms.has(corridor["from"]):
            continue
        if not _rooms.has(corridor["to"]):
            continue
        _rooms[corridor["from"]]["connectors"].append(corridor)
        _rooms[corridor["to"]]["connectors"].append(corridor)
    emit_signal("dungeon_ready", capture_state())

func get_room(id: String) -> Dictionary:
    return _rooms.get(id, {})

func get_corridors() -> Array:
    return _corridors

func _create_rooms() -> void:
    var required := ROOM_ARCHETYPES.duplicate()
    var count := _rng.randi_range(MIN_ROOMS, MAX_ROOMS)
    while required.size() < count:
        required.append(EXTRA_ARCHETYPES[_rng.randi_range(0, EXTRA_ARCHETYPES.size() - 1)])
    required.shuffle()
    for index in range(count):
        var id := "R%02d" % index
        var archetype := required[index]
        _rooms[id] = {
            "id": id,
            "archetype": archetype,
            "position": Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)) * 480.0,
            "connectors": [],
            "items": [],
            "puzzles": []
        }

func _connect_rooms() -> void:
    var ids := _rooms.keys()
    ids.sort()
    var previous := ids[0]
    for i in range(1, ids.size()):
        var current := ids[i]
        _add_corridor(previous, current, false)
        previous = current

func _ensure_loops_and_shortcuts() -> void:
    var ids := _rooms.keys()
    ids.shuffle()
    for i in range(2):
        var a := ids[i]
        var b := ids[(i + 3) % ids.size()]
        _add_corridor(a, b, true)
    for i in range(2):
        var a := ids[(i + 5) % ids.size()]
        var b := ids[(i + 7) % ids.size()]
        _add_corridor(a, b, true)

func _place_puzzles() -> void:
    var archetype_map := {}
    for room in _rooms.values():
        archetype_map[room["archetype"]] = room
    if archetype_map.has("Mechanist Hall"):
        archetype_map["Mechanist Hall"]["puzzles"].append({
            "type": "light_angle",
            "state": {"mirrors": [0, 90, 180], "goal": 45}
        })
    if archetype_map.has("Puzzle Lock"):
        archetype_map["Puzzle Lock"]["puzzles"].append({
            "type": "rune_circuit",
            "state": {"runes": [0, 1, 2, 3], "solution": [1, 3, 0, 2]}
        })
    if archetype_map.has("Antechamber"):
        archetype_map["Antechamber"]["puzzles"].append({
            "type": "lever_bridge",
            "state": {"timer": 12.0, "bridges": 2}
        })

func _place_keys_and_locks() -> void:
    if _corridors.size() == 0:
        return
    var attempts := 0
    var locked := 0
    while locked < LOCK_COUNT and attempts < 20:
        attempts += 1
        var corridor := _corridors[_rng.randi_range(0, _corridors.size() - 1)]
        if corridor.get("locked", false):
            continue
        var origin := corridor["from"]
        var destination := corridor["to"]
        var accessible := _flood_reach(origin, [])
        if not accessible.has(destination):
            continue
        if accessible.is_empty():
            continue
        var key_room := accessible[_rng.randi_range(0, accessible.size() - 1)]
        var key_id := "key_%d" % locked
        corridor["locked"] = true
        corridor["key"] = key_id
        _rooms[key_room]["items"].append({"type": "key", "id": key_id})
        locked += 1

func _add_corridor(from_id: String, to_id: String, dynamic: bool) -> void:
    if from_id == to_id:
        return
    if _has_connection(from_id, to_id):
        return
    var connector_type := CONNECTOR_TYPES[_rng.randi_range(0, CONNECTOR_TYPES.size() - 1)]
    var corridor := {
        "from": from_id,
        "to": to_id,
        "type": connector_type,
        "dynamic": dynamic,
        "locked": false,
        "key": ""
    }
    _corridors.append(corridor)
    _rooms[from_id]["connectors"].append(corridor)
    _rooms[to_id]["connectors"].append(corridor)

func _has_connection(a: String, b: String) -> bool:
    for corridor in _corridors:
        if (corridor["from"] == a and corridor["to"] == b) or (corridor["from"] == b and corridor["to"] == a):
            return true
    return false

func _flood_reach(start: String, ignore_keys: Array) -> Array:
    var visited := {}
    var frontier := [start]
    while frontier.size() > 0:
        var current := frontier.pop_front()
        if visited.has(current):
            continue
        visited[current] = true
        for corridor in _rooms[current]["connectors"]:
            if corridor.get("locked", false) and not ignore_keys.has(corridor.get("key", "")):
                continue
            var target := corridor["from"] == current ? corridor["to"] : corridor["from"]
            if not visited.has(target):
                frontier.append(target)
    return visited.keys()

func _on_eclipse_tick(value: int) -> void:
    if value in [8, 4]:
        _shift_dynamic_corridors()

func _shift_dynamic_corridors() -> void:
    var dynamic_corridors := []
    for corridor in _corridors:
        if corridor.get("dynamic", false):
            dynamic_corridors.append(corridor)
    if dynamic_corridors.is_empty():
        return
    dynamic_corridors.shuffle()
    var updates := []
    for corridor in dynamic_corridors:
        var options := _rooms.keys()
        options.shuffle()
        for candidate in options:
            if candidate in [corridor["from"], corridor["to"]]:
                continue
            if not _has_connection(corridor["from"], candidate):
                corridor["to"] = candidate
                updates.append({"from": corridor["from"], "to": candidate})
                break
    emit_signal("corridors_shifted", updates)

