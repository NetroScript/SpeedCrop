@tool
extends PanelContainer

@export
var element_to_resize: Control

@export
var bar_width: float = 2

@export
var is_horizontal: bool = true : 
	set(value): 
		is_horizontal = value
		# Change the expand margins of the container
		if margin:
			if is_horizontal:
				margin.add_theme_constant_override("margin_bottom", 4)
				margin.add_theme_constant_override("margin_top", 4)
				margin.add_theme_constant_override("margin_left", 14)
				margin.add_theme_constant_override("margin_right", 14)
				%ResizeHandle.custom_minimum_size = Vector2(0.0, bar_width)
			else:
				margin.add_theme_constant_override("margin_bottom", 14)
				margin.add_theme_constant_override("margin_top", 14)
				margin.add_theme_constant_override("margin_left", 4)
				margin.add_theme_constant_override("margin_right", 4)
				%ResizeHandle.custom_minimum_size = Vector2(bar_width, 0.0)
		

@export
var minimal_size: int = 100
@export 
var maximal_size: int = -1

var being_hovered: bool = false
# Have a custom flag to enforce updates even with fast mouse movements
var currently_moving: bool = false
var starting_mouse_position: Vector2
var starting_min_size: Vector2
var minimum_difference: Vector2 

@onready
var margin: MarginContainer = %Margin

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	# Trigger correct sizing once with the setter
	self.is_horizontal = is_horizontal
	
	if is_horizontal:
		mouse_default_cursor_shape = Control.CURSOR_VSIZE
	else:
		mouse_default_cursor_shape = Control.CURSOR_HSIZE
	
	# Stay true to the minimal size by checking the current element
	if element_to_resize:
		if is_horizontal:
			minimal_size = max(minimal_size,element_to_resize.custom_minimum_size.y)
		else:
			minimal_size = max(minimal_size,element_to_resize.custom_minimum_size.x)
	
	if not Engine.is_editor_hint():
		mouse_entered.connect(
			func():
				being_hovered = true
		)
		mouse_exited.connect(
			func():
				being_hovered = false
		)

# Called on GUI input
func _input(event: InputEvent) -> void:
	
	if element_to_resize == null:
		return
	
	# Check if we arer in a mouse button event
	if event is InputEventMouseButton:
	
		# Check if the mouse is inside and the mouse is currently being pressed down
		if being_hovered and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			
			# Store the mouse position
			starting_mouse_position = get_global_mouse_position()
			starting_min_size = element_to_resize.custom_minimum_size
			
			# Ensure the minimal_size, for that store what the maximal distance could be
			# If the starting width is 50 for example, the difference would be 50, so the minimum for each differences will be clamped to 50 and above
			# If it would be 200, the difference would be -150, so we can go down up to -150
			minimum_difference = Vector2(minimal_size, minimal_size) - starting_min_size
			
			
			currently_moving = true
		
		# Register the end of our action the first time we let go off mouse
		if currently_moving and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			currently_moving = false
		
	
	# Now check if we are moving the mouse
	if event is InputEventMouseMotion:
		
		# Check if we are hovering and the button is pressed
		if currently_moving:
			
			# Check the amount which the element should be resized by getting the current mouse position
			var mouse_position := get_global_mouse_position()

			# Get the difference to our previous mouse position
			var difference : Vector2 
			# Depending on if we are a horizontal or a vertical container, we use the different coordinate
			
			if is_horizontal:
				difference = Vector2(0, starting_mouse_position.y - mouse_position.y)
				if difference.y < minimum_difference.y:
					difference.y = minimum_difference.y
					
				# Check if we want to check for maximum size
				if maximal_size > 0:
					# Check if the difference is bigger than our maximal size
					if difference.y + starting_min_size.y > maximal_size :
						difference.y = -starting_min_size.y + maximal_size 
			else:
				difference = Vector2(starting_mouse_position.x - mouse_position.x, 0)
				if difference.x < minimum_difference.x:
					difference.x = minimum_difference.x
				# Check if we want to check for maximum size
				if maximal_size > 0:
					# Check if the difference is bigger than our maximal size
					if difference.x + starting_min_size.x > maximal_size :
						difference.x = -starting_min_size.x + maximal_size 
			
			# Update the minimum rect for the element in the Y direction with that difference
			element_to_resize.custom_minimum_size = starting_min_size + difference
			element_to_resize.update_minimum_size()
		
			
