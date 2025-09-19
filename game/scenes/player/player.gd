## Handles player movement, stamina, stealth noise, combat actions, and interactions.
extends CharacterBody2D

const WALK_SPEED := 140.0
const SPRINT_SPEED := 230.0
const CROUCH_SPEED := 80.0
const NOISE_INTERVAL := 0.35
const BASE_DAMAGE := 25

@onready var _light: Light2D = $Light2D
@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _interact_area: Area2D = $InteractArea
@onready var _noise_timer: Timer = $NoiseTimer
@onready var _parry_timer: Timer = $ParryTimer
@onready var _dodge_timer: Timer = $DodgeTimer

var _is_crouched := false
var _is_sprinting := false
var _torch_enabled := true
var _current_interactable: Node
var _parry_window := false
var _iframe := false
var _noise_level := 0.0

var _flare_scene := preload("res://scenes/player/flare_projectile.tscn")
var _knife_scene := preload("res://scenes/player/knife_projectile.tscn")

func _ready() -> void:
    add_to_group("player")
    _interact_area.connect("area_entered", Callable(self, "_on_area_entered"))
    _interact_area.connect("area_exited", Callable(self, "_on_area_exited"))
    _noise_timer.wait_time = NOISE_INTERVAL
    _noise_timer.connect("timeout", Callable(self, "_emit_noise"))
    _noise_timer.start()

func _physics_process(delta: float) -> void:
    var input_vector := Vector2.ZERO
    input_vector.x = Input.get_action_strength("action_move_right") - Input.get_action_strength("action_move_left")
    input_vector.y = Input.get_action_strength("action_move_down") - Input.get_action_strength("action_move_up")
    if input_vector.length() > 1.0:
        input_vector = input_vector.normalized()
    _handle_stance()
    var target_speed := WALK_SPEED
    if _is_crouched:
        target_speed = CROUCH_SPEED
    if Input.is_action_pressed("action_sprint") and input_vector != Vector2.ZERO:
        if GameState.spend_stamina(18.0 * delta):
            target_speed = SPRINT_SPEED
            _is_sprinting = true
        else:
            _is_sprinting = false
    else:
        _is_sprinting = false
        GameState.recover_stamina(12.0 * delta)
    velocity = input_vector * target_speed
    if _dodge_timer.time_left > 0.0:
        velocity *= 1.5
    move_and_slide()
    _update_noise_level(input_vector.length(), delta)
    _update_light()

func _process(delta: float) -> void:
    if _torch_enabled:
        GameState.adjust_light(-delta * 0.3)
    else:
        GameState.adjust_light(-delta * 0.1)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("action_interact"):
        _interact()
    elif event.is_action_pressed("action_light"):
        _toggle_torch()
    elif event.is_action_pressed("action_use_item"):
        _use_consumable()
    elif event.is_action_pressed("action_drop_rope"):
        _drop_rope()
    elif event.is_action_pressed("action_throw"):
        _throw_projectile()
    elif event.is_action_pressed("action_dodge"):
        _perform_dodge()
    elif event.is_action_pressed("action_parry"):
        _open_parry_window()

func receive_attack(damage: int) -> void:
    if _iframe:
        return
    if _parry_window:
        AudioManager.trigger_stinger("parry")
        return
    GameState.apply_damage(damage)
    _camera_shake(4.0)

func heal(amount: int) -> void:
    GameState.heal(amount)

func _handle_stance() -> void:
    if Input.is_action_just_pressed("action_crouch"):
        _is_crouched = not _is_crouched
        _collision.scale = Vector2(1.0, _is_crouched ? 0.6 : 1.0)
        AudioManager.update_crouch_filter(_is_crouched)

func _update_noise_level(motion: float, delta: float) -> void:
    var target := 0.0
    if motion > 0.0:
        if _is_sprinting:
            target = 1.0
        elif _is_crouched:
            target = 0.2
        else:
            target = 0.6
    _noise_level = lerp(_noise_level, target, delta * 5.0)

func _emit_noise() -> void:
    if _noise_level <= 0.05:
        return
    var surface := "stone"
    AudioManager.play_footstep(_noise_level, surface)
    get_tree().get_current_scene().call_deferred("add_noise_marker", global_position, _noise_level)

func _update_light() -> void:
    var normalized := clamp(GameState.lgt / 100.0, 0.0, 1.0)
    _light.energy = 0.8 + normalized * 0.6
    _light.texture_scale = 1.0 + normalized * 0.25
    _light.visible = _torch_enabled

func _interact() -> void:
    if _current_interactable and _current_interactable.has_method("on_interact"):
        _current_interactable.on_interact(self)

func _toggle_torch() -> void:
    _torch_enabled = not _torch_enabled
    if _torch_enabled and GameState.lgt < 30.0:
        if GameState.consume_item("torches", 1):
            GameState.adjust_light(35.0)
        else:
            _torch_enabled = false

func _use_consumable() -> void:
    if GameState.consume_item("rations", 1):
        heal(20)
    elif GameState.consume_item("flares", 1):
        _throw_projectile(true)

func _drop_rope() -> void:
    if GameState.consume_item("rope", 1):
        var rope := Node2D.new()
        rope.name = "Rope"
        rope.position = global_position + Vector2(0, 24)
        get_tree().get_current_scene().add_child(rope)

func _throw_projectile(force_light := false) -> void:
    var dir := (get_global_mouse_position() - global_position).normalized()
    var scene := force_light ? _flare_scene : _knife_scene
    if force_light:
        pass
    elif GameState.consume_item("knives", 1):
        pass
    else:
        if GameState.consume_item("flares", 1):
            scene = _flare_scene
        else:
            return
    var projectile := scene.instantiate()
    projectile.global_position = global_position
    projectile.call("launch", dir)
    get_tree().get_current_scene().add_child(projectile)

func _perform_dodge() -> void:
    if _dodge_timer.time_left > 0.0:
        return
    _iframe = true
    _dodge_timer.start()
    await _dodge_timer.timeout
    _iframe = false

func _open_parry_window() -> void:
    if _parry_timer.time_left > 0.0:
        return
    _parry_window = true
    _parry_timer.start()
    await _parry_timer.timeout
    _parry_window = false

func _camera_shake(intensity: float) -> void:
    var camera := get_viewport().get_camera_2d()
    if camera:
        camera.add_trauma(intensity / 10.0)

func _on_area_entered(area: Area2D) -> void:
    if area.has_method("is_interactable"):
        _current_interactable = area
    elif area.get_parent() and area.get_parent().has_method("is_interactable"):
        _current_interactable = area.get_parent()

func _on_area_exited(area: Area2D) -> void:
    if _current_interactable == area or _current_interactable == area.get_parent():
        _current_interactable = null
