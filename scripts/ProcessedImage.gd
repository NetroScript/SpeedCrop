class_name ProcessedImage
extends Resource

signal was_exported
signal was_loaded
signal was_unloaded

signal active_changed

var source_path: String
var processed_path: String
var is_currently_loaded := false 
var was_already_exported := false

var original_texture : Texture2D = null 
var preview_texture : Texture2D = null

var index: int = 0

var is_loading_image: bool = false

var is_active: bool = false :
	set(value):
		is_active = value
		active_changed.emit()

func _init(index: int, source_path: String) -> void:
	self.index = index 
	self.source_path = source_path

func load_image() -> void:

	if original_texture != null and preview_texture != null:
		return

	if is_loading_image:
		return

	is_loading_image = true

	Application.threaded_load_image(
		source_path,
		func(image: ImageTexture): 
			original_texture = image
			was_loaded.emit()
			is_loading_image = false
	)
		

func unload_image() -> bool:
	
	original_texture = null
	preview_texture = null
	
	was_unloaded.emit()
	
	return false
	
func export_image(position: Rect2) -> bool:
	
	was_already_exported = true
	was_exported.emit()
	return false

func get_file_name() -> String:
	return source_path.get_file()
