extends Panel

# Declare member variables here. Examples:
var board = []

# Helper functions
func print_board():
	for x in len(board):
		print(board[x])

# Called when the node enters the scene tree for the first time.
func _ready():
	# Make empty board
	for x in range(20):
		board.append([])
		for _y in range(20):
			board[x].append("")
	#print_board()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


# Signal functions
func _on_HUD_piece_placed(color, location):
	# Add piece to board
	board[location.y][location.x] = color
#	print_board()
	get_node("PlacedTiles"+color).set_cellv(location,0)

func _on_HUD_piece_undone(color, location):
	# Remove piece from board
	board[location.y][location.x] = ""
#	print_board()
	get_node("PlacedTiles"+color).set_cellv(location,-1)
