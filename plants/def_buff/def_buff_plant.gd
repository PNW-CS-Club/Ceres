class_name DefBuffPlant extends Plant

@onready var health_bar: HealthBar = %HealthBar
func _ready() -> void:
	super._ready()
	health_bar.setup(stats)

func ability():
	print("I'm Dan the Defense Buff Plant!!")
