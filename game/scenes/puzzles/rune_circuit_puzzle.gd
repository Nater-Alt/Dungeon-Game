## Circuit puzzle requiring the player to match rune ordering by toggling plates.
extends Node2D

var _runes: Array = []
var _solution: Array = []
var _index := 0
var _solved := false

func configure(data: Dictionary) -> void:
    _runes = data.get("state", {}).get("runes", [0, 1, 2, 3])
    _solution = data.get("state", {}).get("solution", [1, 3, 0, 2])
    _update_labels()

func is_interactable() -> bool:
    return true

func on_interact(_player: Node) -> void:
    if _solved:
        return
    _index = (_index + 1) % _runes.size()
    _runes.rotate(1)
    _update_labels()
    if _runes == _solution:
        _solved = true
        GameState.clues.append("Rune order stabilized")

func _update_labels() -> void:
    for i in range(_runes.size()):
        var label := get_node("Rune" + str(i + 1)) as Label
        label.text = str(_runes[i])
