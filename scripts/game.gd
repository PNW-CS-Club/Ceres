class_name Game extends Node2D

signal attacks_complete


@onready var farm: FarmTileLayer = %TileMapLayerFarm
@onready var inventory: Inventory = %Hotbar
@onready var grid: Grid = %Grid
@onready var shop: Shop = %Shop 
@onready var shop_button: BaseButton = %ShopButton
@onready var cabin: Cabin = %Cabin
@onready var cabin_area: CabinArea = %CabinArea
@onready var wallet: Wallet = %Wallet
@onready var daylight_cycle: DaylightCycle = %DaylightCycle
@onready var attack_highlight_marker: Sprite2D = %AttackHighlightMarker
@onready var enemy_attack: EnemyAttack = %EnemyAttack

@onready var sfx_attackmiss: AudioStreamPlayer = $sfx_attackmiss
@onready var sfx_attackhit: AudioStreamPlayer = %sfx_attackhit
@onready var sfx_dig: AudioStreamPlayer = %sfx_dig
@onready var sfx_plant: AudioStreamPlayer = %sfx_plant
@onready var sfx_water: AudioStreamPlayer = %sfx_water

enum GameStates {DAWN, DAY, DUSK, NIGHT}

const BUFF_PLANT_SCENE: PackedScene = preload("uid://dciwxjx24qc3d")
const DEF_PLANT_SCENE: PackedScene = preload("uid://cj5dv7qg2wly8")
const HP_PLANT_SCENE: PackedScene = preload("uid://dka8tnw2nv8vq")
const BUFF_BUFF_PLANT_SCENE: PackedScene = preload("uid://dv2es8w1ejiuj")
const DEF_DEF_PLANT_SCENE: PackedScene = preload("uid://clfojmjqriv6d")
const HP_HP_PLANT_SCENE: PackedScene = preload("uid://ch6t652jrihl5")
const DEF_BUFF_PLANT_SCENE: PackedScene = preload("uid://dwx5ysqk211ee")
const DEF_HP_PLANT_SCENE: PackedScene = preload("uid://bamydx7slu2tx")
const HP_BUFF_PLANT_SCENE: PackedScene = preload("uid://ml2bjogn0vg")

const BUFF_BUFF_SEED_ITEM: Item = preload("uid://lbrpwm774xio")
const BUFF_DEF_SEED_ITEM: Item = preload("uid://cnyfoeggl3wu4")
const BUFF_HP_SEED_ITEM: Item = preload("uid://cyvhvfsxnkax2")
const BUFF_SEED_ITEM: Item = preload("uid://2enc8i11rwcn")
const DEF_DEF_SEED_ITEM: Item = preload("uid://cf1rhemkxk6p7")
const DEF_HP_SEED_ITEM: Item = preload("uid://djbxsbsd7pdbn")
const DEF_SEED_ITEM: Item = preload("uid://bmuyyjk7ba5o6")
const HP_HP_SEED_ITEM: Item = preload("uid://h0n2yn0ei1w0")
const HP_SEED_ITEM: Item = preload("uid://gad4q5m7vacj")

const SHOVEL_ITEM: Item = preload("uid://us2gsrgycubo")
const WATER_ITEM: Item = preload("uid://dot1l1nu30k12")

const current_state = GameStates.DAWN
var current_day: int

# Atlas coords
const WET_TILE: Vector2i = Vector2i(0,0)
const DRY_TILE: Vector2i = Vector2i(1,0)
const DEBRIS_TILE: Vector2i = Vector2i(4,2)

func _ready():
	# Signals
	farm.on_tile_click.connect(_click_tile)
	cabin.end_day.connect(_end_day)
	shop.try_buy.connect(_click_purchase)
	
	enemy_attack.squares_to_attack.connect(_attack_squares)
	#Game State
	set_state(GameStates.DAWN)
	current_day = 0
	attack_highlight_marker.visible = false


#region Game State

func set_state(state: Game.GameStates) -> void:
	print("setting state to:",state)
	match state:
		GameStates.DAWN:
			_handle_dawn()
		GameStates.DAY:
			_handle_day()
		GameStates.DUSK:
			_handle_dusk()
		GameStates.NIGHT:
			_handle_night()

## The game starts here. Give the player resources
func _handle_dawn() -> void:
	current_day += 1
	# Display good day overview if not the first day
	if current_day > 1:
		pass #Display good day overview
	
	inventory.visible = false
	cabin_area.can_select = false
	shop_button.disabled = true
	wallet.visible = true
	_give_resources()
	_reset_wet_to_dry()
	_add_debris()
	daylight_cycle.transition_to(DaylightCycle.Phase.DAWN)
	await daylight_cycle.transition_finished
	print("state is now dawn")
	set_state(GameStates.DAY)

## The player does most of their actions here
func _handle_day() -> void:
	daylight_cycle.transition_to(DaylightCycle.Phase.DAY)
	inventory.visible = true
	cabin_area.can_select = true
	shop.refresh()
	shop_button.disabled = false
	wallet.visible = true
	print("state is now day")

## The attacks happen during this state
func _handle_dusk() -> void:
	inventory.drop_stack()
	inventory.visible = false
	cabin_area.can_select = false
	shop_button.disabled = true
	wallet.visible = true
	daylight_cycle.transition_to(DaylightCycle.Phase.DUSK)
	await daylight_cycle.transition_finished
	print("state is now dusk")
	var rng = RandomNumberGenerator.new()
	var number_of_patterns = rng.randi_range(1,3)
	for i in number_of_patterns:
		# select a pattern
		var pattern = randi_range(0,EnemyAttack.Attacks.size()-1)
		var number_of_attacks = rng.randi_range(2, 6)
		enemy_attack.attack(pattern, number_of_attacks)
		await attacks_complete
	set_state(GameStates.NIGHT)

## We check if the player survived at this stage.
func _handle_night() -> void:
	daylight_cycle.transition_to(DaylightCycle.Phase.NIGHT)
	await daylight_cycle.transition_finished
	print("state is now night")
	set_state(GameStates.DAWN)
	# Check if the player lost
	if grid.plants.is_empty():
		pass

func _end_day() -> void:
	cabin.visible = false
	set_state(GameStates.DUSK)
#endregion

#region Player Actions
func _click_tile(coords: Vector2i) -> void:
	print("\nclicked on farm plot at " + str(coords))
	var plot_contents: Node = grid.at(coords)
	
	if inventory.stack_in_hand:
		var item: Item = inventory.stack_in_hand.item
		
		if !plot_contents:
			print("> trying to place " + item.name)
			if _try_to_plant(coords, item):
				print("> success")
				return
			else: print("> failed")
		elif plot_contents is Plant:
			if item.type == Item.Type.WATER:
				_try_to_water(coords)
		else:
			if item.type == Item.Type.SHOVEL:
				_dig_up(coords)


## If the given item is plantable, it is consumed and the plant is created.
## Returns whether it was successful.
## This function assumes that `item` is in hand and the plot is empty.
func _try_to_plant(coords: Vector2i, item: Item) -> bool:
	if farm.get_cell_atlas_coords(coords) == DEBRIS_TILE: # Debris
		print("> failed because the land has debris.")
		return false
	# try to find a plant to instantiate
	var plant_scene: PackedScene
	match item.type:
		Item.Type.BUFF_SEED:
			plant_scene = BUFF_PLANT_SCENE
		Item.Type.DEF_SEED:
			plant_scene = DEF_PLANT_SCENE
		Item.Type.HP_SEED:
			plant_scene = HP_PLANT_SCENE
		Item.Type.BUFF_BUFF_SEED:
			plant_scene = BUFF_BUFF_PLANT_SCENE
		Item.Type.DEF_DEF_SEED:
			plant_scene = DEF_DEF_PLANT_SCENE
		Item.Type.HP_HP_SEED:
			plant_scene = HP_HP_PLANT_SCENE
		Item.Type.BUFF_DEF_SEED:
			plant_scene = DEF_BUFF_PLANT_SCENE
		Item.Type.BUFF_HP_SEED:
			plant_scene = HP_BUFF_PLANT_SCENE
		Item.Type.DEF_HP_SEED:
			plant_scene = DEF_HP_PLANT_SCENE
	
	if plant_scene:
		var plant: Plant = plant_scene.instantiate()
		plant.global_position = farm.to_global(farm.map_to_local(coords))
		inventory.remove_from_hand(1)
		grid.put(coords, plant)
		grid.plants.append(coords)
		grid.add_child(plant)
		sfx_plant.play()
		plant.stats.health_depleted.connect(_on_plant_died.bind(coords, plant))
		return true
	else:
		return false

## Use the shovel to remove debris
func _dig_up(coords: Vector2i) -> void:
	var target = grid.at(coords)
	if target is Debris:
		grid.put(coords, null)
		grid.remove_child(target)
		farm.set_cell(coords, 9, DRY_TILE)
		sfx_dig.play()
		inventory.remove_from_hand(1)

## If the coordinate is a plant, the watering can is used and the plant is upgraded.
## Returns whether it was successful.
## A plant can only be watered 1 time per day.
func _try_to_water(coords: Vector2i) -> bool:
	print("Trying to water", coords)
	var plant: Plant = grid.at(coords)
	# Fail if the plant is already max level.
	if plant.stats.level >= 3:
		return false
	# Fail if the plant has already been leveled up this turn.
	if farm.get_cell_atlas_coords(coords) == WET_TILE:
		return false
	# Update the level of the plant. 
	plant.stats.level += 1
	# Update the farm tile to the watered tile
	farm.set_cell(coords, 9, WET_TILE)
	sfx_water.play()
	
	
	inventory.remove_from_hand(1)
	return true
#endregion

#region Private Helper Functions
## Give the player resources
func _give_resources() -> void:
	var rng = RandomNumberGenerator.new()
	const BASIC_SEEDS: Array = [BUFF_SEED_ITEM, HP_SEED_ITEM, DEF_SEED_ITEM]
	const COMBINED_SEEDS: Array = [BUFF_BUFF_SEED_ITEM,BUFF_DEF_SEED_ITEM,BUFF_HP_SEED_ITEM,DEF_DEF_SEED_ITEM,DEF_HP_SEED_ITEM,HP_HP_SEED_ITEM]
	const ALL_SEEDS: Array = BASIC_SEEDS + COMBINED_SEEDS
	var random_seed
	if current_day == 1: # Consistent day 1 resources
		for i in 3: # Pick 3 random basic seeds
			random_seed = BASIC_SEEDS.pick_random()
			inventory.add_item(BUFF_SEED_ITEM,1)
		wallet.change_balance(50) ## Give the player 50 coins
		inventory.add_item(SHOVEL_ITEM,1)
		inventory.add_item(WATER_ITEM, 2)
		return
	if current_day < 3:
		for i in 2:
			random_seed = BASIC_SEEDS.pick_random()
			inventory.add_item(random_seed,1)
	else:
		for i in 2:
			random_seed = ALL_SEEDS.pick_random()
			inventory.add_item(random_seed,1)
	wallet.change_balance(rng.randi_range(20,50))
	inventory.add_item(SHOVEL_ITEM,rng.randi_range(1,3))
	inventory.add_item(WATER_ITEM,randi_range(2,4))



## Used to place debris in the farm. Only places in empty tiles
func _add_debris() -> void:
	var rng = RandomNumberGenerator.new()
	var debris_amount = rng.randi_range(0,4)
	while debris_amount > 0:
		var cell_coords: Vector2i = Vector2i(rng.randi_range(0,grid.WIDTH-1), rng.randi_range(0,grid.HEIGHT-1))
		var cell = grid.at(cell_coords)
		if cell == null: 
			var debris: Debris = Debris.new()
			grid.put(cell_coords, debris)
			grid.add_child(debris)
			farm.set_cell(cell_coords, 9, DEBRIS_TILE)
		debris_amount -= 1 
		#NOTE Even if the function failed to add certain debris we still reduce the amount.
		#NOTE This gives some grace to the player so that they see less debris with nearly full boards.

#adds item to inventory and subtracts price from wallet
func _click_purchase(item: Item, quantity: int, price: int, index: int) -> void:
	if price > wallet.coins:
		print("You do not have enough money")
	else:
		print("You have bought the item")
		wallet.change_balance(-price)
		inventory.add_item(item)
		shop.remove_at_index(quantity, index)

## Reset all the wet tiles to dry tiles
func _reset_wet_to_dry() -> void:
	var wet_tiles: Array[Vector2i] = farm.get_used_cells_by_id(9,WET_TILE)
	for i in wet_tiles:
		farm.set_cell(i, 9, DRY_TILE)

## Deal damage to the marked squares
func _attack_squares(marked_squares: Array[Vector2i]) -> void:
	print("now attacking squares")
	for square in marked_squares:
		# Place the attack marker on the square
		attack_highlight_marker.global_position = farm.to_global(farm.map_to_local(square))
		attack_highlight_marker.visible = true
		await get_tree().create_timer(0.2).timeout
		if grid.at(square) is Plant:
			var plant: Plant = grid.at(square)
			plant.take_damage(100)
			sfx_attackhit.play()
		else:
			sfx_attackmiss.play()
		await get_tree().create_timer(0.2).timeout
		#var plant = grid.at(square)
	attack_highlight_marker.visible = false
	attacks_complete.emit()

func _on_plant_died(coords: Vector2i, plant: Plant) -> void:
	grid.plants.erase(coords)
	var debris: Debris = Debris.new()
	grid.put(coords, debris)
	grid.add_child(debris)
	farm.set_cell(coords, 9, DEBRIS_TILE)
	grid.remove_child(plant)
	plant.queue_free()
#endregion
