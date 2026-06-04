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

func receive_attack(damage: int) -> void: 
	print("receive_attack(damage=%d) self=%s" % [damage, self])
	var cover_left: int = 0
	var damage_left: int = damage
	
	for plant in adj_plants:
		print("< cover ", plant.stats.current_cover_provided, " from ", plant)
		cover_left += plant.stats.current_cover_provided
	
	# duplicate the array so that removing from adj_plants doesnt affect it
	for plant in adj_plants.duplicate(): 
		print("> cover_left: ", cover_left, ", damage_left: ", damage_left)
		if cover_left <= 0: break
		
		var multiplier: float = min(1.0, float(damage_left) / cover_left) 
		# the min prevents the plant from covering more than it needs to (if damage_left < cover_left)
		var covered_damage = int(plant.stats.current_cover_provided * multiplier);
		
		if covered_damage > 0:
			plant.take_damage(covered_damage)
			cover_left -= plant.stats.current_cover_provided
			damage_left -= covered_damage
	
	print("> damage_left: ", damage_left)
	if damage_left > 0:
		take_damage(damage_left)

func take_damage(health_loss: int) -> void:
	print("take_damage(health_loss=%d) self=%s" % [health_loss, self])
	stats.health -= health_loss

func heal(health_gain: int) -> void:
	print("heal(health_gain=%d) self=%s" % [health_gain, self])
	stats.health += health_gain
