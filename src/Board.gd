extends Panel

var PLAYERS = ["Y","R","G","B"] # List of colors denoting the four players
var board = [] # Board matrix

# Helper functions
func print_board():
	for x in len(board):
		print(board[x])
		
func _rotate_board(numTurns):
	# Rotate the board clockwise by 90 degrees numTurns times.
	for _c in range(numTurns):
		var new_board = []
		for i in range(len(board[0])):
			var row = []
			for j in range(len(board)):
				row.append(board[len(board) - j - 1][i])
			new_board.append(row)
		board=new_board
	return board

func _redraw_tilemap(color):
	# Change all tiles that are not correctly drawn.
	for i in range(len(board)):
		for j in range(len(board[0])):
			if board[i][j] == color and get_node("PlacedTiles"+color).get_cell(j,i) != 0:
				get_node("PlacedTiles"+color).set_cellv(Vector2(j,i),0)
			elif board[i][j] != color  and get_node("PlacedTiles"+color).get_cell(j,i) != -1:
				get_node("PlacedTiles"+color).set_cellv(Vector2(j,i),-1)



func _ready():
	# Make empty board
	for x in range(20):
		board.append([])
		for _y in range(20):
			board[x].append("")
	#print_board()

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

func _on_HUD_rotate_board(numTurns):
	# Rotate board matrix
	_rotate_board(numTurns)
	
	# Rotate tilemaps
	for color in PLAYERS:
		_redraw_tilemap(color)
