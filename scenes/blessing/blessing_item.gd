## A "slot" in the blessing screen that holds one stack of items.
## Has a button that accepts the item.
##
## Setting `quantity` and `item` will update the display, 
## and the `accept_blessing_item` signal will be emitted when the player presses the button.
class_name BlessingItem extends Control

signal accept_blessing_item(stack: ItemStack)

var quantity: int: set = _set_quantity
var item: Item: set = _set_item
var _is_accepted: bool = false

@onready var _name_label: Label = %NameLabel
@onready var _stack: ItemStack = %ItemStack
@onready var _desc_label: Label = %DescLabel
@onready var _accept_button: Button = %AcceptButton

#region Setter Methods
func _set_quantity(value: int) -> void:
	# quantity validation
	if value <= 0:
		printerr("attempted to set blessing item '%s' to a non-positive quantity (%d)" % 
				 [_stack.item.name, value])
		set_disabled(true)
				
	quantity = max(1, value)
	if not is_node_ready(): await ready
	
	_stack.amount = quantity

func _set_item(value: Item) -> void:
	item = value
	if not item: return
	if not is_node_ready(): await ready
	
	_stack.item = item
	_name_label.text = item.name
	_desc_label.text = item.desc
	
#endregion

func _emit_accept() -> void: 
	if _is_accepted: return # avoid giving a blessing more than once
	set_disabled(true)
	accept_blessing_item.emit(_stack)

func reset() -> void:
	set_disabled(false)

func set_disabled(disabled: bool) -> void:
	_is_accepted = disabled
	_accept_button.disabled = disabled
	
