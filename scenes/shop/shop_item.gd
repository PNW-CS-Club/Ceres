## A "slot" in the shop that holds one stack of items.
## Has a button that displays the price.
##
## This class was designed to "just work": 
## it only has three public fields and a signal.
## Setting the fields will update the display, 
## and the signal will be emitted when the player presses the buy button.
class_name ShopItem extends Control

signal try_buy_shop_item(item: Item, quantity: int, total_price: int)

const DIM_OPACITY = 0.5

var quantity: int: set = _set_quantity
var price_per: int: set = _set_price_per
var item: Item: set = _set_item

@onready var _name_label: Label = %NameLabel
@onready var _stack: ItemStack = %ItemStack
@onready var _desc_label: Label = %DescLabel
@onready var _buy_button: Button = %BuyButton
var _initialized: bool = false

#region Setter Methods
func _set_quantity(value: int) -> void:
	# quantity validation
	if value < 0:
		printerr("attempted to set shop item '%s' to a negative quantity (%d)" % 
				 [_stack.item.name, value])
	quantity = max(0, value)
	if not _initialized: return
	
	# dim the stack display if there are none left in stock
	if quantity == 0:
		_stack.amount = 1
		_stack.modulate = Color(1.0, 1.0, 1.0, DIM_OPACITY)
		_buy_button.disabled = true
	else:
		_stack.amount = quantity
		_stack.modulate = Color.WHITE
		_buy_button.disabled = false

func _set_price_per(value: int) -> void:
	price_per = value
	if not _initialized: return
	_buy_button.text = str(value)

func _set_item(value: Item) -> void:
	item = value
	if not _initialized or not item: return
	_stack.item = item
	_name_label.text = item.name
	_desc_label.text = item.desc
	
#endregion

func _ready() -> void:
	_initialized = true
	_set_quantity(quantity)
	_set_price_per(price_per)
	_set_item(item)

func _emit_try_buy():
	_emit_try_buy_many(1)

func _emit_try_buy_many(n: int) -> void: 
	if quantity < n: return
	try_buy_shop_item.emit(_stack.item, n, price_per * n)
