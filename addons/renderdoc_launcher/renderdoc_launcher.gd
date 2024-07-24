tool
extends EditorPlugin

var button_res: PackedScene = preload("res://addons/renderdoc_launcher/res/renderdoc_button.tscn")

var path_tres: String = "res://addons/renderdoc_launcher/res/renderdoc_path.tres"
var renderdoc_settings_path: String = "addons/renderdoc_launcher/res/settings.cap"

var renderdoc_path: RenderDocPath
var button: Control
var file_dialog: FileDialog

var added: bool = false;

func _enter_tree():
	if(OS.get_current_video_driver() == 1):
		push_warning ("RenderDoc only supports GLES3, please update the driver setting and reload the project.")
		return
	
	if create_renderdoc_path_tres() != OK:
		printerr("Failed to create renderdoc_path.tres.")
		return
	
	button = button_res.instance();
	
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, button);
	
	button.get_node("RenderDocButton").connect("pressed", self, "open_renderdoc")
	
	file_dialog = button.get_node("FileDialog")
	file_dialog.connect("file_selected", self, "save_path")
	file_dialog.window_title = "RenderDoc Location"
	
	added = true
	print("Added RenderDoc Launcher Button to Toolbar.")

func _exit_tree():
	if added:
		remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, button);
		print("Removed RenderDoc Launcher Button from Toolbar.")

func open_renderdoc():
	if renderdoc_path == null:
		if create_renderdoc_path_tres() != OK:
			printerr("Failed to create renderdoc_path.tres.")
			return
	
	var file = File.new()
	if get_renderdoc_path() == null || get_renderdoc_path().empty() || not file.file_exists(get_renderdoc_path()):
		print("RenderDoc path empty or not valid, please locate RenderDoc on your system.")
		print("Typical Windows installation would be at 'C:\\Program Files\\RenderDoc\\qrenderdoc.exe'.")
		file_dialog.popup_centered()
	else:
		execute_renderdoc();

func execute_renderdoc():
	if create_renderdoc_settings() != OK:
		printerr("Error creating settings.cap for RenderDoc!")
		return
	
	var file = File.new()
	var error = file.open(renderdoc_settings_path, file.READ)
	if error != OK:
		printerr("Error opening settings.cap!")
		return
	
	var text = file.get_as_text()
	var data = parse_json(text)
	
	data["settings"]["commandLine"] = '--path "%s"' % ProjectSettings.globalize_path("res://")
	data["settings"]["executable"] = OS.get_executable_path()
	
	file.close()
	
	error = file.open(renderdoc_settings_path, file.WRITE)
	if error != OK:
		printerr("Error opening settings.cap!")
		return
	
	file.store_string(to_json(data))
	file.close()
	
	yield(get_tree(), "idle_frame")
	OS.execute(get_renderdoc_path(), ["addons/renderdoc_launcher/res/settings.cap"], false)

func save_path(path):
	match OS.get_name():
		"Windows", "UWP":
			renderdoc_path.win_path = path
		"OSX":
			renderdoc_path.osx_path = path
		"X11":
			renderdoc_path.x11_path = path
		_:
			printerr("RenderDoc can only be launched from a desktop platform!")
			return
	
	var error = ResourceSaver.save(path_tres, renderdoc_path)
	if error != OK:
		printerr("Error saving RenderDoc path in renderdoc_path.tres!")
		return
	
	print("Saved '%s' as the RenderDoc location for the OS %s." % [path, OS.get_name()])
	
	execute_renderdoc()

func get_renderdoc_path():
	match OS.get_name():
		"Windows", "UWP":
			return renderdoc_path.win_path
		"OSX":
			return renderdoc_path.osx_path
		"X11":
			return renderdoc_path.x11_path
		_:
			printerr("RenderDoc can only be launched from a desktop platform!")

func create_renderdoc_path_tres() -> int:
	var file = File.new()
	if not file.file_exists(path_tres):
		renderdoc_path = RenderDocPath.new()
		var error = ResourceSaver.save(path_tres, renderdoc_path)
		if error == OK:
			print("Created renderdoc_path.tres.")
		return error
	else:
		renderdoc_path = ResourceLoader.load(path_tres)
		return OK

func create_renderdoc_settings() -> int:
	var renderdoc_settings_file = File.new()
	if not renderdoc_settings_file.file_exists(renderdoc_settings_path):
		var default_settings_file = File.new()
		var error = default_settings_file.open("addons/renderdoc_launcher/res/default_settings.cap", File.READ)
		if error != OK:
			return error
		
		var content = default_settings_file.get_as_text()
		default_settings_file.close()
		
		error = renderdoc_settings_file.open(renderdoc_settings_path, File.WRITE)
		if error != OK:
			return error
		
		renderdoc_settings_file.store_string(content)
		renderdoc_settings_file.close()
		
		return OK
	
	return OK
