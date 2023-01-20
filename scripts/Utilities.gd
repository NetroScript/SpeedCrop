class_name Utilities
extends Node


static func get_theme(node: Control) -> Theme:
	var theme : Theme = null
	while node != null && "theme" in node:
		theme = node.theme
		if theme != null: break
		var parent := node.get_parent()
		if not parent is Control:
			break
		node = parent as Control
	return theme


static func recursively_load_all_image_files(access: DirAccess, recursive: bool = true) -> PackedStringArray:

	var files : PackedStringArray = PackedStringArray([])
	var current_folder = access.get_current_dir(true)

	access.list_dir_begin() 
	var file_name = access.get_next()
	while file_name != "":
		if not access.current_is_dir():
			# Check if the extension is a valid file
			if file_name.get_extension() in ["png", "jpg", "jpeg", "webp"]:
				files.append(current_folder + "/" + file_name)
		elif recursive:
			files.append_array(recursively_load_all_image_files(DirAccess.open(current_folder + "/" + file_name), recursive))
			
		file_name = access.get_next()
	return files
