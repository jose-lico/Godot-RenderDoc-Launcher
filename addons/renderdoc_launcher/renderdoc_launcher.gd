tool
extends EditorPlugin

var button_res: PackedScene = preload("res://addons/renderdoc_launcher/res/renderdoc_button.tscn")
var path_res: RenderDocPath = preload("res://addons/renderdoc_launcher/res/renderdoc_path.tres")

var button: Control
var file_dialog: FileDialog

var added: bool = false;

func _enter_tree():
	if(OS.get_current_video_driver() == 1):
		push_warning ("RenderDoc only supports GLES3, please update the setting and refresh the project.")
		return
	
	button = button_res.instance();
	
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, button);
	
	button.get_node("RenderDocButton").connect("pressed", self, "open_renderdoc")
	
	file_dialog = button.get_node("FileDialog")
	file_dialog.connect("file_selected", self, "save_path")
	file_dialog.window_title = "RenderDoc Location"
	
	added = true


func _exit_tree():
	if added:
		remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, button);


func open_renderdoc():
	if path_res != null:
		var file = File.new()
		if get_os_path() == null || get_os_path().empty() || not file.file_exists(get_os_path()):
			print("RenderDoc path empty or not valid, please locate RenderDoc on your system.")
			file_dialog.popup_centered()
		else:
			execute_renderdoc();
	else:
		# Later might just recreate again instead of prompting the user to do so
		printerr('Could not find "renderdoc_path.tres" at "res://addons/renderdoc_launcher/res/renderdoc_path.tres",' \
			+ 'please recreate the resource using the script "res://addons/renderdoc_launcher/res/renderdoc_path.gd".')


func execute_renderdoc():
	var settings_path = "addons/renderdoc_launcher/res/settings.cap"
	var file = File.new()
	
	if not file.file_exists(settings_path):
		# Recreate settings.cap in case user deleted it
		printerr("Could not find settings.cap!")
		pass
		
	file.open(settings_path, file.READ)
	
	var text = file.get_as_text()
	var data = parse_json(text)
	
	data["settings"]["commandLine"] = "--path %s" % [ProjectSettings.globalize_path("res://")]
	data["settings"]["executable"] = OS.get_executable_path()

	file.close()
	
	file.open(settings_path, file.WRITE)
	file.store_string(to_json(data))
	file.close()
	
	yield(get_tree(), "idle_frame")
	OS.execute(get_os_path(), ["addons/renderdoc_launcher/res/settings.cap"], false)


func save_path(path):
	match OS.get_name():
		"Windows", "UWP":
			path_res.win_path = path
		"OSX":
			path_res.osx_path = path
		"X11":
			path_res.x11_path = path
		_:
			printerr("RenderDoc can only be launched from a desktop platform!")
			return
			
	print("Saved %s as the RenderDoc location for the OS %s" % [path, OS.get_name()])
	
	execute_renderdoc()


func get_os_path():
	match OS.get_name():
		"Windows", "UWP":
			return path_res.win_path
		"OSX":
			return path_res.osx_path
		"X11":
			return path_res.x11_path
		_:
			printerr("RenderDoc can only be launched from a desktop platform!")
