extends ScrollContainer

const image_container_scene := preload("res://components/PreviewContainer.tscn")

@onready
var container := %ImagePreviews

var preview_list : Array[PreviewContainer] = []
var old_visible_items_start = -1
var old_visible_items_end = -1

var visible_items: int = -1
var item_width: int = -1
@export 
var loading_buffer: int = 32
var old_scroll_position: int = -1

var image_update_timer: Timer

var filling_images : bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	Application.pre_clear.connect(clear_images)
	Application.new_files_loaded.connect(create_images)
	
	resized.connect(func(): old_scroll_position = -1)
	
	Application.active_item_changed.connect(on_active_item_changed)
	
	image_update_timer = Timer.new()
	image_update_timer.wait_time = 0.25
	add_child(image_update_timer)
	image_update_timer.timeout.connect(load_and_unload_images)
	image_update_timer.start()
	
func on_active_item_changed(item: ProcessedImage) -> void: 
	scroll_horizontal = (item.index - (visible_items / 2)) * item_width

func load_and_unload_images():
	
	if preview_list.size() == 0:
		return
		
	item_width = preview_list[0].size.x
	visible_items = ceil(size.x / item_width)
	
	# We need to check every frame if the shown items changed
	# This is because we cant passively listen to changes
	var current_scroll_item: int = floor(scroll_horizontal / item_width)
	


	# Check if our item index would change considering shown items
	if current_scroll_item != old_scroll_position:
		
		# Load and unload all images which we need
		
		# First determine which indexes should be visible
		var start_visible := current_scroll_item - loading_buffer
		
		if start_visible < 0:
			start_visible = 0
		
		var end_visible := current_scroll_item + visible_items + loading_buffer
		if end_visible >= preview_list.size():
			end_visible =  preview_list.size() - 1
		
		# Check that we actually have items
		if end_visible - start_visible <= 0:
			return
		
		# Unload the items which were visible previously
		for i in range(old_visible_items_start, old_visible_items_end + 1):
		
			
			# Check that we are not in the region of the new visibility
			if i <= end_visible and i >= start_visible:
				continue
			
			# print("Unloading Image - " + str(i))
			
			# Unload the image at this offset
			preview_list[i].unload_image()
			
		# Now start loading the images in the visible section
		
		for i in range(start_visible, end_visible + 1):
			
			# Check that we are not in the region of the old visibility
			if i <=  old_visible_items_end and i >= old_visible_items_start:
				continue
			
			# print("Loading Image - " + str(i))
			preview_list[i].load_image()
	


		old_visible_items_start = start_visible
		old_visible_items_end = end_visible
		
		old_scroll_position = current_scroll_item
	

func clear_images() -> void:
	filling_images = false
	for child in container.get_children():
		child.queue_free()
	preview_list.clear()

# Creating all objects in a single frame can be too much, depending on the amount of data loaded
# So we move this to process actually
func create_images() -> void:
	filling_images = true 

func _process(delta: float) -> void:
	if filling_images:
		
		# Iterate the next 500 images we want to add
		
		for i in range(preview_list.size(), min(Application.currently_loaded_files.size(), preview_list.size() + 500)):
			var image : ProcessedImage = Application.currently_loaded_files[i]
		
			var child : PreviewContainer = image_container_scene.instantiate()
			
			child.image_reference = image
			
			container.add_child(child)
			
			preview_list.append(child)
			
		if preview_list.size() == Application.currently_loaded_files.size():
			filling_images = false
			Application.current_active_index = 0
