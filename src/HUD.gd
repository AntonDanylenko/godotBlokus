extends Control

signal piece_placed(color, location)
signal piece_undone(color, location)


# Variables
var BOARDGP = null # Board Global Position coordinates (x,y)
var BOARDSIZE = null # Board Size in pixels (x,y)
var TILESIZE = null # Tile Size in pixels (x,y)

var PIECETYPES = [1,1,1] # List of all shapes of pieces
var PLAYERS = ["Y","R","G","B"] # List of colors denoting the four players
var FULLCOLORNAMES = {"Y":"Yellow","R":"Red","G":"Green","B":"Blue"} # Color names expanded
var HEXCOLORVALUES = {"Y":"e2e152","R":"e41f1f","G":"3fa92e","B":"3d63dd"} # Hexes of colors
var curPlayer = null # Player whose turn it currently is

var pieceDict = {}	# Dictionary of all piece instances in game
					# Keys are piece instance IDs and values are dictionaries with attributes:
					# overBoard (whether the piece is hovering over the board area)
					# type (the shape of the piece)
					# color (the color of player who the piece belongs to)
var curPiece = null # The current piece being picked up or moved
var curContainer = null # The container of the curPiece in the tray
var locationPlaced = null # Location where curPiece was placed
var curSelected = null # The current board square closest to the moving piece


# Helper functions
func _get_nearest_square(piece):
	# Get the relative board location of the board square that is nearest the moving piece.
#	print(piece)
	var pieceGP = piece.get_node("Sprite").global_position
	var piecePosition = Vector2(pieceGP.x-BOARDGP.x,pieceGP.y-BOARDGP.y)
	var nearestSquare = Vector2(clamp(stepify(piecePosition.x-TILESIZE.x/2, TILESIZE.x),0,BOARDSIZE.x-TILESIZE.x),
								clamp(stepify(piecePosition.y-TILESIZE.y/2, TILESIZE.y),0,BOARDSIZE.y-TILESIZE.y))
	return nearestSquare

func _instantiate_tray(player):
	# Instantiate the starting tray and pieces for a player
	var trayScroll = ScrollContainer.new()
	trayScroll.name = "TrayScroll" + player
	trayScroll.rect_position = Vector2(8,8)
	trayScroll.rect_size = Vector2(864,224)
	trayScroll.rect_min_size = Vector2(864,224)
	trayScroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	trayScroll.scroll_vertical_enabled = false
	$PieceTray.add_child(trayScroll)
	var innerTray = HBoxContainer.new()
	innerTray.name = "InnerTray"
	innerTray.rect_size = Vector2(864,210)
	innerTray.rect_min_size = Vector2(864,210)
	innerTray.mouse_filter = Control.MOUSE_FILTER_IGNORE
	trayScroll.add_child(innerTray)
	for type in PIECETYPES:
		_instantiate_piece(type,player)

func _instantiate_piece(type,player):
	# Instantiate a piece
	var pieceContainerScene = load("res://data/PieceContainer.tscn")
	var pieceContainer = pieceContainerScene.instance()
	$PieceTray.get_node("TrayScroll"+player).get_node("InnerTray").add_child(pieceContainer)
	var piece = pieceContainer.get_node("Piece")
	piece.set_color(player)
	# Connect signals
	piece.connect("pickedup", self, "_on_Piece_pickedup")
	piece.connect("dropped", self, "_on_Piece_dropped")
	piece.connect("overBoard", self, "_on_Piece_overBoard")
	piece.connect("notOverBoard", self, "_on_Piece_notOverBoard")
	# Instantiate pieceDict
	pieceDict[piece] = {}
	pieceDict[piece]["overBoard"] = false
	pieceDict[piece]["type"] = type
	pieceDict[piece]["color"] = player
	# Hide piece visibility
	piece.visible = false
	return piece

func _reset_piece_on_tray():
	# Put piece back into container in tray and center it
	curContainer.add_child(curPiece)
	curPiece.get_node("CollisionShape2D").position = Vector2(0,0)
	curPiece.get_node("Sprite").position = Vector2(0,0)
	# Make everything visible and reset curPiece variable
	curContainer.visible = true
	curPiece.visible = true
	curPiece = null
	curContainer = null
	locationPlaced = null
	# Disable undo button
	$UndoButton.disabled = true



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
	startScreen.get_node("StartGameButton").connect("pressed", self, "_on_Start_Pressed")


func _process(_delta):
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
			curSelected = nearestIndex


# Signal functions
func _on_Start_Pressed():
	curPlayer = PLAYERS[0]
	# Unhide first player's pieces
	for piece in pieceDict:
		if pieceDict[piece]["color"]==curPlayer:
			piece.visible = true
	# Unhide header
	get_node("playerHeader" + curPlayer).visible = true
	# Remove start screen scene
	remove_child($StartScreen)

func _on_NextTurnButton_pressed():
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
	get_node("playerHeader" + curPlayer).visible = false
	
	# Rotate Board
	
	# Change all cur variables
	var playerIndex = PLAYERS.find(curPlayer)
	if playerIndex == len(PLAYERS)-1:
		curPlayer = PLAYERS[0]
	else:
		curPlayer = PLAYERS[playerIndex+1]
	
	# Disable undo button
	$UndoButton.disabled = true
	
	# Fill tray
	for piece in pieceDict:
		if pieceDict[piece]["color"]==curPlayer:
			piece.visible = true
	
	# Player name header and popup
	get_node("playerHeader" + curPlayer).visible = true
	

func _on_Piece_overBoard(id):
	# Get signal when piece is over the board.
	print(str(id) + " Over Board")
	pieceDict[id]["overBoard"] = true
	if curSelected != null:
		$Board/SelectionTiles.set_cellv(curSelected,0)

func _on_Piece_notOverBoard(id):
	# Get signal when piece has left the board.
	print(str(id) + " Left Board")
	pieceDict[id]["overBoard"] = false
	if curSelected!=null:
		$Board/SelectionTiles.set_cellv(curSelected,-1)
	
func _on_Piece_pickedup(id):
	print(str(id) + " Picked Up")
	curPiece = id
	curContainer = curPiece.get_parent()
	# Remove piece from tray and add to HUD.
	curContainer.remove_child(curPiece)
	curContainer.visible = false
	add_child(curPiece)

func _on_Piece_dropped():
	print(str(curPiece) + " Dropped")
	# Snap piece to nearest tile when dropped over board.
	if pieceDict[curPiece]["overBoard"]:
		# Remove outline from nearest square.
		if curSelected != null:
			$Board/SelectionTiles.set_cellv(curSelected,-1)
			curSelected = null
		# Get board coordinate of drop.
		var nearestSquare = _get_nearest_square(curPiece)
		locationPlaced = Vector2(nearestSquare.x/TILESIZE.x, nearestSquare.y/TILESIZE.y)
		# Remove piece from HUD, and signal board that it has been placed.
		remove_child(curPiece)
		emit_signal("piece_placed", curPiece.get_color(), locationPlaced)
		# Prepare undo functionality
		$UndoButton.disabled = false
		# Restrict tray
#		$PieceTray.disabled = true
	# Place piece back on tray if dropped anywhere other than board.
	else:
		remove_child(curPiece)
		_reset_piece_on_tray()

func _on_UndoButton_pressed():
	# Remove recently used piece from board and place back on tray
	emit_signal("piece_undone", curPiece.get_color(), locationPlaced)
	_reset_piece_on_tray()
