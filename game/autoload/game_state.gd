## Tracks run-wide data such as player stats, inventory, and eclipse progress.
extends Node

signal stats_changed(stats)
signal inventory_changed(inventory)
signal eclipse_tick(value)
signal room_discovered(id)

var hp := 100
var sta := 100
var lgt := 100
var eclipse_value := 12
var seed := 0
var discovered_rooms: Dictionary = {}
var inventory := {
    "torches": 3,
    "rope": 2,
    "rations": 2,
    "keys": 0,
    "flares": 2,
    "knives": 1
}
var clues: Array[String] = []

func initialize_run(new_seed: int) -> void:
    seed = new_seed
    var difficulty := ConfigService.get_value("difficulty", "normal")
    var hp_max := 100
    var sta_max := 100
    match difficulty:
        "easy":
            hp_max = 120
            sta_max = 120
        "hard":
            hp_max = 80
            sta_max = 90
    hp = hp_max
    sta = sta_max
    lgt = 100
    eclipse_value = 12
    discovered_rooms.clear()
    inventory = {
        "torches": 3,
        "rope": 2,
        "rations": 2,
        "keys": 0,
        "flares": 2,
        "knives": 1
    }
    clues.clear()
    emit_signal("stats_changed", _collect_stats())
    emit_signal("inventory_changed", inventory)

func apply_damage(amount: int) -> void:
    hp = max(0, hp - amount)
    emit_signal("stats_changed", _collect_stats())

func heal(amount: int) -> void:
    hp = min(100, hp + amount)
    emit_signal("stats_changed", _collect_stats())

func spend_stamina(amount: float) -> bool:
    if sta < amount:
        return false
    sta -= amount
    emit_signal("stats_changed", _collect_stats())
    return true

func recover_stamina(amount: float) -> void:
    sta = clamp(sta + amount, 0, 100)
    emit_signal("stats_changed", _collect_stats())

func adjust_light(amount: float) -> void:
    lgt = clamp(lgt + amount, 0, 100)
    emit_signal("stats_changed", _collect_stats())

func add_item(name: String, amount: int = 1) -> void:
    inventory[name] = inventory.get(name, 0) + amount
    emit_signal("inventory_changed", inventory)

func consume_item(name: String, amount: int = 1) -> bool:
    if inventory.get(name, 0) < amount:
        return false
    inventory[name] -= amount
    emit_signal("inventory_changed", inventory)
    return true

func register_room(id: String) -> void:
    if discovered_rooms.has(id):
        return
    discovered_rooms[id] = true
    emit_signal("room_discovered", id)

func advance_eclipse() -> void:
    if eclipse_value <= 0:
        return
    eclipse_value -= 1
    emit_signal("eclipse_tick", eclipse_value)

func capture_state() -> Dictionary:
    return {
        "hp": hp,
        "sta": sta,
        "lgt": lgt,
        "eclipse": eclipse_value,
        "seed": seed,
        "inventory": inventory.duplicate(true),
        "discovered_rooms": discovered_rooms.keys(),
        "clues": clues.duplicate()
    }

func restore_state(data: Dictionary) -> void:
    hp = data.get("hp", 100)
    sta = data.get("sta", 100)
    lgt = data.get("lgt", 100)
    eclipse_value = data.get("eclipse", 12)
    seed = data.get("seed", randi())
    inventory = data.get("inventory", {}).duplicate(true)
    discovered_rooms.clear()
    for id in data.get("discovered_rooms", []):
        discovered_rooms[id] = true
    clues = data.get("clues", [])
    emit_signal("stats_changed", _collect_stats())
    emit_signal("inventory_changed", inventory)
    emit_signal("eclipse_tick", eclipse_value)

func _collect_stats() -> Dictionary:
    return {
        "hp": hp,
        "sta": sta,
        "lgt": lgt,
        "eclipse": eclipse_value
    }
