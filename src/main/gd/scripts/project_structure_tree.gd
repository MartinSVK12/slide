@warning_ignore("unused_parameter")
extends Tree

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#var root: TreeItem = create_item(null)
	#root.set_text(0,"No folder selected.")
	#root.set_selectable(0,false)
	#var root = create_dir("/home/deck/Documents/Godot/","lox-ide",null)
	#load_project_structure("/home/deck/Documents/Godot/lox-ide/",root)
	pass # Replace with function body.
	
func load_folder(path: String):
	clear()
	(get_tree().current_scene.folders as Array[String]).clear()
	(get_tree().current_scene.folders as Array[String]).append(path)
	var root = create_dir(path,path.get_file(),null)
	load_project_structure(path,root)

func load_project_structure(path: String,parent: TreeItem = null):
	var dirs = DirAccess.get_directories_at(path)
	var files = DirAccess.get_files_at(path)
	for dir in dirs:
		(get_tree().current_scene.folders as Array[String]).append(path.path_join(dir))
		var item = create_dir(path,dir,parent)
		load_project_structure(path.path_join(dir),item)
		item.set_collapsed_recursive(true)
	for file in files:
		var item = create_file(path,file,parent)

func create_dir(path: String, dir_name: String, parent: TreeItem):
	var item = create_item(parent)
	item.set_text(0,dir_name)
	item.set_icon_max_width(0,16)
	item.set_icon(0,load("res://src/main/gd/assets/open_dark.svg"))
	item.set_metadata(0,{"path":path.path_join(dir_name), "type":"dir"})
	#item.add_button(0,load("res://src/main/gd/assets/add_dark.svg"))
	#item.add_button(0,load("res://src/main/gd/assets/moreVertical_dark.svg"))
	return item
	
func create_file(path: String, file_name: String, parent: TreeItem):
	var item = create_item(parent)
	item.set_text(0,file_name)
	item.set_icon_max_width(0,16)
	item.set_icon(0,load("res://src/main/gd/assets/text_dark.svg"))
	item.set_metadata(0,{"path":path.path_join(file_name), "type":"file"})
	#item.add_button(0,load("res://src/main/gd/assets/moreVertical_dark.svg"))
	return item

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if get_root() == null:
		$Label.visible = true
	else:
		$Label.visible = false


func load_file(path: String):
	for i in %ScriptTabs.get_child_count():
		if %ScriptTabs.get_tab_title(i) == path.get_file():
			%ScriptTabs.set_current_tab(i)
			return
	var scn = load("res://src/main/gd/scenes/script.tscn")
	var script: ScriptEdit = scn.instantiate()
	script.file = path
	%ScriptTabs.add_child(script)
	%ScriptTabs.set_tab_title(script.get_index(),script.file.get_file())
	%ScriptTabs.set_tab_button_icon(script.get_index(),load("res://src/main/gd/assets/close_dark.svg"))
	%ScriptTabs.set_current_tab(script.get_index())

func _on_item_activated() -> void:
	var item: TreeItem = get_selected()
	if item.get_metadata(0)["type"] == "file":
		load_file(item.get_metadata(0)["path"])

func _on_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
	var item = get_selected()
	if mouse_button_index == 2:
		if item.get_metadata(0)["type"] == "dir":
			%ProjectDirAction.popup(Rect2i(get_global_mouse_position(),Vector2.ZERO))
		if item.get_metadata(0)["type"] == "file":
			%ProjectFileAction.popup(Rect2i(get_global_mouse_position(),Vector2.ZERO))


func _on_project_dir_action_id_pressed(id: int) -> void:
	match id:
		0:
			%CreateFileDialog.popup()
		1:
			%CreateDirDialog.popup()
		3:
			var item = get_selected()
			var path: String = item.get_metadata(0)["path"]
			%RenameDialog/VBox/Name.text = path
			%RenameDialog.popup()
		5:
			var item = get_selected()
			if item.get_metadata(0)["type"] == "dir":
				var file_path: String = item.get_metadata(0)["path"]
				%DeleteConfirmationDialog.set_meta("file_path",file_path)
				%DeleteConfirmationDialog.title = "Delete folder?"
				%DeleteConfirmationDialog.dialog_text = "Are you sure you want to delete this folder?\n\n{0}\n\nThis cannot be undone!".format([file_path])
				%DeleteConfirmationDialog.popup()

func _on_project_file_action_id_pressed(id: int) -> void:
	match id:
		0:
			var item = get_selected()
			var path: String = item.get_metadata(0)["path"]
			%RenameDialog/VBox/Name.text = path
			%RenameDialog.popup()
		2:
			var item = get_selected()
			if item.get_metadata(0)["type"] == "file":
				var file_path: String = item.get_metadata(0)["path"]
				%DeleteConfirmationDialog.set_meta("file_path",file_path)
				%DeleteConfirmationDialog.title = "Delete file?"
				%DeleteConfirmationDialog.dialog_text = "Are you sure you want to delete this file?\n\n{0}\n\nThis cannot be undone!".format([file_path])
				%DeleteConfirmationDialog.popup()


func _on_create_file_dialog_confirmed() -> void:
	var item = get_selected()
	var file: String = %CreateFileDialog/VBox/FileName.text
	if item.get_metadata(0)["type"] == "dir":
		var dir_path: String = item.get_metadata(0)["path"]
		var path = dir_path.path_join(file)
		if not FileAccess.file_exists(path):
			var f = FileAccess.open(path,FileAccess.WRITE_READ)
			push_error(error_string(FileAccess.get_open_error()))
			if f != null:
				f.close()
				load_file(path)
				load_folder(get_tree().current_scene.current_folder)
		else:
			%AlertDialog.dialog_text = "File already exists!"
			%AlertDialog.popup()
	%CreateFileDialog/VBox/FileName.text = ""


func _on_delete_confirmation_dialog_confirmed() -> void:
	var file_path: String = %DeleteConfirmationDialog.get_meta("file_path")
	var err = DirAccess.remove_absolute(file_path)
	if err == OK:
		var item = get_selected()
		item.free()
	else:
		%AlertDialog.dialog_text = "Couldn't delete '{0}'!\n\n{1}\n\nCheck if the folder exists and is empty.".format([file_path,error_string(err)])
		%AlertDialog.popup()


func _on_create_dir_dialog_confirmed() -> void:
	var item = get_selected()
	var file: String = %CreateDirDialog/VBox/DirName.text
	if item.get_metadata(0)["type"] == "dir":
		var dir_path: String = item.get_metadata(0)["path"]
		var path = dir_path.path_join(file)
		if not DirAccess.dir_exists_absolute(path):
			DirAccess.make_dir_absolute(path)
			load_folder(get_tree().current_scene.current_folder)
		else:
			%AlertDialog.dialog_text = "Directory already exists!"
			%AlertDialog.popup()
	%CreateDirDialog/VBox/DirName.text = ""


func _on_rename_dialog_confirmed() -> void:
	var item = get_selected()
	var new_name: String = %RenameDialog/VBox/Name.text
	var old_name: String = item.get_metadata(0)["path"]
	if not DirAccess.dir_exists_absolute(new_name) and not FileAccess.file_exists(new_name):
		var err = DirAccess.rename_absolute(old_name,new_name)
		if err != OK:
			%AlertDialog.dialog_text = "Couldn't rename or move '{0}' to:\n\n'{1}'!\n\n{1}".format([old_name,new_name,error_string(err)])
			%AlertDialog.popup()
		else:
			load_folder(get_tree().current_scene.current_folder)
	else:
		%AlertDialog.dialog_text = "A folder or file already exists at that path."
		%AlertDialog.popup()
	%RenameDialog/VBox/Name.text = ""
	
