extends Control

signal piece_placed(color, location)
signal piece_undone(color, location)
signal rotate_board(numTurns)


# Global Variables
var BOARDGP = null # Board Global Position coordinates (x,y)
var BOARDSIZE = null # Board Size in pixels (x,y)
var TILESIZE = null # Tile Size in pixels (x,y)

# Dict of all types of pieces with keys as piece names and values as piece shapes
#var PIECETYPES = {"1":[[1]]}
var PIECETYPES = {"5I":[[1],[1],[1],[1],[1]],"5L":[[1,0],[1,0],[1,0],[1,1]],"5Y":[[1,0],[1,1],[1,0],[1,0]],
					"5N":[[1,0],[1,1],[0,1],[0,1]],"5T":[[1,1,1],[0,1,0],[0,1,0]],"5V":[[1,0,0],[1,0,0],[1,1,1]],
					"5W":[[1,0,0],[1,1,0],[0,1,1]],"5X":[[0,1,0],[1,1,1],[0,1,0]],"5Z":[[1,1,0],[0,1,0],[0,1,1]],
					"5F":[[1,1,0],[0,1,1],[0,1,0]],"5U":[[1,1],[0,1],[1,1]],"5P":[[1,1],[1,1],[1,0]],
					"4I":[[1],[1],[1],[1]],"4L":[[1,0],[1,0],[1,1]],"4S":[[1,0],[1,1],[0,1]],
					"4T":[[1,0],[1,1],[1,0]],"4Q":[[1,1],[1,1]],
					"3I":[[1],[1],[1]],"3L":[[1,0],[1,1]], "2":[[1],[1]], "1":[[1]]}

var PLAYERS = ["Y","R","G","B"] # List of colors denoting the four players
var FULLCOLORNAMES = {"Y":"Yellow","R":"Red","G":"Green","B":"Blue"} # Color names expanded
var HEXCOLORVALUES = {"Y":"e2e152","R":"e41f1f","G":"3fa92e","B":"3d63dd"} # Hexes of colors
var curPlayer = null # Player whose turn it currently is

var pieceDict = {}	# Dictionary of all piece instances in game
					# Keys are piece instance IDs and values are dictionaries with attributes:
					# overBoard (whether the piece is hovering over the board area)
					# type_matrix (the matrix of the shape of the piece)
					# color (the color of player who the piece belongs to)
var curPiece = null # The current piece being picked up or moved
var curContainer = null # The container of the curPiece in the tray
var locationPlaced = null # Location where curPiece was placed
var curSelected = null # The current board square closest to the moving piece
var canPress = true # Whether any of the rotation buttons can be pressed


# Helper functions
func _get_nearest_square(piece):
	# Get the relative board location of the board square that is nearest the moving piece.
#	print(piece)
	var pieceGP = piece.get_node("CollisionShape2D").global_position
	var piecePosition = Vector2(pieceGP.x-BOARDGP.x,pieceGP.y-BOARDGP.y)
	var nearestSquare = Vector2(clamp(stepify(piecePosition.x-TILESIZE.x/2, TILESIZE.x),0,BOARDSIZE.x-TILESIZE.x),
								clamp(stepify(piecePosition.y-TILESIZE.y/2, TILESIZE.y),0,BOARDSIZE.y-TILESIZE.y))
	return nearestSquare

func _can_place_more(color, matrices):
#	print(color + str(matrices))
	# Check if any remaining pieces of the color can be placed anywhere on the board in any orientation.
	var transformations = [0,1,1,1,2,1,1,1] # Cover all orientations
	for transformation in transformations:
		for index in range(len(matrices)-1,-1,-1):
#			print(matrices[index])
			if transformation>0:
				matrices[index] = _rotate_piece(matrices[index],"clockwise")
				if transformation>1:
					matrices[index] = _flip_piece(matrices[index])
			if $Board.can_place_anywhere(color,matrices[index]):
				return true
	return false

func _rotate_piece(piece_matrix, direction):
	# Rotate the piece matrix 90 degrees in the direction given.
	var new_matrix = []
	for i in range(len(piece_matrix[0])):
		var row = []
		for j in range(len(piece_matrix)):
			if direction=="clockwise":
				row.append(piece_matrix[len(piece_matrix) - j - 1][i])
			elif direction=="counterclockwise":
				row.append(piece_matrix[j][len(piece_matrix[0]) - i - 1])
		new_matrix.append(row)
	piece_matrix=new_matrix
	return piece_matrix

func _flip_piece(piece_matrix):
	# Flip the piece matrix horizontally.
	var new_matrix = []
	for i in range(len(piece_matrix)):
		var row = []
		for j in range(len(piece_matrix[0])):
			row.append(piece_matrix[i][len(piece_matrix[0])-j-1])
		new_matrix.append(row)
	piece_matrix=new_matrix
	return piece_matrix

func _reposition_sprites(type_matrix):
	# Reposition sprites based on new type_matrix
	var origin = curPiece.get_node("CollisionShape2D").position
	var sprites = []
	for child in curPiece.get_children():
		if child.get_class() == "Sprite":
			sprites.append(child)
	var index = 0
	for i in range(len(type_matrix)):
		for j in range(len(type_matrix[0])):
			if type_matrix[i][j]:
				sprites[index].position = Vector2(origin.x + j*TILESIZE.x,origin.y + i*TILESIZE.y)
				index+=1

func _instantiate_tray(player):
	# Instantiate the starting tray and pieces for a player
	var trayScroll = ScrollContainer.new()
	trayScroll.name = "TrayScroll" + player
	trayScroll.rect_position = Vector2(8,8)
	trayScroll.rect_size = Vector2(864,284)
	trayScroll.rect_min_size = Vector2(864,284)
	trayScroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	trayScroll.scroll_vertical_enabled = false
	$PieceTray.add_child(trayScroll)
	var innerTray = HBoxContainer.new()
	innerTray.name = "InnerTray"
	innerTray.rect_size = Vector2(864,270)
	innerTray.rect_min_size = Vector2(864,270)
	innerTray.mouse_filter = Control.MOUSE_FILTER_IGNORE
	trayScroll.add_child(innerTray)
	for type in PIECETYPES:
		_instantiate_piece(type,player)
	trayScroll.visible = false

func _instantiate_piece(type,player):
	# Instantiate a piece
	var pieceContainerScene = load("res://data/PieceContainer.tscn")
	var pieceContainer = pieceContainerScene.instance()
	$PieceTray.get_node("TrayScroll"+player).get_node("InnerTray").add_child(pieceContainer)
	var type_matrix = PIECETYPES[type]
	pieceContainer.rect_min_size = Vector2(TILESIZE.x*(len(type_matrix[0])+1),TILESIZE.y*(len(type_matrix)+1))
	var piece = pieceContainer.get_node("Piece")
	piece.set_color(player)
	_create_piece_shape(piece,type_matrix)
	# Connect signals
	piece.connect("pickedup", self, "_on_Piece_pickedup")
	piece.connect("dropped", self, "_on_Piece_dropped")
	piece.connect("overBoard", self, "_on_Piece_overBoard")
	piece.connect("notOverBoard", self, "_on_Piece_notOverBoard")
	# Instantiate pieceDict
	pieceDict[piece] = {}
	pieceDict[piece]["overBoard"] = false
	pieceDict[piece]["type_matrix"] = type_matrix
	pieceDict[piece]["color"] = player
	# Hide piece visibility
	piece.visible = false
	return piece

func _create_piece_shape(piece,type_matrix):
	# Creates piece node based off its type_matrix
	var origin = piece.get_node("CollisionShape2D").position
	var origin_established = false
	for i in range(len(type_matrix)):
		for j in range(len(type_matrix[0])):
			if type_matrix[i][j]:
				# Shift origin piece if no square in top left corner of piece
				if not origin_established:
#					piece.get_node("CollisionShape2D").position = Vector2(origin.x + j*TILESIZE.x,origin.y + i*TILESIZE.y)
					piece.get_node("Sprite").position = Vector2(origin.x + j*TILESIZE.x,origin.y + i*TILESIZE.y)
					origin_established = true
				else:
					var new_square = piece.get_node("Sprite").duplicate()
					piece.add_child(new_square)
					new_square.position = Vector2(origin.x + j*TILESIZE.x,origin.y + i*TILESIZE.y)

func _reset_piece_on_tray():
	# Put piece back into container in tray and center it
	curContainer.add_child(curPiece)
	var type_matrix = pieceDict[curPiece]["type_matrix"]
	curContainer.rect_min_size = Vector2(TILESIZE.x*(len(type_matrix[0])+1),TILESIZE.y*(len(type_matrix)+1))
	curPiece.position = Vector2(TILESIZE.x,TILESIZE.y)
	# Make everything visible and reset curPiece variable
	curContainer.visible = true
	curPiece.visible = true
	curPiece = null
	curContainer = null
	locationPlaced = null
	# Disable undo and next turn buttons
	$UndoButton.disabled = true
	$NextTurnButton.disabled = true

func _count_squares(matrix):
	# Count number of squares in given piece matrix.
	var count = 0
	for i in range(len(matrix)):
		for j in range(len(matrix[0])):
			count+=matrix[i][j]
	return count

func _end_game_screen():
	# End Game screen
	var endScreenScene = load("res://data/EndScreen.tscn")
	var endScreen = endScreenScene.instance()
	add_child(endScreen)
	
	# Calculate final scores
	var scores = [0,0,0,0]
	for piece in pieceDict:
		var index = PLAYERS.find(pieceDict[piece]["color"])
		scores[index] += _count_squares(pieceDict[piece]["type_matrix"])
	
	# Get winner(s)
	var winners = [0]
	var minScore = scores[0]
	for index in range(1,len(scores)):
		if scores[index]<minScore:
			winners = [index]
			minScore = scores[index]
		elif scores[index]==minScore:
			winners.append(index)
	
	var scoresLabel = endScreen.get_node("Panel").get_node("Scores")
	var scoresLabelContents = "[center]"
	for index in range(len(scores)):
		var player = PLAYERS[index]
		scoresLabelContents = scoresLabelContents + "[color=#" + HEXCOLORVALUES[player] + "]"
		scoresLabelContents = scoresLabelContents + FULLCOLORNAMES[player] + "[/color]: " + str(scores[index]) + "\n"
	scoresLabelContents += "[/center]"
	scoresLabel.bbcode_text = scoresLabelContents
	
	var winnerLabel = endScreen.get_node("Panel").get_node("WINNER")
	var winnerLabelContents = "[center]"
	for windex in range(len(winners)):
		var player = PLAYERS[winners[windex]]
		winnerLabelContents = winnerLabelContents + "[color=#" + HEXCOLORVALUES[player] + "]"
		winnerLabelContents = winnerLabelContents + FULLCOLORNAMES[player] + "[/color]"
		if windex != len(winners)-1:
			winnerLabelContents += " & "
	if len(winners)>1:
		winnerLabelContents += "\nWIN"
		winnerLabel.rect_size.y = 300
		scoresLabel.rect_position.y = 475
	else:
		winnerLabelContents += " WINS"
	winnerLabelContents += "[/center]"
	winnerLabel.bbcode_text = winnerLabelContents
	
	endScreen.get_node("Panel").get_node("NewGameButton").connect("pressed", self, "_on_Restart_pressed")



func _ready():
	# Instantiate globals
	BOARDGP = $Board.rect_position
	BOARDSIZE = $Board.rect_size
	TILESIZE = $Board/BoardTiles.cell_size * $Board/BoardTiles.scale
	
	# Randomize player order
	randomize()
	PLAYERS.shuffle()
	print(PLAYERS)
	
	# Loop through players and instantiate the name headers, trays, and pieces
	var playerLabelScene = load("res://data/HeaderLabel.tscn")
	for color in PLAYERS:
		curPlayer = color
		# Player name header
		var curPlayerLabel = playerLabelScene.instance()
		curPlayerLabel.name = "playerHeader" + curPlayer
		curPlayerLabel.text = FULLCOLORNAMES[curPlayer]
		curPlayerLabel.set("custom_colors/font_color", Color(HEXCOLORVALUES[curPlayer]))
		add_child(curPlayerLabel)
		curPlayerLabel.visible = false
		# Tray and pieces
		_instantiate_tray(curPlayer)
	
	# Start Game screen
	var startScreenScene = load("res://data/StartScreen.tscn")
	var startScreen = startScreenScene.instance()
	add_child(startScreen)
	startScreen.get_node("StartGameButton").connect("pressed", self, "_on_Start_pressed")


func _process(_delta):
	# Keybinds for piece rotations.
	if Input.is_action_pressed("Rotate Left"):
		if canPress:
			_on_LeftRotateButton_pressed()
			canPress = false
			$ButtonTimer.start()
	if Input.is_action_pressed("Rotate Right"):
		if canPress:
			_on_RightRotateButton_pressed()
			canPress = false
			$ButtonTimer.start()
	if Input.is_action_pressed("Flip"):
		if canPress:
			_on_FlipButton_pressed()
			canPress = false
			$ButtonTimer.start()
	
	# Draw green outline around nearest square to piece.
	if curPiece!=null and pieceDict[curPiece]["overBoard"]:
		var nearestSquare = _get_nearest_square(curPiece)
		var nearestIndex = Vector2(nearestSquare.x/TILESIZE.x,nearestSquare.y/TILESIZE.y)
#		print(nearestIndex)
		if curSelected != nearestIndex:
#			print("Changing selected tile")
			if curSelected != null:
				$Board/SelectionTiles.set_cellv(curSelected,-1)
			$Board/SelectionTiles.set_cellv(nearestIndex,0)
			if $Board.can_place(curPiece.get_color(), pieceDict[curPiece]["type_matrix"], nearestIndex):
				$Board/SelectionTiles.modulate = Color("#a8e61d")
			else:
				$Board/SelectionTiles.modulate = Color("#ff4d4d")
			curSelected = nearestIndex


# Signal functions
func _on_Start_pressed():
	curPlayer = PLAYERS[0]
	# Unhide first player's pieces
	for piece in pieceDict:
		if pieceDict[piece]["color"]==curPlayer:
			piece.visible = true
	$PieceTray.get_node("TrayScroll"+curPlayer).visible = true
	# Unhide header
	get_node("playerHeader" + curPlayer).visible = true
	# Remove start screen scene
	remove_child($StartScreen)

func _on_Restart_pressed():
	var reloaded = get_tree().reload_current_scene()
	print(reloaded)

func _on_NextTurnButton_pressed():
	# Disable undo and next turn buttons
	$UndoButton.disabled = true
	$NextTurnButton.disabled = true
	
	# Remove used piece and its container
	pieceDict.erase(curPiece)
	if curPiece:
		curPiece.queue_free()
	if curContainer:
		curContainer.queue_free()
	curPiece = null
	curContainer = null
	locationPlaced = null
	
	# Clear tray and header
	for piece in pieceDict:
		if pieceDict[piece]["color"]==curPlayer:
			piece.visible = false
	$PieceTray.get_node("TrayScroll"+curPlayer).visible = false
	get_node("playerHeader" + curPlayer).visible = false
	
	# Rotate Board
	emit_signal("rotate_board",1)
	
	# Change curPlayer
	var playerIndex = PLAYERS.find(curPlayer)
	if playerIndex == len(PLAYERS)-1:
		curPlayer = PLAYERS[0]
	else:
		curPlayer = PLAYERS[playerIndex+1]
	
	# Variable to keep track of whether all players are done placing.
	var skipCount = 0
	
	# Make temp list of all remaining piece matrices.
	var matrices = []
	for piece in pieceDict:
		if pieceDict[piece]["color"]==curPlayer:
			matrices.append(pieceDict[piece]["type_matrix"])
	# Check if player can place any more pieces, skip turn if can't.
	var goNext = not _can_place_more(curPlayer, matrices)
	while goNext:
		skipCount+=1
		if skipCount>3:
			print("All Players Done!")
			_end_game_screen()
			goNext = false
		else:
			# Player done popup
			print(curPlayer + " done.")
			
			# Rotate Board
			emit_signal("rotate_board",1)
			
			# Change curPlayer
			playerIndex = PLAYERS.find(curPlayer)
			if playerIndex == len(PLAYERS)-1:
				curPlayer = PLAYERS[0]
			else:
				curPlayer = PLAYERS[playerIndex+1]
			
			# Make temp list of all remaining piece matrices.
			matrices = []
			for piece in pieceDict:
				if pieceDict[piece]["color"]==curPlayer:
					matrices.append(pieceDict[piece]["type_matrix"])
			goNext = not _can_place_more(curPlayer, matrices)
	
	# Fill tray
	for piece in pieceDict:
		if pieceDict[piece]["color"]==curPlayer:
			piece.visible = true
	$PieceTray.get_node("TrayScroll"+curPlayer).visible = true
	
	# Unrestrict tray
	$PieceTray.get_node("TrayScroll"+curPlayer).get_node("InnerTray").mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Player name header and popup
	get_node("playerHeader" + curPlayer).visible = true
	

func _on_Piece_overBoard(id):
	# Get signal when piece is over the board.
#	print(str(id) + " Over Board")
	pieceDict[id]["overBoard"] = true
	if curSelected != null:
		$Board/SelectionTiles.set_cellv(curSelected,0)

func _on_Piece_notOverBoard(id):
	# Get signal when piece has left the board.
#	print(str(id) + " Left Board")
	pieceDict[id]["overBoard"] = false
	if curSelected!=null:
		$Board/SelectionTiles.set_cellv(curSelected,-1)
	
func _on_Piece_pickedup(id):
#	print(str(id) + " Picked Up")
	curPiece = id
	curContainer = curPiece.get_parent()
	# Remove piece from tray and add to HUD.
	curContainer.remove_child(curPiece)
	curContainer.visible = false
	add_child(curPiece)
	# Enable rotate and flip buttons
	$LeftRotateButton.disabled = false
	$RightRotateButton.disabled = false
	$FlipButton.disabled = false

func _on_Piece_dropped():
#	print(str(curPiece) + " Dropped")
	# Snap piece to nearest tile when dropped over board.
	if pieceDict[curPiece]["overBoard"]:
		# Remove outline from nearest square.
		if curSelected != null:
			$Board/SelectionTiles.set_cellv(curSelected,-1)
			curSelected = null
		# Get board coordinate of drop.
		var nearestSquare = _get_nearest_square(curPiece)
		locationPlaced = Vector2(nearestSquare.x/TILESIZE.x, nearestSquare.y/TILESIZE.y)
		# Check if can place
		if $Board.can_place(curPiece.get_color(), pieceDict[curPiece]["type_matrix"], locationPlaced):
			# Remove piece from HUD, and signal board that it has been placed.
			remove_child(curPiece)
			emit_signal("piece_placed", curPiece.get_color(), pieceDict[curPiece]["type_matrix"], locationPlaced)
			# Enable undo and next turn
			$UndoButton.disabled = false
			$NextTurnButton.disabled = false
			# Restrict tray
			$PieceTray.get_node("TrayScroll"+curPlayer).get_node("InnerTray").mouse_filter = Control.MOUSE_FILTER_STOP
		else:
			remove_child(curPiece)
			_reset_piece_on_tray()
	# Place piece back on tray if dropped anywhere other than board.
	else:
		remove_child(curPiece)
		_reset_piece_on_tray()

func _on_UndoButton_pressed():
	# Remove recently used piece from board and place back on tray
	emit_signal("piece_undone", curPiece.get_color(), pieceDict[curPiece]["type_matrix"], locationPlaced)
	_reset_piece_on_tray()
	# Unrestrict tray
	$PieceTray.get_node("TrayScroll"+curPlayer).get_node("InnerTray").mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_LeftRotateButton_pressed():
	if curPiece:
		# Rotate matrix
		pieceDict[curPiece]["type_matrix"] = _rotate_piece(pieceDict[curPiece]["type_matrix"],"counterclockwise")
		# Rotate sprites
		_reposition_sprites(pieceDict[curPiece]["type_matrix"])

func _on_RightRotateButton_pressed():
	if curPiece:
		# Rotate matrix
		pieceDict[curPiece]["type_matrix"] = _rotate_piece(pieceDict[curPiece]["type_matrix"],"clockwise")
		# Rotate sprites
		_reposition_sprites(pieceDict[curPiece]["type_matrix"])

func _on_FlipButton_pressed():
	if curPiece:
		# Flip matrix
		pieceDict[curPiece]["type_matrix"] = _flip_piece(pieceDict[curPiece]["type_matrix"])
		# Flip sprites
		_reposition_sprites(pieceDict[curPiece]["type_matrix"])

func _on_ButtonTimer_timeout():
	canPress = true
