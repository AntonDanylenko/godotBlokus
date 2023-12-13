extends Area2D

signal overBoard(id)
signal notOverBoard(id)
signal pickedup(id)
signal dropped()

# Variables
var COLORS = {"R":"e41f1f","G":"3fa92e","B":"3d63dd","Y":"e2e152"}
var dragging = false
var mousePos = null

var color = null


# Helper functions
func get_color():
	return color

func set_color(input):
	# Set color of all sprites
	color = input
	for child in get_children():
		if child.get_class() == "Sprite":
			child.self_modulate = COLORS[color]

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if dragging:
		mousePos = get_global_mouse_position()
		self.position = mousePos


# Signal functions
func _on_Piece_input_event(_viewport, event, _shape_idx):
	# Start and stop dragging at every mouse click
	if (event is InputEventMouseButton and 
		event.pressed and 
		event.button_index == BUTTON_LEFT):
#		print("Piece clicked")
#		print(self)
		if dragging:
			emit_signal('dropped')
		else:
			emit_signal('pickedup', self)
		dragging = not dragging

func _on_Piece_body_entered(_body):
	emit_signal('overBoard', self)

func _on_Piece_body_exited(_body):
	emit_signal('notOverBoard',self)
