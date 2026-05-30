@abstract class_name Plant extends Node

@export var stats: Stats
@onready var health_bar: HealthBar = %HealthBar

# Note: all plants must have a Sprite2D child
@onready var sprite: Sprite2D = $Sprite2D

## Make sure to call super._ready() in all subclasses!
func _ready():
	stats.level_changed.connect(_on_level_changed)
	sprite.frame = stats.level - 1
	health_bar.setup(stats)

func _on_level_changed(level: int) -> void:
	sprite.frame = level - 1

## The ability of the plant.
@abstract func ability()

func take_damage(amount: int):
	stats.health -= amount
