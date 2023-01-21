extends Sprite2D

var current_image: ProcessedImage
@onready
var cutout_area : Control = %CutOutArea 
var minimum_zoom : float 
var space_available_from_center : Vector2 
var additional_offset : Vector2
var size: Vector2
var old_relative_position: Vector2
var pinch_zoom_start: Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Application.active_item_changed.connect(update_image)
	cutout_area.resized.connect(update_positions)
	
func update_image(image: ProcessedImage) -> void:

	if current_image != null:
		current_image.was_loaded.disconnect(update_image.bind(image))
	
	current_image = image
	
	if image.original_texture == null:
		image.load_image()
		image.was_loaded.connect(update_image.bind(image))
	
	texture = image.original_texture

func update_positions() -> void:
	if texture == null:
		return
	
	# Set size to original texture size
	size = texture.get_size()
	
	# Adjust the scale so that it fits our aspectratio container
	var container_ratio := float(Application.crop_to_size.x)/float(Application.crop_to_size.y)
	var image_ratio := float(size.x)/float(size.y)
	
	var scale_tmp : float
	
	if image_ratio < container_ratio:
		scale_tmp = cutout_area.size.x / size.x 
	else:
		scale_tmp = cutout_area.size.y / size.y
	
	minimum_zoom = scale_tmp
	scale = Vector2(scale_tmp, scale_tmp)
	
func _input(event: InputEvent) -> void:
	
	
	# Check for mouse events to update the position
	
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			
		additional_offset -= event.relative
		clamp_position()
		
		
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		
		if event.relative.x > 0:
			scale *= 1.0 + event.relative.x / 200
			

		elif event.relative.x < 0:
			scale *= 1.0 + event.relative.x / 200
			
		
		if event.relative.y > 0:
			scale *= 1.0 + event.relative.y / 1000
			

		elif event.relative.y < 0:
			scale *= 1.0 + event.relative.y / 1000
			
		if scale.x < minimum_zoom:
			scale = Vector2(minimum_zoom, minimum_zoom)
			
		
		additional_offset += (pinch_zoom_start - get_local_mouse_position())*scale

		
	
	if event is InputEventMouseButton:
		
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				pinch_zoom_start = get_local_mouse_position()
		
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			scale *= 1.05		
			additional_offset += (old_relative_position - get_local_mouse_position())*scale


		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scale *= 0.9
			
			if scale.x < minimum_zoom:
				scale = Vector2(minimum_zoom, minimum_zoom)
			additional_offset += (old_relative_position - get_local_mouse_position())*scale
			
	clamp_position()

	
	old_relative_position = get_local_mouse_position() 

func clamp_position() -> void:
	space_available_from_center = ((size - (cutout_area.size / scale))/2)*scale
		
	if abs(additional_offset.x) > space_available_from_center.x:
		additional_offset.x = space_available_from_center.x * sign(additional_offset.x)
	if abs(additional_offset.y) > space_available_from_center.y:
		additional_offset.y = space_available_from_center.y * sign(additional_offset.y)
	
	position = -additional_offset
