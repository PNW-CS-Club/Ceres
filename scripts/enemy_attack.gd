class_name EnemyAttack extends Node2D

signal squares_to_attack(marked_squares: Array[Vector2i])

enum Attacks {SQUARE, ROW_COLUMN, RANDOM}

var guaranteed_hit_chance: float = 0.10: set = on_guaranteed_hit_chance_set
@onready var grid: Grid = %Grid 
var rng

func _ready():
	rng = RandomNumberGenerator.new()

## Set the guaranteed hit chance of the attack bound between [0.0,1.0].
func on_guaranteed_hit_chance_set(amount: float) -> void:
	guaranteed_hit_chance = clamp(amount, 0.0, 1.0)
	

## Attack function that can be used to specify the attack and the size of the attack.
## Emits a signal of the marked squares
func attack(type: Attacks = Attacks.SQUARE, size: int = 1) -> void:
	# check if there are any plants first
	if grid.plants.is_empty():
		return
	if size < 1: size = 1 # Minimum size of an attack should be 1
	var rand_num = rng.randf_range(0.0001, 1.0) # exclude 0 so there isnt a chance of guaranteed hit at 0% chance
	var guaranteed_hit: bool = rand_num <= guaranteed_hit_chance 
	match type:
		Attacks.SQUARE:
			squares_to_attack.emit( _square_attack(guaranteed_hit, size) )
		Attacks.ROW_COLUMN:
			squares_to_attack.emit( _row_column_attack(guaranteed_hit) ) # row column attack doesnt have a size
		Attacks.RANDOM:
			squares_to_attack.emit( _random_attack(guaranteed_hit, size) )
	

#region attacks
## A square attack pattern where the size parameter determines the side length of the square. [br]
## | 1 | 2 | 0 | [br]
## | 3 | 4 | 0 | [br]
## | 0 | 0 | 0 | [br]
func _square_attack(guaranteed_hit: bool, size: int) -> Array[Vector2i]:
	var attack_length: int = clampi(size,1,grid.WIDTH) # Clamp size to grid WIDTH
	attack_length = clampi(attack_length,1,grid.HEIGHT)  # Clamp size to grid HEIGHT
	var column: int
	var row: int
	var marked_squares: Array[Vector2i]
	if guaranteed_hit: # generate the attack to hit at least 1 plant
		var plant_coords: Vector2i = grid.plants.pick_random() # picks a random plant from the list of living plants
		if attack_length == 1: # attack a single square
			marked_squares.append(plant_coords)
			return marked_squares
		# else: generate the attack to hit the random plant
		# find column start index
		if (plant_coords.x + attack_length) > (grid.WIDTH - 1):
			var diff = plant_coords.x + attack_length - grid.WIDTH + 1
			column = clampi(plant_coords.x - diff,0,grid.WIDTH-1)
		else:
			column = plant_coords.x
		# find row start index
		if (plant_coords.y + attack_length) > (grid.HEIGHT - 1):
			var diff = plant_coords.y + attack_length - grid.HEIGHT + 1
			row = clampi(plant_coords.y - diff,0,grid.HEIGHT-1)
		else:
			row = plant_coords.y
		# mark squares
		for r in range(row, row + attack_length):
			for c in range(column, column + attack_length):
				marked_squares.append(Vector2i(c,r))
		return marked_squares
	# else: generate the attack in a random spot in the grid
	column = rng.randi_range(0,grid.WIDTH - attack_length)
	row = rng.randi_range(0,grid.HEIGHT - attack_length)
	if attack_length == 1:
		marked_squares.append(Vector2i(column,row))
		return marked_squares
	for r in range(row, row + attack_length):
		for c in range(column, column + attack_length):
			marked_squares.append(Vector2i(c,r))
	return marked_squares


## An Attack pattern that hits an entire row and column.
## Attack row first then attack column. 
## The square where the attacks overlap gets hit twice. [br]
## | 1 |2 4| 3 | [br]
## | 0 | 5 | 0 | [br]
## | 0 | 6 | 0 | [br]
func _row_column_attack(guaranteed_hit: bool) -> Array[Vector2i]:
	var column: int 
	var row: int 
	var marked_squares: Array[Vector2i]
	
	if guaranteed_hit: # Center the attack on the row and column of a random plant.
		var plant_coords: Vector2i = grid.plants.pick_random() # picks a random plant from the list of living plants
		column = plant_coords.x
		row = plant_coords.y
		for c in range(grid.WIDTH): # First mark the row.
			marked_squares.append(Vector2i(c,row))
		for r in range(grid.HEIGHT): # Secondly mark the column.
			marked_squares.append(Vector2i(column,r))
		return marked_squares
	# Generate a random column and random row.
	column = rng.randi_range(0,grid.WIDTH-1)
	row = rng.randi_range(0,grid.HEIGHT-1)
	for c in range(grid.WIDTH): # First mark the row.
		marked_squares.append(Vector2i(c,row))
	for r in range(grid.HEIGHT): # Secondly mark the column.
		marked_squares.append(Vector2i(column,r))
	return marked_squares

## A random attack where size is the amount of hits. [br]
## | 2 | 1 |[br]
## | 3 | 0 |[br]
## | 0 | 4 |[br]
func _random_attack(guaranteed_hit: bool, size: int) -> Array[Vector2i]:
	# size in this function is the amount of random attacks
	print("Doing a random attack")
	var marked_squares: Array[Vector2i]
	
	if guaranteed_hit: # The very first strike is a guaranteed hit on a random plant.
		var plant_coords: Vector2i = grid.plants.pick_random() # picks a random plant from the list of living plants
		marked_squares.append(plant_coords)
		size -= 1 # Count the guaranteed hit
	# The remaining attacks are random
	for i in range(size):
		marked_squares.append(Vector2i(rng.randi_range(0,grid.WIDTH-1), rng.randi_range(0,grid.HEIGHT-1)))
	print("returning the marked squares:",marked_squares)
	return marked_squares
#endregion
