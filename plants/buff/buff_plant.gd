class_name BuffPlant extends Plant

@onready var health_bar: HealthBar = %HealthBar

func _ready() -> void:
	super._ready()
	health_bar.setup(stats)

func ability():
	print("I'm Barry the Buff Plant!!")
