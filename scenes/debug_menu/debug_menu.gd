class_name DebugMenu extends Control

signal cheat_in_items(type: Item.Type, amount: int)
signal cheat_in_coins(amount: int)

@onready var item_type_picker: OptionButton = %ItemTypePicker
@onready var item_amount_picker: SpinBox = %ItemAmountPicker

@onready var coin_amount_picker: SpinBox = %CoinAmountPicker


func _ready() -> void:
	# add all the possible item types to item picker
	item_type_picker.clear()
	for key: String in Item.Type.keys():
		var words = key.to_lower().split("_", false)
		for i in words.size():
			words.set(i, words.get(i).capitalize())
		var item_name = " ".join(words)
		var value: Item.Type = Item.Type.get(key)
		item_type_picker.add_item(item_name, value)


func on_give_items_button():
	# send the cheat_in_items signal using the user's choices from the UI
	var type = item_type_picker.get_selected_id() as Item.Type
	var amount = item_amount_picker.value as int
	cheat_in_items.emit(type, amount)

func on_give_coins_button():
	cheat_in_coins.emit(coin_amount_picker.value as int)
