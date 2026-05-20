class_name HealthBar extends Node2D


@onready var hpbar: ProgressBar = %HPBar
@onready var hplabel: RichTextLabel = %HPLabel

## Health bar is ignorant of its parent.
## Whoever owns it passes the stats in.
func setup(stats: Stats) -> void:
	stats.health_changed.connect(_update_health)
	_update_health(stats.health,stats.current_max_health)


func _update_health(current_health: int, max_health: int) -> void:
	hpbar.max_value = max_health
	hpbar.set_value_no_signal(current_health)
	hplabel.text = str(current_health)
