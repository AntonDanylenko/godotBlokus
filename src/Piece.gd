extends Area2D

signal overBoard(id)
signal notOverBoard(id)
signal pickedup(id)
signal dropped(id)

# Declare member variables here. Examples:
var dragging = false
var mousePos = null

var color = "R"


# Helper functions
func get_color():
	return color


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if dragging:
		mousePos = get_global_mouse_position()
		$Sprite.global_position = mousePos
		$CollisionShape2D.global_position = mousePos


# Signal functions
func _on_Area2D_input_event(_viewport, event, _shape_idx):
	# Start and stop dragging at every mouse click
	if (event is InputEventMouseButton and 
		event.pressed and 
		event.button_index == BUTTON_LEFT):
#		print("Piece clicked")
#		print(self)
		if dragging:
			emit_signal('dropped', self)
		else:
			emit_signal('pickedup', self)
		dragging = not dragging

func _on_Piece_body_entered(_body):
	emit_signal('overBoard', self)

func _on_Piece_body_exited(_body):
	emit_signal('notOverBoard',self)