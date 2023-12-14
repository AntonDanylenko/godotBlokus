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

func can_place(color, matrix, location):
	# Check if piece can be placed
	for i in range(len(matrix)):
		for j in range(len(matrix[0])):
			if matrix[i][j]:
				var board_i = location.y+i
				var board_j = location.x+j
				# Check if piece out of board bounds, 
				# overlaps another piece, 
				# or sides a piece of same color
				if (board_i>=len(board) or board_j>=len(board[0]) or
					board[board_i][board_j] != "" or
					(board_i-1>=0 and board[board_i-1][board_j] == color) or 
					(board_j-1>=0 and board[board_i][board_j-1] == color) or
					(board_i+1<len(board) and board[board_i+1][board_j] == color) or 
					(board_j+1<len(board[0]) and board[board_i][board_j+1] == color)):
						return false
	return true


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
func _on_HUD_piece_placed(color, matrix, location):
	# Add piece to board
	for i in range(len(matrix)):
		for j in range(len(matrix[0])):
			if matrix[i][j]:
				board[location.y+i][location.x+j] = color
				get_node("PlacedTiles"+color).set_cellv(Vector2(location.x+j,location.y+i),0)

func _on_HUD_piece_undone(color, matrix, location):
	# Remove piece from board
	for i in range(len(matrix)):
		for j in range(len(matrix[0])):
			if matrix[i][j]:
				board[location.y+i][location.x+j] = ""
				get_node("PlacedTiles"+color).set_cellv(Vector2(location.x+j,location.y+i),-1)

func _on_HUD_rotate_board(numTurns):
	# Rotate board matrix
	_rotate_board(numTurns)
	
	# Rotate tilemaps
	for color in PLAYERS:
		_redraw_tilemap(color)
