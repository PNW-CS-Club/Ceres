class_name ItemStack extends Control

@onready var item_sprite: TextureRect = %Item
@onready var amount_label: Label = %Label

# item and amount automatically update the gui when they are set
var item: Item: set = _update_item
var amount: int: set = _update_amount
var _is_initialized: bool = false

func _ready() -> void:
	_is_initialized = true
	_update_item(item)
	_update_amount(amount)

func _update_item(value: Item): 
	item = value
	if not _is_initialized or not item: return
	if not item_sprite: printerr("(???) item_sprite is null"); return
	item_sprite.visible = true
	item_sprite.texture = item.texture
	
func _update_amount(value: int): 
	amount = value
	if !_is_initialized: return
	if !amount_label: printerr("(???) amount_label is null"); return
	if amount > 1:
		amount_label.visible = true
		amount_label.text = str(amount)
	else:
		amount_label.visible = false
