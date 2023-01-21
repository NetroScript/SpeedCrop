class_name PreviewContainer
extends PanelContainer

const EXTENDED_DESCRIPTION_WIDTH: float = 200


@export 
var image_reference: ProcessedImage

@onready 
var label: Label = %Label
@onready
var texture : TextureRect = %Texture

var stylebox: StyleBoxFlat

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	if image_reference:
		image_reference.was_loaded.connect(set_texture)
		image_reference.was_exported.connect(set_texture)
		image_reference.was_unloaded.connect(set_texture)
		image_reference.active_changed.connect(update_outline)

	stylebox = get("theme_override_styles/panel")
	
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
		
func update_outline() -> void:#
	
	if image_reference == null:
		return
	
	if image_reference.is_active:
		stylebox.bg_color = Color(0.2, 0.2, 0.2)
	else:
		stylebox.bg_color = Color(0.1, 0.1, 0.1)

		
	if image_reference.was_already_exported:
		stylebox.border_color = Color(0.0247, 0.3438, 0.1081)
	

func set_texture() -> void:
	
	if image_reference == null:
		return
		
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
