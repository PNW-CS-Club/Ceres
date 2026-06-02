@abstract class_name Plant extends Node

signal on_attacked(damage: int)

@export var stats: Stats
@onready var health_bar: HealthBar = %HealthBar

# Note: all plants must have a Sprite2D child
@onready var sprite: Sprite2D = $Sprite2D

var adj_plants: Array[Plant]

## Make sure to call super._ready() in all subclasses that override _ready!
func _ready():
	stats.level_changed.connect(_on_level_changed)
	stats.health_depleted.connect(_become_forgotten)
	sprite.frame = stats.level - 1
	health_bar.setup(stats)

func _on_level_changed(level: int) -> void:
	sprite.frame = level - 1



# Implement the following methods as needed in subclasses

## The ability of the plant that activates at the start of each dawn.
func ability_at_dawn() -> void: pass

## The ability of the plant that activates just before it is attacked.
func ability_on_attacked() -> void: pass



func register_adj(plant: Plant) -> void:
	adj_plants.append(plant)

func forget_adj(plant: Plant) -> void:
	adj_plants.erase(plant)
	# NOTE: this method must be called if a plant is removed for any reason!

func _become_forgotten() -> void:
	for plant in adj_plants:
		plant.forget_adj(self)

func receive_attack(damage: int): 
	var cover_left: int = 0
	var damage_left: int = damage
	
	for plant in adj_plants:
		cover_left += plant.stats.current_cover_provided
	
	for plant in adj_plants:
		if cover_left <= 0: break
		
		var multiplier: float = min(1.0, float(damage) / cover_left)
		var covered_damage = int(plant.stats.current_cover_provided * multiplier);
		
		if covered_damage > 0:
			plant.take_damage(covered_damage)
			cover_left -= covered_damage
			damage_left -= covered_damage
	
	if damage_left > 0:
		take_damage(damage_left)

func take_damage(health_loss: int) -> void:
	stats.health -= health_loss

func heal(health_gain: int) -> void:
	stats.health += health_gain
