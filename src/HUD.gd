extends Control

signal piece_placed(color, location)


# Declare variables here.
var BOARDGP = null
var BOARDSIZE = null
var TILESIZE = null
var TRAYGP = null
var PLAYERS = ["R","G","B","Y"]

var curPlayer = null

var pieceDict = {}
var curPiece = null
var curSelected = null

# Helper functions
func _get_nearest_square(piece):
	# Get the relative board location of the square that is nearest the piece.
#	print(piece)
	var pieceGP = piece.get_node("Sprite").global_position
	var piecePosition = Vector2(pieceGP.x-BOARDGP.x,pieceGP.y-BOARDGP.y)
	var nearestSquare = Vector2(clamp(stepify(piecePosition.x-TILESIZE.x/2, TILESIZE.x),0,BOARDSIZE.x-TILESIZE.x),
								clamp(stepify(piecePosition.y-TILESIZE.y/2, TILESIZE.y),0,BOARDSIZE.y-TILESIZE.y))
	return nearestSquare


func _ready():
	# Instantiate globals
	BOARDGP = $Board.rect_position
	BOARDSIZE = $Board.rect_size
	TILESIZE = $Board/BoardTiles.cell_size * $Board/BoardTiles.scale
	TRAYGP = $PieceTray/TrayScroll/InnerTray.rect_position
	var pieceContainerScene = load("res://data/PieceContainer.tscn")
	
	# Instantiate pieces
	# Set piece locations on piece tray, connect signals, and instantiate pieceDict.
	for _i in range(3):
		var pieceContainer = pieceContainerScene.instance()
		$PieceTray/TrayScroll/InnerTray.add_child(pieceContainer)
		var piece = pieceContainer.get_node("Piece")
#		var piecePosition = Vector2(TRAYGP.x + i*TILESIZE.x*2,TRAYGP.y)
#		piece.get_node("Sprite").global_position = piecePosition 
#		piece.get_node("CollisionShape2D").global_position = piecePosition
		piece.connect("pickedup", self, "_on_Piece_pickedup")
		piece.connect("dropped", self, "_on_Piece_dropped")
		piece.connect("overBoard", self, "_on_Piece_overBoard")
		piece.connect("notOverBoard", self, "_on_Piece_notOverBoard")
		pieceDict[piece] = {}
		pieceDict[piece]["overBoard"] = false


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
	$PieceTray/TrayScroll/InnerTray.remove_child(pieceContainer)
	add_child(curPiece)

func _on_Piece_dropped(id):
	# Snap piece to nearest tile when dropped over board.
	print(str(id) + " Dropped")
	if pieceDict[id]["overBoard"]:
		# Remove outline from nearest square.
		if curSelected != null:
			$Board/SelectionTiles.set_cellv(curSelected,-1)
			curSelected = null
		# Get board coordinate of drop.
		var nearestSquare = _get_nearest_square(id)
#		var globalNearestSquare = Vector2(nearestSquare.x+BOARDGP.x+TILESIZE.x/2,nearestSquare.y+BOARDGP.y+TILESIZE.y/2)
#		id.get_node("Sprite").global_position = globalNearestSquare
#		id.get_node("CollisionShape2D").global_position = globalNearestSquare
		var nearestSquareIndex = Vector2(nearestSquare.x/TILESIZE.x, nearestSquare.y/TILESIZE.y)
		remove_child(id)
		emit_signal("piece_placed", id.get_color(), nearestSquareIndex)
	else:
		$PieceTray/TrayScroll/InnerTray.add_child(id)
	curPiece = null
