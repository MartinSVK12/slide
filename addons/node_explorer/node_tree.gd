extends Tree
class_name NodeTree

@onready var prop_list: ItemList = get_parent().get_node("PropertyList")
@onready var method_list: ItemList = get_parent().get_node("MethodList")
@onready var prop_edit: LineEdit = get_parent().get_node("PropertyEdit")
@onready var method_edit: LineEdit = get_parent().get_node("MethodEdit")
@onready var res_tree: Tree = get_parent().get_node("ResourceTree")

var selected: TreeItem = null
var selected_property: String = ""
var selected_method: String = ""
var selected_node: Object = null

var searching_node = ""
var searching_property = ""
var searching_method = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	get_tree().connect("node_removed",Callable(self,"check_node_validity"))
	var item = create_item()
	item.set_text(0,"Tree uninitialized.")
	item.set_selectable(0,false)
	item = create_item()
	item.set_text(0,"Press 'Reload'.")
	item.set_selectable(0,false)
	NELogger.info("Node explorer ready!")
	
const BuiltinSingletons = ["IP", "ProjectSettings", "InputMap", "Performance",
"Input","OS","Engine","ClassDB","Marshalls","Geometry2D","ResourceLoader","ResourceSaver","Time","DisplayServer","RenderingServer","AudioServer"]


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
func check_node_validity(node):
	if !is_instance_valid(selected_node):
		clear_lists()
		selected = null
		selected_method = ""
		selected_property = ""
		selected_node = null

func reload():
	clear()
	var root = create_item()
	root.set_text(0,"SceneTree")
	root.set_metadata(0,
		{
			"nodePath":get_tree()
		})
	root.set_icon(0,get_theme_icon("Object","EditorIcons"))
	var viewport = create_item(root)
	viewport.set_text(0,"root")
	viewport.set_metadata(0,
		{
			"nodePath":get_viewport()
		})
	viewport.set_icon(0,get_theme_icon(get_node("/root").get_class(),"EditorIcons"))
	get_children_recursive(get_node("/root"),viewport)
	for singleton in BuiltinSingletons:
		var item = create_item(root)
		item.set_text(0,singleton)
		item.set_metadata(0,
		{
			"nodePath":Engine.get_singleton(singleton)
		})
		item.set_icon(0,get_theme_icon("Object","EditorIcons"))
	

func reload_property_list():
	if is_instance_valid(selected):
		var node = selected.get_metadata(0)["nodePath"]
		if is_instance_valid(node):
			selected_node = node
			for prop in node.get_property_list():
				if searching_property in prop["name"] or searching_property == "":
					if !(prop["usage"] == PROPERTY_USAGE_GROUP or prop["usage"] == PROPERTY_USAGE_CATEGORY):
						prop_list.add_item(prop["name"])
						var item = prop_list.get_item_count()-1
						prop_list.set_item_metadata(item,{
							"name":prop["name"]
						})
						var prop_type = typeof(node.get(prop["name"]))
						prop_list.set_item_icon(item,get_theme_icon(TypesNormal[prop_type],"EditorIcons"))
						if prop_type == TYPE_OBJECT:
							if is_instance_valid(node.get(prop["name"])):
								if has_theme_icon(node.get(prop["name"]).get_class(),"EditorIcons"):
									prop_list.set_item_icon(item,get_theme_icon(node.get(prop["name"]).get_class(),"EditorIcons"))
						match prop_type:
							TYPE_OBJECT:
								prop_list.set_item_text(item,prop["name"]+": "+str(node.get(prop["name"])))
							TYPE_DICTIONARY:
								prop_list.set_item_text(item,prop["name"]+": [Dictionary]")
							TYPE_ARRAY:
								prop_list.set_item_text(item,prop["name"]+": [Array]")
							_:
								prop_list.set_item_text(item,prop["name"]+": "+str(node.get(prop["name"])))
					else:
						prop_list.add_item(prop["name"])
						var item = prop_list.get_item_count()-1
						prop_list.set_item_disabled(item,true)
						if ClassDB.class_exists(prop["name"]):
							if has_theme_icon(prop["name"],"EditorIcons"):
								prop_list.set_item_icon(item,get_theme_icon(prop["name"],"EditorIcons"))
	else:
		clear_lists()
func reload_method_list():
	if selected != null:
		var node = selected.get_metadata(0)["nodePath"]
		if is_instance_valid(node):
			selected_node = node
			for method in node.get_method_list():
				if searching_method in method["name"] or searching_method == "":
					var args = []
					for arg in method["args"]:
						args.append(arg["name"])
					var item = method_list.get_item_count()
					method_list.add_item(method["name"]+"("+str(args).replace("[","").replace("]","")+")")
					if not ClassDB.class_has_method(node.get_class(),method["name"],false) and node.has_method(method["name"]):
						method_list.set_item_custom_fg_color(item,Color.POWDER_BLUE)
					#some methods should just not be called so its ok to remove_at them
					var forbidden_methods = ["_process","_init","free","_ready","_unhandled_input","_input"]
					if forbidden_methods.has(method["name"]):
						method_list.remove_item(item)
						continue
					method_list.set_item_icon(item,get_theme_icon(TypesNormal[method["return"]["type"]],"EditorIcons"))
					method_list.set_item_metadata(item,{
							"method_data":method
					})

func clear_lists():
	selected = get_selected()
	prop_list.clear()
	method_list.clear()

func get_children_recursive(start,parent):
	for node in start.get_children():
		if !is_instance_valid(node):
			continue
		if not searching_node in node.name and searching_node != "":
			get_children_recursive(node,parent)
			continue
		await get_tree().create_timer(0.01).timeout
		var nodeItem = create_item(parent)
		nodeItem.set_collapsed(true)
		nodeItem.set_text(0,node.name)
		
		nodeItem.set_icon(0,get_theme_icon(node.get_class(),"EditorIcons"))
		nodeItem.set_metadata(0,
		{
			"nodePath":node
		})
		if nodeItem.get_parent() == get_root():
			nodeItem.free()
		else:
			pass
		get_children_recursive(node,nodeItem)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_reload_button_pressed():
	reload()

func _on_node_tree_item_activated():
	selected = get_selected()
	if is_instance_valid(selected):
		clear_lists()
		if !is_instance_valid(selected.get_metadata(0)["nodePath"]):
			selected.free()
		reload_property_list()
		reload_method_list()

func _on_resource_tree_item_activated():
	var _selected = res_tree.get_selected()
	if is_instance_valid(_selected):
		if typeof(_selected.get_metadata(0)) == TYPE_DICTIONARY:
			if _selected.get_metadata(0).has("nodePath"):
				if is_instance_valid(_selected.get_metadata(0)["nodePath"]):
					selected = _selected
					prop_list.clear()
					method_list.clear()
					reload_property_list()
					reload_method_list()
		


func _on_property_list_item_activated(index):
	if !prop_list.is_item_disabled(index):
		selected_property = prop_list.get_item_metadata(index)["name"]
		prop_edit.set_text(var_to_str(selected_node.get(selected_property)))


func _on_set_property_button_pressed():
	if is_instance_valid(selected_node) and selected_property != "" and not "=" in prop_edit.text:
		selected_node.set(selected_property,str_to_var(prop_edit.text))
		prop_list.clear()
		await get_tree().create_timer(0.01).timeout
		reload_property_list()
	elif is_instance_valid(selected_node) and "=" in prop_edit.text:
		var string = prop_edit.text.split("=")
		var prop = string[0]
		var args = string[1]
		selected_node.set(prop,str_to_var(args))
		prop_list.clear()
		await get_tree().create_timer(0.01).timeout
		reload_property_list()

func _print(s):
	print(s)

func _on_call_method_button_pressed():
	if is_instance_valid(selected_node) and selected_method != "":
		if method_edit.text.begins_with(":p"):
			print(selected_node.callv(selected_method,str_to_var(method_edit.text.substr(2))))
		elif method_edit.text.begins_with("["):   
			selected_node.callv(selected_method,str_to_var(method_edit.text))
		elif "=" in method_edit.text:
			var string = method_edit.text.split("=")
			var method = string[0]
			var args = string[1]
			selected_node.callv(method,str_to_var(args))
	elif is_instance_valid(selected_node) and not method_edit.text.begins_with("[") and "=" in method_edit.text:
			var string = method_edit.text.split("=")
			var method = string[0]
			var args = string[1]
			selected_node.callv(method,str_to_var(args))

func _on_method_list_item_activated(index):
	selected_method = method_list.get_item_metadata(index)["method_data"]["name"]
	var args = []
	for arg in method_list.get_item_metadata(index)["method_data"]["args"]:
		args.append(arg["name"])
	method_edit.set_text(var_to_str(args))


func _on_Search_text_entered(new_text):
	searching_node = new_text
	reload()


func _on_PropertySearch_text_entered(new_text):
	searching_property = new_text
	prop_list.clear()
	reload_property_list()


func _on_MethodSearch_text_entered(new_text):
	searching_method = new_text
	method_list.clear()
	reload_method_list()

func _on_CloseButton_pressed():
	get_parent().hide()

func _on_Node_Explorer_visibility_changed():
	pass


func _on_CheckButton_toggled(button_pressed):
	get_parent().get_node("ResourceTree").visible = button_pressed
	get_parent().get_node("ResourceTree").reload()
