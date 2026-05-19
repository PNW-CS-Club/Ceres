class_name Wallet extends Control

@onready var coin_label: Label = %CoinLabel

#our currency for the game
var coins: int

#the ready function will display the amount of coins on the screen
func _ready() -> void:
	coin_label.text = str(coins)

## adds `amount` to balance (may be negative)
func change_balance(amount: int) -> void:
	coins += amount
	coin_label.text = str(coins)
