class_name DefHpPlant extends Plant

@onready var health_bar: HealthBar = %HealthBar
func _ready() -> void:
	super._ready()
	health_bar.setup(stats)

func ability():
	print("I'm Dobby the Defense HP Plant!!")
