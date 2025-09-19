## Handles ambient layering, procedural sound cues, and accessibility captions.
extends Node

const AMBIENT_LAYERS := {
    "wind": {"frequency": 220.0, "volume_db": -12.0},
    "drip": {"frequency": 440.0, "volume_db": -18.0},
    "chains": {"frequency": 110.0, "volume_db": -16.0}
}

signal caption_emitted(text)

var _playbacks := {}
var _low_pass_effect: AudioEffectLowPassFilter
var _caption_queue: Array[String] = []
var _caption_timer := 0.0

func _ready() -> void:
    _install_low_pass()
    for name in AMBIENT_LAYERS.keys():
        _create_layer_player(name, AMBIENT_LAYERS[name])
    set_process(true)

func _process(delta: float) -> void:
    for name in _playbacks.keys():
        var playback: AudioStreamGeneratorPlayback = _playbacks[name]
        if playback.get_frames_available() > 512:
            _fill_hum_wave(playback, AMBIENT_LAYERS[name]["frequency"])
    if _caption_queue.size() > 0:
        _caption_timer -= delta
        if _caption_timer <= 0.0:
            var caption := _caption_queue.pop_front()
            emit_signal("caption_emitted", caption)
            if _caption_queue.size() > 0:
                _caption_timer = 1.5

func trigger_stinger(type: String) -> void:
    var freq := match type:
        "detection": 880.0
        "parry": 1320.0
        "eclipse": 256.0
        _:
            660.0
    _spawn_one_shot(freq, -6.0)
    _caption_queue.append(type.capitalize() + " stinger")
    if _caption_queue.size() == 1:
        _caption_timer = 0.1

func play_footstep(intensity: float, surface: String) -> void:
    var base_freq := 220.0
    match surface:
        "stone": base_freq = 180.0
        "metal": base_freq = 360.0
        "fungus": base_freq = 140.0
    _spawn_one_shot(base_freq + intensity * 90.0, -8.0 + intensity * 4.0)

func update_crouch_filter(enabled: bool) -> void:
    if not _low_pass_effect:
        return
    _low_pass_effect.cutoff_hz = enabled ? 1200.0 : 8500.0

func _install_low_pass() -> void:
    var master := AudioServer.get_bus_index("Master")
    _low_pass_effect = AudioEffectLowPassFilter.new()
    _low_pass_effect.cutoff_hz = 8500.0
    _low_pass_effect.resonance = 0.7
    AudioServer.add_bus_effect(master, _low_pass_effect, 0)

func _create_layer_player(name: String, data: Dictionary) -> void:
    var player := AudioStreamPlayer.new()
    player.name = name.capitalize() + "Layer"
    player.volume_db = data.get("volume_db", -12.0)
    var stream := AudioStreamGenerator.new()
    stream.mix_rate = 44100
    stream.buffer_length = 0.5
    player.stream = stream
    add_child(player)
    player.play()
    var playback := player.get_stream_playback() as AudioStreamGeneratorPlayback
    _playbacks[name] = playback
    _fill_hum_wave(playback, data["frequency"])

func _fill_hum_wave(playback: AudioStreamGeneratorPlayback, frequency: float) -> void:
    var mix_rate := playback.get_stream().mix_rate
    for i in range(128):
        var t := float(i) / mix_rate
        var sample := sin(TAU * frequency * t) * 0.15 + sin(TAU * frequency * 0.5 * t) * 0.05
        playback.push_frame(Vector2(sample, sample))

func _spawn_one_shot(frequency: float, volume_db: float) -> void:
    var player := AudioStreamPlayer.new()
    var stream := AudioStreamGenerator.new()
    stream.mix_rate = 44100
    stream.buffer_length = 0.25
    player.stream = stream
    player.volume_db = volume_db
    add_child(player)
    player.finished.connect(player.queue_free)
    player.play()
    var playback := player.get_stream_playback() as AudioStreamGeneratorPlayback
    for i in range(256):
        var env := (1.0 - float(i) / 256.0)
        var t := float(i) / stream.mix_rate
        var sample := sin(TAU * frequency * t) * env
        playback.push_frame(Vector2(sample, sample))
