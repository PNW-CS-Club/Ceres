extends Resource
class_name Stats

enum BuffableStats {MAX_HEALTH, DODGE_CHANCE, PRICE}

signal health_depleted
signal health_changed(current_health: int, max_health: int)
signal level_changed(level: int)

@export var base_max_health: int = 100
@export var base_dodge_chance: float = 0.00
@export var base_price: float = 100.0
@export var base_level: int = 1
@export var mature_cover_provided: int = 0

var current_max_health: int = 100
var current_dodge_chance: float = 0.00
var current_price: float = 100.0
var current_cover_provided: int = 0
var level: int = 1: set = _on_level_set
var health: int = 0: set = _on_health_set

var stat_buffs: Array[StatBuff]

func _init() -> void:
	setup_stats.call_deferred()

func setup_stats() -> void:
	# recalculate current stats first
	recalculate_stats()
	health = current_max_health

func add_buff(buff: StatBuff) -> void:
	stat_buffs.append(buff)
	recalculate_stats.call_deferred()

func remove_buff(buff: StatBuff) -> void: 
	stat_buffs.erase(buff)
	recalculate_stats.call_deferred()

func recalculate_stats() -> void:
	var stat_multipliers: Dictionary = {} # Amount to multiply included stats by
	var stat_addends: Dictionary = {} # Amount to add to included stats
	for buff in stat_buffs:
		var stat_name: String = BuffableStats.keys()[buff.stat].to_lower()
		match buff.buff_type:
			StatBuff.BuffType.ADD:
				if not stat_addends.has(stat_name):
					stat_addends[stat_name] = 0.0
				stat_addends[stat_name] += buff.buff_amount
			StatBuff.BuffType.MULTIPLY:
				if not stat_multipliers.has(stat_name):
					stat_multipliers[stat_name] = 1.0
				stat_multipliers[stat_name] += buff.buff_amount
	# Set stats based on level
	match level:
		1:
			current_max_health = base_max_health
			current_dodge_chance = base_dodge_chance
			current_price = base_price
			current_cover_provided = 0
		2: 
			current_max_health = int(base_max_health * 2.0)
			current_dodge_chance = base_dodge_chance + 0.05
			current_price = base_price * 1.25
			current_cover_provided = 0
		3: # Max level
			current_max_health = int(base_max_health * 4.0)
			current_dodge_chance = base_dodge_chance + 0.10
			current_price = base_price * 1.5
			current_cover_provided = min(mature_cover_provided, health)
	
	for stat_name in stat_addends:
		var cur_property_name: String = str("current_" + stat_name)
		set(cur_property_name, get(cur_property_name) + stat_addends[stat_name])
	
	for stat_name in stat_multipliers:
		var cur_property_name: String = str("current_" + stat_name)
		set(cur_property_name, get(cur_property_name) * stat_multipliers[stat_name])

func _on_health_set(new_value: int) -> void:
	health = clampi(new_value, 0, current_max_health)
	if level == 3:
		current_cover_provided = min(mature_cover_provided, health)
	health_changed.emit(health, current_max_health)
	if health <= 0:
		health_depleted.emit()

func _on_level_set(new_level: int) -> void:
	level = clampi(new_level, 1, 3)
	recalculate_stats()
	health = current_max_health
	level_changed.emit(level)
