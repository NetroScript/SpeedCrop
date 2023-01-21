class_name ProcessedImage
extends Resource

signal was_exported
signal was_loaded
signal was_unloaded

signal active_changed

var source_path: String
var processed_path: String = ""
var is_currently_loaded := false 
var was_already_exported := false
var relative_path: String

var original_texture : Texture2D = null 
var preview_texture : Texture2D = null

var index: int = 0
var total_rotations: int = 0

var is_loading_images: int = 0
var is_exporting_image: bool = false

var exported_section: Rect2i = Rect2i()

var is_active: bool = false :
	set(value):
		is_active = value
		active_changed.emit()

func _init(index: int, source_path: String) -> void:
	self.index = index 
	self.source_path = source_path
	self.relative_path = source_path.replace(Application.entry_path, "")

func load_image() -> void:

	if original_texture != null and preview_texture != null:
		return

	if is_loading_images != 0:
		return

	if processed_path != "":
		is_loading_images = 2
	else:
		is_loading_images = 1

	Application.threaded_load_image(
		source_path,
		func(image: ImageTexture): 
			original_texture = image
			is_loading_images -= 1
			if is_loading_images == 0:
				was_loaded.emit()
	)
	
	if processed_path != "":
		Application.threaded_load_image(
			processed_path,
			func(image: ImageTexture): 
				preview_texture = image
				is_loading_images -= 1
				if is_loading_images == 0:
					was_loaded.emit()
		)

func rotate(direction: int) -> void:
	if original_texture == null:
		return 
	
	total_rotations -= direction * 2 - 1 
	
	var new_image = original_texture.get_image()
	new_image.rotate_90(direction)
	
	original_texture = ImageTexture.create_from_image(new_image)
	
	was_loaded.emit()

func unload_image() -> bool:
	
	original_texture = null
	preview_texture = null
	
	was_unloaded.emit()
	
	return false
	
func export_image(position: Rect2i) -> void:
	
	# If the crop region didn't change, we do not need to do anything
	if position == exported_section:
		return
	
	if is_exporting_image:
		return
	
	# We now have our image section, where we extract a new image
	if original_texture != null:
		
		is_exporting_image = true
		
		Application.threaded_crop_image(
			original_texture.get_image(),
			position,
			func(image: Image):
				preview_texture = ImageTexture.create_from_image(image)
				
				# Create a formatted file name for the image
				var file_name : String = Application.output_template.format({
					"directory_tree": relative_path.get_base_dir().path_join(""),
					"file": relative_path.get_file().trim_suffix("." + relative_path.get_extension()),
					"extension": relative_path.get_extension() if Application.current_file_format == 0 else ["png", "jpg", "webp"][Application.current_file_format - 1],
					"index": index,
					"width": Application.crop_to_size.x,
					"height": Application.crop_to_size.x,
					"rotations": total_rotations,
					"rect.x": exported_section.position.x,
					"rect.y": exported_section.position.y,
					"rect.width": exported_section.size.x,
					"rect.height": exported_section.size.y,
				})

				# Remove leading / from the filename and join the path with the output directory
				var path := Application.output_path.path_join(file_name.trim_prefix("/"))

				exported_section = position
				
				Application.threaded_save_image(
					image, 
					path, 
					func(status: int):
						
						is_exporting_image = false
						
						if status == OK:
							processed_path = path
							was_already_exported = true
							was_exported.emit()
						else:
							print("File - " + path + " - was exported unsuccessfully - status: " + error_string(status))
				)
		)
		
		

func get_file_name() -> String:
	return source_path.get_file()
