class_name Forecast extends Control

enum DayEvent { SAFE, PAYMENT, ATTACK, FINAL }

var schedule: Array[Dictionary] = []

@onready var _day_label: Label = %DayLabel

var _curr_day: int = 0

func incr_day() -> void:
	_curr_day += 1
	_day_label.text = "Day %d" % [_curr_day]
	_animate_icons()

func get_day() -> int:
	return _curr_day

func get_event_today() -> Dictionary:
	if _curr_day > schedule.size():
		printerr("Schedule array does not have an event for day #", _curr_day)
		return {}
	return schedule[_curr_day - 1]

func add_safe_day() -> void:
	schedule.push_back({
		"type": DayEvent.SAFE
	})
	
func add_payment_day(price: int) -> void:
	schedule.push_back({
		"type": DayEvent.PAYMENT, 
		"price": price 
	})
	
func add_attack_day(attacks: Array[EnemyAttack.Attacks]) -> void:
	schedule.push_back({
		"type": DayEvent.ATTACK, 
		"attacks": attacks
	})
	
func add_final_day(price: int, attacks: Array[EnemyAttack.Attacks]) -> void:
	schedule.push_back({
		"type": DayEvent.FINAL, 
		"price": price, 
		"attacks": attacks 
	})

func _ready() -> void:
	pass

func _animate_icons() -> void:
	pass
