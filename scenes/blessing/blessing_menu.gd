class_name BlessingMenu extends BaseButton

signal accept(stack: ItemStack)
signal done()


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


@onready var _item_container: Control = %BlessingItemContainer
@onready var _blessing_items: Array[BlessingItem] = []
var _rng = RandomNumberGenerator.new()

var _blessings_left: int = 0


func _ready() -> void:
	for child in _item_container.get_children():
		if child is BlessingItem:
			_blessing_items.append(child)
	
	for i in range(_blessing_items.size()):
		# pass accept signal through
		_blessing_items[i].accept_blessing_item.connect(_emit_accept)


func _emit_accept(stack: ItemStack):
	print("Accepting %s" % [stack])
	_blessings_left -= 1
	accept.emit(stack)
	if _blessings_left <= 0:
		done.emit()


func _make_blessing(item: Item, quantity: int) -> Dictionary:
	return {
		"item": item,
		"quantity": quantity
	}

func generate_blessings(day: int) -> Array[Dictionary]:
	
	print("generating for day ", day)
	
	var basic_pool = [BUFF_SEED, DEF_SEED, HP_SEED]
	basic_pool.shuffle()
	var hybrid_pool = [BUFF_DEF_SEED, BUFF_HP_SEED, DEF_HP_SEED]
	hybrid_pool.shuffle()
	var double_pool = [BUFF_BUFF_SEED, DEF_DEF_SEED, HP_HP_SEED]
	double_pool.shuffle()
	var tier2_pool = []
	tier2_pool.append_array(hybrid_pool)
	tier2_pool.append_array(double_pool)
	tier2_pool.shuffle()
	
	var values: Array[Dictionary] = []
	
	if day == 1:
		return [
			_make_blessing(WATER, 2),
			_make_blessing(BUFF_SEED, 1),
			_make_blessing(DEF_SEED, 1),
			_make_blessing(HP_SEED, 1),
		]
		
	elif day == 2:
		values.push_back(_make_blessing(WATER, 2))
		var basic_seed = basic_pool.pop_back()
		values.push_back(_make_blessing(basic_seed, 1))
		return values
		
	elif day == 3:
		values.push_back(_make_blessing(WATER, 2))
		var basic_seed = basic_pool.pop_back()
		values.push_back(_make_blessing(basic_seed, 1))
		values.push_back(_make_blessing(SHOVEL, 1))
		return values
		
	else:
		values.push_back(_make_blessing(WATER, _rng.randi_range(2, 3)))
		
		if _rng.randf() <= 0.5:
			# add a BASIC SEED and a SHOVEL to the blessing
			var basic_seed = basic_pool.pop_back()
			values.append(_make_blessing(basic_seed, 1))
			values.append(_make_blessing(SHOVEL, 1))
		else: 
			# add a TIER 2 SEED to the blessing
			var tier2_seed = tier2_pool.pop_back()
			values.append(_make_blessing(tier2_seed, 1))
		
		return values


## updates the blessing menu's item slots with the given items
func refresh(blessings: Array[Dictionary]) -> void:
	_blessings_left = 0
	for i in range(_blessing_items.size()):
		var slot = _blessing_items[i]
		if i < blessings.size():
			slot.reset()
			_blessings_left += 1
			var blessing = blessings[i]
			slot.item = blessing["item"]
			slot.quantity = blessing["quantity"]
			slot.show()
		else:
			slot.hide()
