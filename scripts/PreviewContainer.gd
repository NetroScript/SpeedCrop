class_name PreviewContainer
extends PanelContainer

const EXTENDED_DESCRIPTION_WIDTH: float = 200


@export 
var image_reference: ProcessedImage

@onready 
var label: Label = %Label
@onready
var texture : TextureRect = %Texture

var is_active: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	if image_reference:
		image_reference.was_loaded.connect(set_texture)
		image_reference.was_exported.connect(set_texture)
		image_reference.was_unloaded.connect(set_texture)

	
	# Set the context of the Label to our image_reference index
	update_label()
	
	resized.connect(update_label)


func update_label() -> void:
	
	if image_reference == null:
		return
	
	# Check the current width of the container to know if we show the file name for the file
	if size.x > EXTENDED_DESCRIPTION_WIDTH:
		label.text = str(image_reference.index) + " - " + image_reference.get_file_name()
	else:
		label.text = str(image_reference.index)

func set_texture() -> void:
	
	if image_reference == null:
		return
		
	if image_reference.was_already_exported:
		pass
		
	if image_reference.preview_texture != null:
		texture.texture = image_reference.preview_texture
		
	elif  image_reference.original_texture != null:
		texture.texture = image_reference.original_texture
	else:
		texture.texture = preload("res://assets/icons/Image.svg")

	
func load_image() -> void:
	
	if image_reference == null:
		return
		
	image_reference.load_image()
	
func unload_image() -> void:
	
	texture.texture = preload("res://assets/icons/Image.svg")
	
	if image_reference == null:
		return
		
	image_reference.unload_image()
