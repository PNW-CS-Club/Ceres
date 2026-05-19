class_name Shop extends BaseButton

signal try_buy(item: Item, quantity: int, total_price: int, index: int)


const BUFF_BUFF_SEED = preload("uid://lbrpwm774xio")
const BUFF_DEF_SEED = preload("uid://cnyfoeggl3wu4")
const BUFF_HP_SEED = preload("uid://cyvhvfsxnkax2")
const BUFF_SEED = preload("uid://2enc8i11rwcn")
const DEF_DEF_SEED = preload("uid://cf1rhemkxk6p7")
const DEF_HP_SEED = preload("uid://djbxsbsd7pdbn")
const DEF_SEED = preload("uid://bmuyyjk7ba5o6")
const HP_HP_SEED = preload("uid://h0n2yn0ei1w0")
const HP_SEED = preload("uid://gad4q5m7vacj")
const SHOVEL = preload("uid://us2gsrgycubo")
const WATER = preload("uid://dot1l1nu30k12")


@onready var _item_container: Control = %ShopItemContainer
@onready var _shop_items: Array[ShopItem] = []
var _rng = RandomNumberGenerator.new()


func _ready() -> void:
	for child in _item_container.get_children():
		if child is ShopItem:
			_shop_items.append(child)
	
	for i in range(_shop_items.size()):
		# pass try_buy signal through
		_shop_items[i].try_buy_shop_item.connect(_emit_try_buy.bind(i))


func _emit_try_buy(item: Item, quantity: int, total_price: int, index: int):
	try_buy.emit(item, quantity, total_price, index)


func remove_at_index(quantity, index):
	_shop_items[index].quantity -= 1


func refresh() -> void:
	var values = []
	
	var basic_pool = [BUFF_SEED, DEF_SEED, HP_SEED]
	basic_pool.shuffle()
	var hybrid_pool = [BUFF_DEF_SEED, BUFF_HP_SEED, DEF_HP_SEED]
	hybrid_pool.shuffle()
	var double_pool = [BUFF_BUFF_SEED, DEF_DEF_SEED, HP_HP_SEED]
	double_pool.shuffle()
	
	
	# add a BASIC SEED to the shop
	var basic_item = basic_pool.pop_back()
	# basic_cost is a random value between 30 and 50, rounded to nearest 5
	var basic_cost = snapped(_rng.randi_range(30, 50), 5) 
	values.append([ basic_item, 1, basic_cost ])
	
	
	var tier2_pool = []
	tier2_pool.append_array(hybrid_pool)
	tier2_pool.append_array(double_pool)
	tier2_pool.shuffle()
	
	# add a TIER 2 SEED to the shop
	var tier2_item = tier2_pool.pop_back()
	var tier2_cost = snapped(_rng.randi_range(80, 120), 5)
	values.append([ tier2_item, 1, tier2_cost ])
	
	
	var tools = [
		[WATER, randi_range(1, 2), 40], 
		[SHOVEL, 1, 60]
	]
	tools.shuffle()
	
	# add a TOOL to the shop
	var tool = tools.pop_back()
	values.append(tool)
	
	# REMOVE 1 random item from the shop
	values.shuffle()
	values.pop_back()
	
	# update the shop's item slots
	for i in range(_shop_items.size()):
		var slot = _shop_items[i]
		if i < values.size():
			var value = values[i]
			slot.item = value[0]
			slot.quantity = value[1]
			slot.price_per = value[2]
			slot.show()
		else:
			slot.hide()
