extends Tree
class_name ResourceTree

@onready var prop_list: ItemList = get_parent().get_node("PropertyList")
@onready var method_list: ItemList = get_parent().get_node("MethodList")
@onready var prop_edit: LineEdit = get_parent().get_node("PropertyEdit")
@onready var method_edit: LineEdit = get_parent().get_node("MethodEdit")
@onready var node_tree: Tree = get_parent().get_node("NodeTree")

var selected: TreeItem = null
var selected_property: String = ""
var selected_method: String = ""
var selected_node: Object = null

var searching_node = ""
var searching_property = ""
var searching_method = ""

#var items = {}

# Called when the node enters the scene tree for the first time.
func _ready():
#	get_tree().connect("node_removed",Callable(self,"check_node_validity"))
	var item = create_item()
	item.set_text(0,"No resources to show.")
	item.set_selectable(0,false)
	item = create_item()
	item.set_text(0,"No node selected.")
	item.set_selectable(0,false)

const TypesNormal = [
	"Nil",
	"bool",
	"int",
	"float",
	"String",
	"Vector2",
	"Vector2i",
	"Rect2",
	"Rect2i",
	"Vector3",
	"Vector3i",
	"Transform2D",
	"Vector4",
	"Vector4i",
	"Plane",
	"Quad",
	"AABB",
	"Basis",
	"Transform3D",
	"Projection",
	"Color",
	"StringName",
	"NodePath",
	"RID",
	"Object",
	"Callable",
	"Signal",
	"Dictionary",
	"Array",
	"PackedByteArray",
	"PackedInt32Array",
	"PackedInt64Array",
	"PackedFloat32Array",
	"PackedFloat64Array",
	"PackedStringArray",
	"PackedVector2Array",
	"PackedVector3Array",
	"PackedColorArray",
	"TYPE_MAX"
]
#func check_node_validity(node):
#	if !is_instance_valid(selected_node):
#		clear_lists()
#		selected = null
#		selected_method = ""
#		selected_property = ""
#		selected_node = null

func reload():
	clear()
	await get_tree().create_timer(0.01).timeout
	if is_instance_valid(node_tree.selected_node):
		var root = create_item()
		root.set_collapsed(false)
		if node_tree.selected_node is Node:
			root.set_text(0,node_tree.selected_node.name)
		else:
			root.set_text(0,node_tree.selected_node.get_class())
		root.set_icon(0,get_theme_icon(node_tree.selected_node.get_class(),"EditorIcons"))
		root.set_metadata(0,
		{
			"nodePath":node_tree.selected_node#.get_path()
		})
		get_properties(root)
	else:
		var item = create_item()
		item.set_text(0,"No resources to show.")
		item.set_selectable(0,false)
		item = create_item()
		item.set_text(0,"No node selected.")
		item.set_selectable(0,false)
	
func get_properties(root):
	if is_instance_valid(root):
		var node = root.get_metadata(0)["nodePath"]
		if is_instance_valid(node):
			for prop in node.get_property_list():
				if !(prop["usage"] == PROPERTY_USAGE_GROUP or prop["usage"] == PROPERTY_USAGE_CATEGORY):
					var item = create_item(root)
					item.set_text(0,prop["name"])
					var prop_type = typeof(node.get(prop["name"]))
					item.set_icon(0,get_theme_icon(TypesNormal[prop_type],"EditorIcons"))
					item.set_selectable(0,false)
					if prop_type != TYPE_OBJECT and prop_type != TYPE_ARRAY and prop_type != TYPE_DICTIONARY:
						item.free()
					elif prop_type == TYPE_OBJECT:
						item.set_selectable(0,true)
						item.set_metadata(0,
						{
							"nodePath":node.get(prop["name"])#.get_path()
						})
						pass
					elif prop_type == TYPE_ARRAY:
						item.set_collapsed(true)
						for array_item in node.get(prop["name"]):
							if array_item is Object:
								var item2 = create_item(item)
								if array_item is Node:
									item2.set_text(0,array_item.name)
								elif array_item is Resource and array_item.resource_name != "":
									item2.set_text(0,array_item.resource_name)
								else:
									item2.set_text(0,array_item.get_class())
								item2.set_icon(0,get_theme_icon(array_item.get_class(),"EditorIcons"))
								item2.set_metadata(0,
								{
									"nodePath":array_item#.get_path()
								})
					elif prop_type == TYPE_DICTIONARY:
						item.set_collapsed(true)
						for array_item in node.get(prop["name"]).keys():
							if array_item is Object:
								var item2 = create_item(item)
								item2.set_collapsed(true)
								if array_item is Node:
									item2.set_text(0,array_item.name)
								elif array_item is Resource and array_item.resource_name != "":
									item2.set_text(0,array_item.resource_name)
								else:
									item2.set_text(0,array_item.get_class())
								item2.set_icon(0,get_theme_icon(array_item.get_class(),"EditorIcons"))
								item2.set_metadata(0,
								{
									"nodePath":array_item#.get_path()
								})
								var dict_value = node.get(prop["name"]).get(array_item)
								if dict_value is Object:
									var item3 = create_item(item2)
									if dict_value is Node:
										item3.set_text(0,dict_value.name)
									elif dict_value is Resource and dict_value.resource_name != "":
										item3.set_text(0,dict_value.resource_name)
									else:
										item3.set_text(0,dict_value.get_class())
									item3.set_icon(0,get_theme_icon(dict_value.get_class(),"EditorIcons"))
									item3.set_metadata(0,
									{
										"nodePath":dict_value#.get_path()
									})
								else:
									var item3 = create_item(item2)
									item3.set_selectable(0,false)
									item3.set_text(0,str(dict_value))
									var prop_type2 = typeof(dict_value)
									item3.set_icon(0,get_theme_icon(TypesNormal[prop_type2],"EditorIcons"))
							else:
								var item2 = create_item(item)
								item2.set_selectable(0,false)
								item2.set_collapsed(true)
								item2.set_text(0,str(array_item))
								var prop_type2 = typeof(array_item)
								item2.set_icon(0,get_theme_icon(TypesNormal[prop_type2],"EditorIcons"))
								var dict_value = node.get(prop["name"]).get(array_item)
								if dict_value is Object:
									var item3 = create_item(item2)
									if dict_value is Node:
										item3.set_text(0,dict_value.name)
									elif dict_value is Resource and dict_value.resource_name != "":
										item3.set_text(0,dict_value.resource_name)
									else:
										item3.set_text(0,dict_value.get_class())
									item3.set_icon(0,get_theme_icon(dict_value.get_class(),"EditorIcons"))
									item3.set_metadata(0,
									{
										"nodePath":dict_value#.get_path()
									})
								else:
									var item3 = create_item(item2)
									item3.set_selectable(0,false)
									item3.set_text(0,str(dict_value))
									var prop_type3 = typeof(dict_value)
									item3.set_icon(0,get_theme_icon(TypesNormal[prop_type3],"EditorIcons"))
				else:
					pass
#					var item = create_item(root)
#					item.set_text(0,prop["name"])
#					item.set_selectable(0,false)
#					if ClassDB.class_exists(prop["name"]):
#						if has_theme_icon(prop["name"],"EditorIcons"):
#							item.set_icon(0,get_theme_icon(prop["name"],"EditorIcons"))
	pass
	

#	root.set_text(0,"SceneTree")
#	root.set_metadata(0,
#		{
#			"nodePath":get_tree()
#		})
#	root.set_icon(0,get_theme_icon("Object","EditorIcons"))
##	items[get_tree()] = root
#	var viewport = create_item(root)
#	viewport.set_text(0,"root")
#	viewport.set_metadata(0,
#		{
#			"nodePath":get_viewport()
#		})
##	items[get_viewport()] = viewport
#	viewport.set_icon(0,get_theme_icon(get_node("/root").get_class(),"EditorIcons"))
#	get_children_recursive(get_node("/root"),viewport)
#	for singleton in BuiltinSingletons:
#		var item = create_item(root)
#		item.set_text(0,singleton)
#		item.set_metadata(0,
#		{
#			"nodePath":Engine.get_singleton(singleton)
#		})
##		items[Engine.get_singleton(singleton)] = item
#		item.set_icon(0,get_theme_icon("Object","EditorIcons"))

#
#func reload_property_list():
#	if is_instance_valid(selected):
#		var node = selected.get_metadata(0)["nodePath"]#get_node_or_null(selected.get_metadata(0)["nodePath"])
#		if is_instance_valid(node):
#			selected_node = node
#			for prop in node.get_property_list():
#				if searching_property in prop["name"] or searching_property == "":
#					if !(prop["usage"] == PROPERTY_USAGE_GROUP or prop["usage"] == PROPERTY_USAGE_CATEGORY):
#						prop_list.add_item(prop["name"])
#						var item = prop_list.get_item_count()-1
#						prop_list.set_item_metadata(item,{
#							"name":prop["name"]
#						})
#						var prop_type = typeof(node.get(prop["name"]))
#						prop_list.set_item_icon(item,get_theme_icon(TypesNormal[prop_type],"EditorIcons"))
#						if prop_type == TYPE_OBJECT:
#							if is_instance_valid(node.get(prop["name"])):
#								if has_theme_icon(node.get(prop["name"]).get_class(),"EditorIcons"):
#									prop_list.set_item_icon(item,get_theme_icon(node.get(prop["name"]).get_class(),"EditorIcons"))
#						match prop_type:
#							TYPE_OBJECT:
#								prop_list.set_item_text(item,prop["name"]+": "+str(node.get(prop["name"])))
#							TYPE_DICTIONARY:
#								prop_list.set_item_text(item,prop["name"]+": [Dictionary]")
#							TYPE_ARRAY:
#								prop_list.set_item_text(item,prop["name"]+": [Array]")
#							_:
#								prop_list.set_item_text(item,prop["name"]+": "+str(node.get(prop["name"])))
#					else:
#						prop_list.add_item(prop["name"])
#						var item = prop_list.get_item_count()-1
#						prop_list.set_item_disabled(item,true)
#						if ClassDB.class_exists(prop["name"]):
#							if has_theme_icon(prop["name"],"EditorIcons"):
#								prop_list.set_item_icon(item,get_theme_icon(prop["name"],"EditorIcons"))
#	else:
#		clear_lists()
#func reload_method_list():
#	if selected != null:
#		var node = selected.get_metadata(0)["nodePath"]#get_node_or_null(selected.get_metadata(0)["nodePath"])
#		if is_instance_valid(node):
#			selected_node = node
#			for method in node.get_method_list():
#				if searching_method in method["name"] or searching_method == "":
#					var args = []
#					for arg in method["args"]:
#						args.append(arg["name"])
#					var item = method_list.get_item_count()
#					method_list.add_item(method["name"]+"("+str(args).replace("[","").replace("]","")+")")
#					if not ClassDB.class_has_method(node.get_class(),method["name"],false) and node.has_method(method["name"]):
#						method_list.set_item_custom_fg_color(item,Color.POWDER_BLUE)
#					#bizzare glitch involving Node and Object methods, some are even registered twice?? calling them won't do anything so its ok to remove_at them
#					var forbidden_methods = ["_process","_init","free","_ready","_unhandled_input","_input"]
#					if forbidden_methods.has(method["name"]):
#						method_list.remove_item(item)
#						continue
#					method_list.set_item_icon(item,get_theme_icon(TypesNormal[method["return"]["type"]],"EditorIcons"))
#					method_list.set_item_metadata(item,{
#							"method_data":method
#					})
#
#func clear_lists():
#	selected = get_selected()
#	prop_list.clear()
#	method_list.clear()
#
#func get_children_recursive(start,parent):
#	for node in start.get_children():
##		print(node.name)
#		if !is_instance_valid(node):
#			continue
#		if not searching_node in node.name and searching_node != "":
#			get_children_recursive(node,parent)
#			continue
##		elif searching_for in node.name:
##			print("Found searched node: "+node.name)
#		await get_tree().create_timer(0.01).timeout
#		var nodeItem = create_item(parent)
#		nodeItem.set_collapsed(true)
#		nodeItem.set_text(0,node.name)
#		nodeItem.set_icon(0,get_theme_icon(node.get_class(),"EditorIcons"))
#		nodeItem.set_metadata(0,
#		{
#			"nodePath":node#.get_path()
#		})
#		if nodeItem.get_parent() == get_root():
#			nodeItem.free()
#		else:
#			pass
##			items[node] = nodeItem
#		get_children_recursive(node,nodeItem)
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
##	var root = get_root()
##	if root != null:
##		root.call_recursive("set_custom_color",0,Color(randf(),randf(),randf(),1))
#
#func _on_reload_button_pressed():
#	reload()
#
#func _on_node_tree_item_activated():
#	selected = get_selected()
#	if is_instance_valid(selected):
#		clear_lists()
#		if !is_instance_valid(selected.get_metadata(0)["nodePath"]):
#			selected.free()
#		reload_property_list()
#		reload_method_list()
#
#
#func _on_property_list_item_activated(index):
#	if !prop_list.is_item_disabled(index):
#		selected_property = prop_list.get_item_metadata(index)["name"]
#		prop_edit.set_text(var_to_str(selected_node.get(selected_property)))
#
#
#func _on_set_property_button_pressed():
#	if is_instance_valid(selected_node) and selected_property != "" and not "=" in prop_edit.text:
#		selected_node.set(selected_property,str_to_var(prop_edit.text))
#		prop_list.clear()
#		await get_tree().create_timer(0.01).timeout
##		clear_lists()
#		reload_property_list()
#	elif is_instance_valid(selected_node) and "=" in prop_edit.text:
#		var string = prop_edit.text.split("=")
#		var prop = string[0]
#		var args = string[1]
#		selected_node.set(prop,str_to_var(args))
#		prop_list.clear()
#		await get_tree().create_timer(0.01).timeout
##		clear_lists()
#		reload_property_list()
##	selected = null
##	selected_node = null
##	selected_method = ""
##	selected_property = ""
##	reload()
##	_on_node_tree_item_activated()
#
#func _print(s):
#	print(s)
#
#func _on_call_method_button_pressed():
#	if is_instance_valid(selected_node) and selected_method != "":
#		if method_edit.text.begins_with("p"):
#			print(selected_node.callv(selected_method,str_to_var(method_edit.text.right(1))))
#		elif method_edit.text.begins_with("["):   
#			selected_node.callv(selected_method,str_to_var(method_edit.text))
#		elif "=" in method_edit.text:
#			var string = method_edit.text.split("=")
#			var method = string[0]
#			var args = string[1]
#			selected_node.callv(method,str_to_var(args))
#	elif is_instance_valid(selected_node) and not method_edit.text.begins_with("[") and "=" in method_edit.text:
#			var string = method_edit.text.split("=")
#			var method = string[0]
#			var args = string[1]
##			prints(method,args)
#			selected_node.callv(method,str_to_var(args))
#
#func _on_method_list_item_activated(index):
#	selected_method = method_list.get_item_metadata(index)["method_data"]["name"]
#	var args = []
#	for arg in method_list.get_item_metadata(index)["method_data"]["args"]:
#		args.append(arg["name"])
#	method_edit.set_text(var_to_str(args))
#
#
#func _on_Search_text_entered(new_text):
#	searching_node = new_text
#	reload()
#
#
#func _on_PropertySearch_text_entered(new_text):
#	searching_property = new_text
#	prop_list.clear()
#	reload_property_list()
#
#
#func _on_MethodSearch_text_entered(new_text):
#	searching_method = new_text
#	method_list.clear()
#	reload_method_list()
#
#func _on_CloseButton_pressed():
#	get_parent().hide()
#
#func _on_Node_Explorer_visibility_changed():
#	if get_parent().visible:
#		OS.window_size = Vector2(1024,600)
#		get_viewport().size = Vector2(1024,600)
#		get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_DISABLED,SceneTree.STRETCH_ASPECT_IGNORE,Vector2(1024,600))
#		OS.window_position = OS.get_screen_size()/2 - OS.window_size/2
#	else:
#		get_viewport().size = Vector2(160,144)
#		OS.window_size = Vector2(640,576)
#		get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_2D,SceneTree.STRETCH_ASPECT_EXPAND,Vector2(160,144))
#		OS.window_position = OS.get_screen_size()/2 - OS.window_size/2
#		get_tree().current_scene.get_node("%Inventory").inv.get_child(0).grab_focus()
