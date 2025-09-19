## Base finite-state enemy with vision cones, hearing, and simple combat loops.
extends CharacterBody2D

enum State {IDLE, PATROL, INVESTIGATE, SEARCH, PURSUE, DISENGAGE}

@export var faction := "Lantern-Bearer"
@export var vision_range := 320.0
@export var vision_angle := 60.0
@export var hearing_radius := 260.0
@export var move_speed := 120.0
@export var attack_damage := 15
@export var attack_cooldown := 1.8

var _state := State.IDLE
var _patrol_points: Array[Vector2] = []
var _target_position := Vector2.ZERO
var _attack_timer := 0.0
var _search_timer := 0.0
var _last_known_player := Vector2.ZERO

func _ready() -> void:
    add_to_group("enemy")
    set_physics_process(true)
    _generate_patrol()

func _physics_process(delta: float) -> void:
    _attack_timer = max(0.0, _attack_timer - delta)
    match _state:
        State.IDLE:
            _try_detect_player()
            if _patrol_points.size() > 0:
                _state = State.PATROL
        State.PATROL:
            _move_towards(_patrol_points[0], delta)
            if global_position.distance_to(_patrol_points[0]) < 12.0:
                _patrol_points.rotate(1)
            _try_detect_player()
        State.INVESTIGATE, State.SEARCH:
            _move_towards(_target_position, delta)
            _search_timer -= delta
            if _search_timer <= 0.0:
                _state = State.IDLE
            _try_detect_player()
        State.PURSUE:
            var player := _get_player()
            if player:
                _last_known_player = player.global_position
                _move_towards(_last_known_player, delta, move_speed * 1.2)
                if global_position.distance_to(_last_known_player) < 30.0:
                    _attempt_attack(player)
            else:
                _state = State.DISENGAGE
        State.DISENGAGE:
            if _patrol_points.size() > 0:
                _move_towards(_patrol_points[0], delta)
                if global_position.distance_to(_patrol_points[0]) < 12.0:
                    _state = State.PATROL
            else:
                _state = State.IDLE

func receive_attack(damage: int) -> void:
    GameState.adjust_light(2.0)
    queue_free()

func register_noise(position: Vector2, intensity: float) -> void:
    if global_position.distance_to(position) > hearing_radius:
        return
    _target_position = position
    _state = State.INVESTIGATE
    _search_timer = clamp(intensity * 3.0, 1.0, 4.0)

func _try_detect_player() -> void:
    var player := _get_player()
    if not player:
        return
    if faction == "Silent Order":
        if global_position.distance_to(player.global_position) < hearing_radius * 0.6:
            _state = State.PURSUE
        return
    var to_player := player.global_position - global_position
    if to_player.length() > vision_range:
        return
    var angle := rad2deg(abs(wrapf(to_player.angle() - rotation, -PI, PI)))
    if angle > vision_angle:
        return
    var params := PhysicsRayQueryParameters2D.create(global_position, player.global_position)
    params.collide_with_bodies = true
    params.collide_with_areas = false
    params.collision_mask = 1
    var result := get_world_2d().direct_space_state.intersect_ray(params)
    if result.is_empty() or result["collider"] == player:
        _state = State.PURSUE
        AudioManager.trigger_stinger("detection")

func _move_towards(target: Vector2, delta: float, speed_override := -1.0) -> void:
    var dir := (target - global_position)
    if dir.length() < 1.0:
        velocity = Vector2.ZERO
    else:
        velocity = dir.normalized() * (speed_override > 0.0 ? speed_override : move_speed)
    move_and_slide()

func _attempt_attack(player: Node) -> void:
    if _attack_timer > 0.0:
        return
    _attack_timer = attack_cooldown
    if player.has_method("receive_attack"):
        player.receive_attack(attack_damage)

func _generate_patrol() -> void:
    for i in range(3):
        var angle := TAU * float(i) / 3.0
        _patrol_points.append(global_position + Vector2(cos(angle), sin(angle)) * 120.0)

func _get_player() -> Node:
    var players := get_tree().get_nodes_in_group("player")
    return players.size() > 0 ? players[0] : null

func get_state_name() -> String:
    match _state:
        State.IDLE:
            return "Idle"
        State.PATROL:
            return "Patrol"
        State.INVESTIGATE:
            return "Investigate"
        State.SEARCH:
            return "Search"
        State.PURSUE:
            return "Pursue"
        State.DISENGAGE:
            return "Disengage"
    return "Unknown"
