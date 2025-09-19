## Generates simple geometry for a procedural room and tracks exploration state.
extends Node2D

const PICKUP_SCENE := preload("res://scenes/props/pickup_item.tscn")

@onready var _polygon: Polygon2D = $Polygon2D
@onready var _occluder: LightOccluder2D = $LightOccluder2D
@onready var _area: Area2D = $RoomArea
@onready var _label: Label = $RoomName

var _room_id := ""
var _archetype := ""

func _ready() -> void:
    _area.connect("body_entered", Callable(self, "_on_body_entered"))

func configure(data: Dictionary) -> void:
    _room_id = data.get("id", "?")
    _archetype = data.get("archetype", "Unknown")
    _label.text = _archetype
    _build_polygon(data.get("position", Vector2.ZERO))

func populate_items(items: Array) -> void:
    for entry in items:
        var item := PICKUP_SCENE.instantiate()
        add_child(item)
        item.position = Vector2(randf_range(-40, 40), randf_range(-40, 40))
        item.call("configure", entry)

func _build_polygon(_seed_position: Vector2) -> void:
    var width := randf_range(180.0, 260.0)
    var height := randf_range(140.0, 220.0)
    var points := PackedVector2Array([
        Vector2(-width * 0.5, -height * 0.5),
        Vector2(width * 0.5, -height * 0.5),
        Vector2(width * 0.5, height * 0.5),
        Vector2(-width * 0.5, height * 0.5)
    ])
    _polygon.polygon = points
    _polygon.color = Color(0.07, 0.09, 0.12).lerp(Color(0.21, 0.25, 0.28), randf())
    var occluder_polygon := OccluderPolygon2D.new()
    occluder_polygon.polygon = points
    _occluder.polygon = occluder_polygon
    var shape := RectangleShape2D.new()
    shape.size = Vector2(width, height)
    _area.get_node("CollisionShape2D").shape = shape

func _on_body_entered(body: Node) -> void:
    if body.is_in_group("player"):
        GameState.register_room(_room_id)
