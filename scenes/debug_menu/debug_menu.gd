class_name DebugMenu extends Control

signal cheat_in_items(item: Item.Type, amount: int)

@onready var item_picker: OptionButton = %ItemPicker
@onready var amount_picker: SpinBox = %AmountPicker


func _ready() -> void:
	# add all the possible item types to item picker
	item_picker.clear()
	for key: String in Item.Type.keys():
		var words = key.to_lower().split("_", false)
		for i in words.size():
			words.set(i, words.get(i).capitalize())
		var item_name = " ".join(words)
		var value: Item.Type = Item.Type.get(key)
		item_picker.add_item(item_name, value)


func on_add_button():
	# send the cheat_in_items signal using the user's choices from the UI
	var item = item_picker.get_selected_id() as Item.Type
	var amount = amount_picker.value as int
	cheat_in_items.emit(item, amount)
