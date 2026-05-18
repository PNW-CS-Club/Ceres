extends PanelContainer
class_name Inventory

@onready var ItemStackScene = preload("res://scenes/Inventory/ItemStack.tscn")
@onready var slot_nodes: Array[Node] = $HBoxContainer.get_children()

var stack_in_hand: ItemStack


func _ready():
	_connect_slots()

func _connect_slots():
	for i in range(slot_nodes.size()):
		var slot_node: InventorySlot = slot_nodes[i]
		slot_node.index = i
		
		# causes on_slot_clicked(slot) to be called when slot is clicked
		var callable = Callable(_on_slot_clicked).bind(slot_node)
		slot_node.pressed.connect(callable)


func _on_slot_clicked(slot: InventorySlot):
	if !stack_in_hand && !slot.is_empty():
		_take_stack_from_slot(slot)
		return
	if slot.is_empty() && stack_in_hand:
		_put_stack_in_slot(slot)
		return
	if !slot.is_empty() && stack_in_hand:
		if stack_in_hand.item.type == slot.stack.item.type:
			_stack_onto_slot(slot)
		else:
			_swap_with_hand(slot)
		return

func _stack_onto_slot(slot: InventorySlot):
	# combine stacks
	if stack_in_hand.item.type == slot.stack.item.type:
		slot.stack.amount += stack_in_hand.amount
		remove_child(stack_in_hand)

func _swap_with_hand(slot: InventorySlot):
	var tmp_amt = stack_in_hand.amount
	var tmp_item = stack_in_hand.item
	stack_in_hand.amount = slot.stack.amount
	stack_in_hand.item = slot.stack.item
	slot.stack.amount = tmp_amt
	slot.stack.item = tmp_item
	
func _take_stack_from_slot(slot: InventorySlot):
	stack_in_hand = slot.take_stack()
	if stack_in_hand:
		add_child(stack_in_hand)
		_update_stack_in_hand()

# Inserts an Item
func _put_stack_in_slot(slot: InventorySlot):
	var item = stack_in_hand
	
	remove_child(stack_in_hand)
	stack_in_hand = null
	
	slot.put_stack(item)


## adds a given amount of the given item to the inventory
func add_item(item: Item, amount: int = 1):
	for slot in slot_nodes:
		if !slot.stack: continue
		if slot.stack.item.type == item.type:
			slot.stack.amount += amount
			return
	
	for slot in slot_nodes:
		if slot.is_empty():
			var new_stack = ItemStackScene.instantiate()
			new_stack.item = item
			new_stack.amount = amount
			slot.put_stack(new_stack)
			return
	
	printerr("Could not insert " + str(amount) + "x " + item.name + " into inventory")


## removes the given number of items (default 1) from the stack_in_hand, and returns whether it was successful
func remove_from_hand(amount: int = 1) -> bool:
	if stack_in_hand && stack_in_hand.amount >= amount:
		stack_in_hand.amount -= amount
		if stack_in_hand.amount == 0:
			remove_child(stack_in_hand)
			stack_in_hand = null
		return true
	else:
		return false

## removes the currently held item (if it exists) and adds it back to the inventory
func drop_stack() -> void:
	var stack = stack_in_hand
	if stack:
		add_item(stack.item, stack.amount)
		remove_from_hand(stack.amount)


# Centers the item on the cursor
func _update_stack_in_hand():
	if !stack_in_hand: return
	stack_in_hand.global_position = get_global_mouse_position() - stack_in_hand.size / 2

func _input(_event):
	_update_stack_in_hand()
