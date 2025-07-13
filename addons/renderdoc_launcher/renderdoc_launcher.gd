@tool
extends EditorPlugin

var button_res: PackedScene = preload("res://addons/renderdoc_launcher/res/renderdoc_button.tscn")
var path_tres: String = "res://addons/renderdoc_launcher/res/renderdoc_path.tres"
var renderdoc_settings_path: String = "addons/renderdoc_launcher/res/settings.cap"

var thread: Thread
var renderdoc_path: RenderDocPath
var button: Control
var file_dialog: FileDialog
var option_button: OptionButton

var added: bool = false;

func _enter_tree():
	if create_renderdoc_path_tres() != OK:
		printerr("Failed to create renderdoc_path.tres.")
		return

	button = button_res.instantiate()
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, button)
	
	var container = button.get_node("Panel/HBoxContainer")
	container.get_node("RenderDocButton").pressed.connect(open_renderdoc)

	option_button = container.get_node("OptionButton")
	option_button.add_item("Main")
	option_button.add_item("Current")

	file_dialog = button.get_node("FileDialog")
	file_dialog.file_selected.connect(save_path)
	file_dialog.title = "RenderDoc Location"

	added = true
	print("Added RenderDoc Launcher Button to Toolbar.")

func _exit_tree():
	if (added):
		remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, button);
		print("Removed RenderDoc Launcher Button from Toolbar.")

func open_renderdoc():
	if create_renderdoc_path_tres() != OK:
		printerr("Failed to create renderdoc_path.tres.")
		return
	
	if get_renderdoc_path() == null || get_renderdoc_path() == "" || not FileAccess.open(get_renderdoc_path(), FileAccess.READ):
		print("RenderDoc path empty or not valid, please locate RenderDoc on your system.")
		print("Typical Windows installation would be at 'C:\\Program Files\\RenderDoc\\qrenderdoc.exe'.")
		file_dialog.popup_centered()
	else:
		execute_renderdoc()

func execute_renderdoc():
	if create_renderdoc_settings() != OK:
		printerr("Error creating settings.cap for RenderDoc!")
		return
	
	var file = FileAccess.open(renderdoc_settings_path, FileAccess.READ)
	
	if not file:
		printerr("Error opening settings.cap!")
		return
	
	var text = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(text)
	var data
	if error == OK:
		data = json.data
		match option_button.get_selected_id():
			0:
				data["settings"]["commandLine"] = '--path "%s"' % ProjectSettings.globalize_path("res://")
			1:
				var current_scene = get_editor_interface().get_edited_scene_root()
				if current_scene:
					var scene_path = current_scene.scene_file_path
					var abs_scene_path = ProjectSettings.globalize_path(scene_path)
					var abs_project_path = ProjectSettings.globalize_path("res://")
					data["settings"]["commandLine"] = '--path "%s" --scene "%s"' % [abs_project_path, abs_scene_path]
			
		
		data["settings"]["executable"] = OS.get_executable_path()
	else:
		print(error)
		return
	
	file.close()
	
	file = FileAccess.open(renderdoc_settings_path, FileAccess.WRITE)
	if not file:
		printerr("Error opening settings.cap!")
		return
	
	file.store_string(json.stringify(data))
	file.close()
	
	await get_tree().process_frame
	print("Launching RenderDoc.")
	OS.create_process(get_renderdoc_path(), ["addons/renderdoc_launcher/res/settings.cap"])

func save_path(path):
	match OS.get_name():
		"Windows":
			renderdoc_path.win_path = path
		"macOS":
			renderdoc_path.osx_path = path
		"Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
			renderdoc_path.x11_path = path
		_:
			printerr("RenderDoc can only be launched from a desktop platform!")
			return
	
	var error = ResourceSaver.save(renderdoc_path, path_tres)
	if error != OK:
		printerr("Error saving RenderDoc path in renderdoc_path.tres!")
		return
	
	print("Saved '%s' as the RenderDoc location for the OS %s." % [path, OS.get_name()])
	
	execute_renderdoc()

func get_renderdoc_path():
	match OS.get_name():
		"Windows":
			return renderdoc_path.win_path
		"macOS":
			return renderdoc_path.osx_path
		"Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
			return renderdoc_path.x11_path
		_:
			printerr("RenderDoc can only be launched from a desktop platform!")

func create_renderdoc_path_tres() -> Error:
	var file = FileAccess.open(path_tres, FileAccess.READ)
	if not file:
		renderdoc_path = RenderDocPath.new()
		var error = ResourceSaver.save(renderdoc_path, path_tres)
		if error == OK:
			print("Created renderdoc_path.tres.")
		return error
	else:
		renderdoc_path = ResourceLoader.load(path_tres)
		return OK

func create_renderdoc_settings() -> Error:
	var renderdoc_settings_file = FileAccess.open(renderdoc_settings_path, FileAccess.READ)
	if not renderdoc_settings_file:
		var default_settings_file = FileAccess.open("addons/renderdoc_launcher/res/default_settings.cap", FileAccess.READ)
		
		if not default_settings_file:
			printerr("Default Renderdoc settings not found!")
			return ERR_FILE_NOT_FOUND

		var content = default_settings_file.get_as_text()
		default_settings_file.close()
		
		renderdoc_settings_file = FileAccess.open(renderdoc_settings_path, FileAccess.WRITE)
		if not renderdoc_settings_file:
			return ERR_FILE_NOT_FOUND
		
		renderdoc_settings_file.store_string(content)
		renderdoc_settings_file.close()
		
		return OK
	
	return OK
