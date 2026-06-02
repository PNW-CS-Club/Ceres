class_name HpPlant extends Plant

func ability_at_dawn():
	super.ability_at_dawn() # this line just serves as a compiler check
	for plant in adj_plants:
		plant.heal(20)
