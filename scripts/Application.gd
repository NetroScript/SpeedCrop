class_name ApplicationSingleton
extends Node

var THREAD_COUNT := OS.get_processor_count()

signal pre_clear
signal post_clear

signal new_files_loaded

signal load_subdirectories_changed(flag: bool)
signal path_invalid(error: int)

signal active_item_changed(item: ProcessedImage)

signal crop_size_changed(size: Vector2i)

var currently_loaded_files: Array[ProcessedImage] = []

var current_loading_index := 0
var currently_active_item: ProcessedImage

var crop_to_size: Vector2i = Vector2i(512,512) : 
	set(value): 
		crop_to_size = value 
		crop_size_changed.emit(value)

var current_active_index := -1 : 
	set(value):
		if current_active_index > -1 and currently_active_item:
			currently_active_item.is_active = false
		
		if value > -1 and value < currently_loaded_files.size():
			current_active_index = value 
			currently_active_item = currently_loaded_files[current_active_index]
			active_item_changed.emit(currently_active_item)
			currently_active_item.is_active = true

var thread_polling_timer: Timer
var thread_workers: Array[ImageThreadWorker] = []

var load_subdirectories: bool = true : 
	set(val):
		load_subdirectories = val 
		load_subdirectories_changed.emit(val)
		_entry_path_changed()

var entry_path: String = "" : 
	set(value):
		var different: bool = entry_path != value
		entry_path = value
		if different:
			_entry_path_changed()
			
func _ready() -> void:
	
	
	thread_polling_timer = Timer.new()
	thread_polling_timer.wait_time = 0.05

	
	for i in range(THREAD_COUNT):
		thread_workers.append(ImageThreadWorker.new())
	
	add_child(thread_polling_timer)
	
	thread_polling_timer.timeout.connect(_poll_threads)
	thread_polling_timer.paused = false
	thread_polling_timer.start()
	
func _unhandled_key_input(e: InputEvent) -> void:
	var event: InputEventKey = e as InputEventKey
	
	if event == null:
		return
	
	
	# Do not do these actions when the GUI has something in focus
	# So check if currently any GUI has focus
	if get_viewport().gui_get_focus_owner() != null:
		return
	
	if not event.pressed:
	
		# If the event is either Space or right key, go to the next image
		if event.keycode == KEY_SPACE || event.keycode == KEY_RIGHT:
			current_active_index += 1
		elif event.keycode == KEY_LEFT:
			current_active_index -= 1
		
		if currently_active_item:
			
			# Allow rotating an image
			if event.keycode == KEY_Q:
				currently_active_item.rotate(COUNTERCLOCKWISE)
				current_active_index = current_active_index
			if event.keycode == KEY_E:
				currently_active_item.rotate(CLOCKWISE)
				current_active_index = current_active_index
	
func _poll_threads() -> void:
	
	for worker in thread_workers:
		worker.check_for_work()


func threaded_load_image(path: String, callback: Callable) -> void:
	
	var worktask := ImageThreadWorkerTask.new(callback, path)
	var worker := select_worker()
	worker.add_item_to_queue(worktask)
	
func threaded_crop_image(image: Image, size: Rect2i, callback: Callable) -> void:
	
	var worktask := ImageThreadWorkerTask.new(callback, "", ImageThreadWorkerTask.WORKER_TASKS.CROP, {
		"image": image,
		"size": size,
		"crop_size": crop_to_size
	})
	var worker := select_worker()
	worker.add_item_to_queue(worktask)

func select_worker() -> ImageThreadWorker:
	# Find a non working thread
	
	for worker in thread_workers:
		if worker.current_work_item == null:
			return worker
			
	# If we have no free worker sample a random one where we assign the work
	return thread_workers.pick_random()

func _entry_path_changed() -> void:
	clear()
	
	# Check if the entry_path is valid (not "")
	if entry_path == "":
		return 
		
	# Try to load the directory
	var dir := DirAccess.open(entry_path)
	
	var error := DirAccess.get_open_error()
	
	# If there was an error return and emit error signal
	if error != OK:
		path_invalid.emit(error)
		return
		
	var file_list := Utilities.recursively_load_all_image_files(dir, load_subdirectories)
	
	# Now create the ProcessedImages instances
	for file_path in file_list:
		
		var image := ProcessedImage.new(current_loading_index, file_path)
		currently_loaded_files.append(image)
		current_loading_index += 1
		
	new_files_loaded.emit()
	
func clear() -> void:
	pre_clear.emit()
	currently_loaded_files.clear()
	current_loading_index = 0
	post_clear.emit()

class ImageThreadWorkerTask extends Resource:
	
	enum WORKER_TASKS {LOAD, STORE, CROP}
	
	var callback: Callable
	var path: String 
	var task: WORKER_TASKS
	var data_playload : Dictionary
	
	func _init(callback: Callable, path: String, task: WORKER_TASKS = WORKER_TASKS.LOAD, payload: Dictionary = {}) -> void:
		self.path = path
		self.callback = callback
		self.task = task
		self.data_playload = payload

class ImageThreadWorker extends Resource:
	
	var working_queue: Array[ImageThreadWorkerTask] = []
	var current_work_item: ImageThreadWorkerTask = null
	
	var thread: Thread
	
	func _init() -> void:
		thread = Thread.new()

	
	func add_item_to_queue(item: ImageThreadWorkerTask) -> void:
		working_queue.append(item)
		check_for_work()
	
	func check_for_work():
		
		# If we are currently working on an item, check if we have finished that, if so clear it
		if current_work_item != null:
			if !thread.is_alive():
				
				match current_work_item.task:
					ImageThreadWorkerTask.WORKER_TASKS.LOAD:
						var image := thread.wait_to_finish() as ImageTexture
						current_work_item.callback.call(image)
					ImageThreadWorkerTask.WORKER_TASKS.CROP:
						var image := thread.wait_to_finish() as Image
						current_work_item.callback.call(image)
				
				current_work_item = null
				check_for_work()
		# If we are not working on an item, check íf we can start working on a new item
		else:
			if working_queue.size() > 0:
				current_work_item = working_queue.pop_back() as ImageThreadWorkerTask
				thread = Thread.new()
				
				match current_work_item.task:
					ImageThreadWorkerTask.WORKER_TASKS.LOAD:
						thread.start(load_image_texture.bind(current_work_item.path))
						
					ImageThreadWorkerTask.WORKER_TASKS.CROP:
						thread.start(crop_image.bind(
							current_work_item.data_playload["image"],
							current_work_item.data_playload["size"],
							current_work_item.data_playload["crop_size"],
						))
				
	
	func load_image_texture(path: String) -> ImageTexture:
		
		var loaded_image := Image.new()
		var error := loaded_image.load(path)
		
		if error != OK:
			return null

		return ImageTexture.create_from_image(loaded_image)
		
	func crop_image(image: Image, rect: Rect2i, size: Vector2i) -> Image:
		
		if image == null:
			return null
		
		# Get the region of the image we actually want
		var new_image := image.get_region(rect)
		
		# Now we resize that target region into the crop size we actually want
		new_image.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
		
		return new_image
