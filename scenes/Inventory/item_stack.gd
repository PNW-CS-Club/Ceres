class_name ItemStack extends Control

@onready var item_sprite: TextureRect = %Item
@onready var amount_label: Label = %Label

# item and amount automatically update the gui when they are set
var item: Item: set = _update_item
var amount: int: set = _update_amount

func _update_item(value: Item): 
	item = value
	if not is_node_ready(): await ready
	
	if not item_sprite: printerr("(???) item_sprite is null"); return
	if not item: 
		item_sprite.hide()
		return
	item_sprite.show()
	item_sprite.texture = item.texture
	
func _update_amount(value: int): 
	amount = value
	if not is_node_ready(): await ready
	
	if !amount_label: printerr("(???) amount_label is null"); return
	if amount > 1:
		amount_label.show()
		amount_label.text = str(amount)
	else:
		amount_label.hide()
