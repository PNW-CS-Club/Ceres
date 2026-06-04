class_name Grid extends Node2D

# Will most likely store these values:
# null -> empty square
# Plant -> Node
# Debris -> Node

@export var WIDTH = 5
@export var HEIGHT = 5
var grid: Array[Node] = Array([], TYPE_OBJECT, "Node", null)
var plants: Array[Vector2i] # Array of pairs that marks squares with living plants

func _ready() -> void:
	#initialize grid
	for i in range(WIDTH * HEIGHT):
		grid.append(null)

## Access element at (x, y).
func at(pos: Vector2i) -> Node: 
	if !_oob_check(pos): return null
	return grid[pos.y * WIDTH + pos.x]

## Set element at (x, y).
func put(pos: Vector2i, node: Node) -> void: 
	if !_oob_check(pos): return
	
	grid[pos.y * WIDTH + pos.x] = node
	if node != null and node.is_class("Plant"):
		plants.append(pos)

## Returns whether the given coordinates are valid.
func is_in_bounds(coords: Vector2i) -> bool: 
	return clampi(coords.x, 0, WIDTH-1) == coords.x && clampi(coords.y, 0, HEIGHT-1) == coords.y

## Logs an error message if the coords are out of bounds
func _oob_check(coords: Vector2i) -> bool:
	var in_bounds = is_in_bounds(coords)
	if !in_bounds:
		printerr("Tile coordinates " + str(coords) + " are out of bounds")
	return in_bounds
