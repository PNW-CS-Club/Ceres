class_name Game extends Node2D

signal attacks_complete

enum GameStates {DAWN, DAY, DUSK, NIGHT}

@onready var debug_menu: DebugMenu = %DebugMenu
@onready var farm: FarmTileLayer = %TileMapLayerFarm
@onready var inventory: Inventory = %Hotbar
@onready var grid: Grid = %Grid
@onready var shop: Shop = %Shop 
@onready var shop_button: BaseButton = %ShopButton
@onready var cabin: Cabin = %Cabin
@onready var cabin_area: CabinArea = %CabinArea
@onready var blessing_menu: BlessingMenu = %BlessingMenu
@onready var forecast: Forecast = %Forecast
@onready var wallet: Wallet = %Wallet
@onready var daylight_cycle: DaylightCycle = %DaylightCycle
@onready var attack_highlight_marker: Sprite2D = %AttackHighlightMarker
@onready var enemy_attack: EnemyAttack = %EnemyAttack

@onready var sfx_attackmiss: AudioStreamPlayer = $sfx_attackmiss
@onready var sfx_attackhit: AudioStreamPlayer = %sfx_attackhit
@onready var sfx_dig: AudioStreamPlayer = %sfx_dig
@onready var sfx_plant: AudioStreamPlayer = %sfx_plant
@onready var sfx_water: AudioStreamPlayer = %sfx_water

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

# Atlas coords
const WET_TILE: Vector2i = Vector2i(0,0)
const DRY_TILE: Vector2i = Vector2i(1,0)
const DEBRIS_TILE: Vector2i = Vector2i(4,2)

var current_day: int = 0
var debug_pressed_last_frame: bool = false


func _ready():
	# Signals
	farm.on_tile_click.connect(_click_tile)
	cabin.end_day.connect(_end_day)
	shop.try_buy.connect(_click_purchase)
	blessing_menu.accept.connect(_click_blessing)
	enemy_attack.squares_to_attack.connect(_attack_squares)
	
	attack_highlight_marker.visible = false
	
	debug_menu.hide()
	debug_menu.cheat_in_items.connect(_cheat_in_items)
	
	# Generate Schedule
	forecast.add_safe_day()
	forecast.add_safe_day()
	forecast.add_payment_day(40)
	forecast.add_attack_day([])
	forecast.add_payment_day(80)
	forecast.add_attack_day([])
	forecast.add_final_day(120, [])
	
	# Game State
	set_state(GameStates.DAWN)

func _process(_delta: float):
	if not debug_pressed_last_frame and Input.is_key_pressed(KEY_QUOTELEFT):
		debug_menu.visible = not debug_menu.visible
	
	debug_pressed_last_frame = Input.is_key_pressed(KEY_QUOTELEFT)


#region Debug Cheats

func _cheat_in_items(type: Item.Type, amount: int):
	const item_list: Array[Item] = [ 
		BUFF_BUFF_SEED_ITEM, BUFF_DEF_SEED_ITEM, BUFF_HP_SEED_ITEM, 
		BUFF_SEED_ITEM, DEF_DEF_SEED_ITEM, DEF_HP_SEED_ITEM, 
		DEF_SEED_ITEM, HP_HP_SEED_ITEM, HP_SEED_ITEM, 
		SHOVEL_ITEM, WATER_ITEM
	]
	for item in item_list:
		if item.type == type:
			inventory.add_item(item, amount)
			return
	printerr("Could not find item of type ", Item.Type.find_key(type))

#endregion



#region Game State

func set_state(state: Game.GameStates) -> void:
	print("Transitioning to ", Game.GameStates.find_key(state))
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
	forecast.incr_day()
	if forecast.get_day() != current_day:
		printerr("mismatch between `forecast.get_day()` = %d and `current_day` = %d" % 
			[forecast.get_day(), current_day])
	
	print("Today's event: ", forecast.get_event_today())
	
	# Display good day overview if not the first day
	if current_day > 1:
		pass # Display good day overview
	
	inventory.visible = false
	cabin_area.can_select = false
	shop_button.disabled = true
	wallet.visible = true
	var blessings = blessing_menu.generate_blessings(current_day)
	blessing_menu.refresh(blessings)
	_reset_wet_to_dry()
	_add_debris()
	daylight_cycle.transition_to(DaylightCycle.Phase.DAWN)
	await daylight_cycle.transition_finished
	print("DAWN phase started")
	
	if current_day == 1: 
		wallet.change_balance(50)
	else:
		var rng = RandomNumberGenerator.new()
		wallet.change_balance(rng.randi_range(20,50))
	
	# TODO: activate "ability_at_dawn" plant abilities here
	
	blessing_menu.show()
	await blessing_menu.done
	blessing_menu.hide()
	
	set_state(GameStates.DAY)

## The player does most of their actions here
func _handle_day() -> void:
	daylight_cycle.transition_to(DaylightCycle.Phase.DAY)
	inventory.visible = true
	cabin_area.can_select = true
	shop.refresh()
	shop_button.disabled = false
	wallet.visible = true
	print("DAY phase started")

## The attacks happen during this state
func _handle_dusk() -> void:
	inventory.drop_stack()
	inventory.visible = false
	cabin_area.can_select = false
	shop_button.disabled = true
	wallet.visible = true
	daylight_cycle.transition_to(DaylightCycle.Phase.DUSK)
	await daylight_cycle.transition_finished
	print("DUSK phase started")
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
	print("NIGHT phase started")
	# Check if the player lost
	if grid.plants.is_empty():
		print("Game over! No plants survived!")
	else:
		set_state(GameStates.DAWN)

func _end_day() -> void:
	cabin.visible = false
	set_state(GameStates.DUSK)
#endregion

#region Player Actions
func _click_tile(coords: Vector2i) -> void:
	var plot_contents: Node = grid.at(coords)
	
	if inventory.stack_in_hand:
		var item: Item = inventory.stack_in_hand.item
		
		if !plot_contents:
			_try_to_plant(coords, item)
		elif plot_contents is Plant:
			if item.type == Item.Type.WATER:
				_try_to_water(coords)
		elif plot_contents is Debris:
			if item.type == Item.Type.SHOVEL:
				_dig_up(coords)
		else:
			printerr("Unexpected plot_contents (%s) at coords %s" % [plot_contents, coords])


## If the given item is plantable, it is consumed and the plant is created.
## Returns whether it was successful.
## This function assumes that `item` is in hand and the plot is empty.
func _try_to_plant(coords: Vector2i, item: Item) -> bool:
	if farm.get_cell_atlas_coords(coords) == DEBRIS_TILE: # Debris
		print("Planting at %s failed because the land has debris" % [coords])
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
		grid.add_child(plant, true)
		sfx_plant.play()
		plant.stats.health_depleted.connect(_on_plant_died.bind(coords, plant))
		
		for adj in _get_adjacent_plants(coords):
			adj.register_adj(plant)
			plant.register_adj(adj)
		
		return true
	else:
		return false

func _get_adjacent_plants(coords: Vector2i) -> Array[Plant]:
	# NOTE: these are the 8 adjacent tiles, 
	#       but we could choose to use only the 4 adjacent ones instead
	const offsets: Array[Vector2i] = [
		Vector2i(-1, -1),
		Vector2i(-1, 0),
		Vector2i(-1, +1),
		Vector2i(0, -1),
		Vector2i(0, +1),
		Vector2i(+1, -1),
		Vector2i(+1, 0),
		Vector2i(+1, +1),
	]
	var result: Array[Plant] = []
	
	for offset in offsets:
		var new_coords = coords + offset
		if not grid.is_in_bounds(new_coords): continue
		
		var plot_contents = grid.at(new_coords)
		if plot_contents is Plant: 
			result.append(plot_contents)
	
	result.shuffle()
	return result

## Use the shovel to remove debris
func _dig_up(coords: Vector2i) -> void:
	var target = grid.at(coords)
	if target is Debris:
		grid.put(coords, null)
		grid.remove_child(target)
		farm.set_cell(coords, 9, DRY_TILE)
		sfx_dig.play()
		inventory.remove_from_hand(1)
	else:
		print("Cannot dig up non-debris target at %s" % [coords])

## If the coordinate is a plant, the watering can is used and the plant is upgraded.
## Returns whether it was successful.
## A plant can only be watered 1 time per day.
func _try_to_water(coords: Vector2i) -> bool:
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

## Used to place debris in the farm. Only places in empty tiles
func _add_debris() -> void:
	var rng = RandomNumberGenerator.new()
	var debris_amount = rng.randi_range(0,4)
	while debris_amount > 0:
		var cell_coords: Vector2i = Vector2i(rng.randi_range(0,grid.WIDTH-1), rng.randi_range(0,grid.HEIGHT-1))
		var cell = grid.at(cell_coords)
		if cell == null: 
			var debris: Debris = Debris.new()
			debris.name = "Debris"
			grid.put(cell_coords, debris)
			grid.add_child(debris, true)
			farm.set_cell(cell_coords, 9, DEBRIS_TILE)
		debris_amount -= 1 
		#NOTE Even if the function failed to add certain debris we still reduce the amount.
		#NOTE This gives some grace to the player so that they see less debris with nearly full boards.

## Adds item to inventory and subtracts price from wallet
func _click_purchase(item: Item, quantity: int, price: int, index: int) -> void:
	if price > wallet.coins:
		print("Only had %d of %d coins required to buy %dx %s" % [wallet.coins, price, quantity, item.name])
	else:
		wallet.change_balance(-price)
		inventory.add_item(item, quantity)
		shop.remove_at_index(quantity, index)

## Adds blessing item stack to inventory
func _click_blessing(stack: ItemStack) -> void:
	inventory.add_item(stack.item, stack.amount)

## Reset all the wet tiles to dry tiles
func _reset_wet_to_dry() -> void:
	var wet_tiles: Array[Vector2i] = farm.get_used_cells_by_id(9,WET_TILE)
	for i in wet_tiles:
		farm.set_cell(i, 9, DRY_TILE)

## Deal attack damage to the marked squares
func _attack_squares(marked_squares: Array[Vector2i]) -> void:
	print("Now attacking the targeted squares")
	for square in marked_squares:
		# Place the attack marker on the square
		attack_highlight_marker.global_position = farm.to_global(farm.map_to_local(square))
		attack_highlight_marker.visible = true
		await get_tree().create_timer(0.2).timeout
		if grid.at(square) is Plant:
			var plant: Plant = grid.at(square)
			plant.receive_attack(100)
			sfx_attackhit.play()
		else:
			sfx_attackmiss.play()
		await get_tree().create_timer(0.1).timeout
	attack_highlight_marker.visible = false
	attacks_complete.emit()

func _on_plant_died(coords: Vector2i, plant: Plant) -> void:
	grid.plants.erase(coords)
	var debris: Debris = Debris.new()
	grid.put(coords, debris)
	grid.add_child(debris, true)
	farm.set_cell(coords, 9, DEBRIS_TILE)
	grid.remove_child(plant)
	plant.queue_free()
#endregion
