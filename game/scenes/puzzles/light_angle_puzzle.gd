## Mirror rotation puzzle where players align beams to unlock a path.
extends Node2D

var _angles: Array = []
var _goal := 45
var _solved := false

func configure(data: Dictionary) -> void:
    _angles = data.get("state", {}).get("mirrors", [0, 90, 180])
    _goal = data.get("state", {}).get("goal", 45)
    _update_visuals()

func is_interactable() -> bool:
    return not _solved

func on_interact(_player: Node) -> void:
    if _solved:
        return
    for i in range(_angles.size()):
        _angles[i] = int((_angles[i] + 45) % 360)
        if _check_solution():
            break
    _update_visuals()
    if _check_solution():
        _solved = true
        GameState.clues.append("Light follows intention")

func _check_solution() -> bool:
    var sum := 0
    for angle in _angles:
        sum += angle
    return int(sum / _angles.size()) == _goal

func _update_visuals() -> void:
    for i in range(_angles.size()):
        var mirror := get_node_or_null("Mirror" + str(i + 1))
        if mirror:
            mirror.rotation_degrees = _angles[i]
