extends Control

signal piece_placed(color, location)


# Variables
var BOARDGP = null # Board Global Position coordinates (x,y)
var BOARDSIZE = null # Board Size in pixels (x,y)
var TILESIZE = null # Tile Size in pixels (x,y)

var PIECETYPES = [1,1,1] # List of all shapes of pieces
var PLAYERS = ["Y","R","G","B"] # List of colors denoting the four players
var curPlayer = null # Player whose turn it currently is

var pieceDict = {}	# Dictionary of all piece instances in game
					# Keys are piece instance IDs and values are dictionaries with attributes:
					# overBoard (whether the piece is hovering over the board area)
					# type (the shape of the piece)
					# color (the color of player who the piece belongs to)
var curPiece = null # The current piece being picked up or moved
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


func _ready():
	# Instantiate globals
	BOARDGP = $Board.rect_position
	BOARDSIZE = $Board.rect_size
	TILESIZE = $Board/BoardTiles.cell_size * $Board/BoardTiles.scale
	
	# Randomize player order
	randomize()
	PLAYERS.shuffle()
	print(PLAYERS)
	
	# Loop through players and instantiate their trays and pieces
	for color in PLAYERS:
		curPlayer = color
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
	# Remove start screen scene
	remove_child($StartScreen)

func _on_NextTurnButton_pressed():
	# Clear tray
	for piece in pieceDict:
		if pieceDict[piece]["color"]==curPlayer:
			piece.visible = false
	
	# Rotate Board
	
	# Change all cur variables
	var playerIndex = PLAYERS.find(curPlayer)
	if playerIndex == len(PLAYERS)-1:
		curPlayer = PLAYERS[0]
	else:
		curPlayer = PLAYERS[playerIndex+1]
	
	# Fill tray
	for piece in pieceDict:
		if pieceDict[piece]["color"]==curPlayer:
			piece.visible = true
	
	# Player name popup

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
	var pieceContainer = curPiece.get_parent()
	# Remove piece and pieceContainer from tray and add piece to HUD.
	pieceContainer.remove_child(curPiece)
	$PieceTray.get_node("TrayScroll"+curPlayer).get_node("InnerTray").remove_child(pieceContainer)
	add_child(curPiece)

func _on_Piece_dropped(id):
	print(str(id) + " Dropped")
	# Snap piece to nearest tile when dropped over board.
	if pieceDict[id]["overBoard"]:
		# Remove outline from nearest square.
		if curSelected != null:
			$Board/SelectionTiles.set_cellv(curSelected,-1)
			curSelected = null
		# Get board coordinate of drop.
		var nearestSquare = _get_nearest_square(id)
		var nearestSquareIndex = Vector2(nearestSquare.x/TILESIZE.x, nearestSquare.y/TILESIZE.y)
		# Remove piece from HUD and signal board that it has been placed.
		remove_child(id)
		emit_signal("piece_placed", id.get_color(), nearestSquareIndex)
	# Place piece back on tray if dropped anywhere other than board.
	else:
		remove_child(id)
		var type = pieceDict[id]["type"]
		pieceDict.erase(id)
		_instantiate_piece(type,curPlayer)
	curPiece = null
