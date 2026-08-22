extends Node
class_name NodeExplorerCLI

var thread: Thread = Thread.new()

var selected: Object
var selected_collection
var selected_collection_name: String
var selected_obj_name: String
var selected_property: String
var selected_method: String
var selected_signal: String
var resource_mode: bool = false
@export var active: bool = false
@export var threaded: bool = true

const GlobalScope: Array[Callable] = [
	abs, absf, absi, acos, acosh, angle_difference, asin, asinh, atan, atan2, atanh, bezier_derivative, 
	bezier_interpolate, bytes_to_var, bytes_to_var_with_objects, ceil, ceilf, ceili, clamp, clampf, 
	clampi, cos, cosh, cubic_interpolate, cubic_interpolate_angle, cubic_interpolate_angle_in_time, 
	cubic_interpolate_in_time, db_to_linear, deg_to_rad, ease, error_string, exp, floor, floorf, floori, 
	fmod, fposmod, hash, instance_from_id, inverse_lerp, is_equal_approx, is_finite, is_inf, 
	is_instance_id_valid, is_instance_valid, is_nan, is_same, is_zero_approx, lerp, lerp_angle, 
	lerpf, linear_to_db, log, max, maxf, maxi, min, minf, mini, move_toward, nearest_po2, pingpong, 
	posmod, pow, print, print_rich, print_verbose, printerr, printraw, prints, printt, push_error, 
	push_warning, rad_to_deg, rand_from_seed, randf, randf_range, randfn, randi, randi_range, randomize, remap, rid_allocate_id, 
	rid_from_int64, rotate_toward, round, roundf, roundi, seed, sign, signf, signi, sin, sinh, smoothstep, 
	snapped, snappedf, snappedi, sqrt, step_decimals, str, str_to_var, tan, tanh, type_convert, type_string, 
	typeof, var_to_bytes, var_to_bytes_with_objects, var_to_str, weakref, wrap, wrapf, wrapi, Color8, 
	char, convert, dict_to_inst, get_stack, is_instance_of, len, load, print_debug, print_stack, range, type_exists, 
]

func activate(args: PackedStringArray):
	active = true
	
func help(args: PackedStringArray):
	if args.size() == 0:
		NELogger.info("Available commands: "+str(commands.keys()).replace("\"","").replace("[","").replace("]","").right(-2))
	elif args.size() == 1:
		NELogger.info(str(commands[args[0]][1]))

func tree(args: PackedStringArray):
	selected = get_tree()
	selected_obj_name = "SceneTree"

func ls(args: PackedStringArray):
	var all: bool = args.has("-all")
	var no_singletons: bool = args.has("-ns")
	var root_tree = print_tree_custom(get_tree().get_root(),"",true,!all,no_singletons)
	if selected is not Node:
		if selected == get_tree():
			NELogger.info("\n[color=cyan]SceneTree[/color]\n"+root_tree)
		else:
			NELogger.info("\n"+root_tree)
	else:
		var tree = print_tree_custom(selected,"",true,!all,no_singletons)	
		NELogger.info("\n"+tree)

func resources(args: PackedStringArray):
	var props: Array[Dictionary] = selected.get_property_list()
	var prop_tree = " ┖╴" + "[color=cyan]" + (selected.get_name() if selected is Node else selected_obj_name) + "[/color]" + "\n"
	var i: int = 0
	for prop in props:
		i += 1
		var type: int = prop["type"]
		var is_category = (prop["usage"] == PROPERTY_USAGE_GROUP or prop["usage"] == PROPERTY_USAGE_CATEGORY or prop["usage"] == PROPERTY_USAGE_SUBGROUP)
		var color = "[color=red]" if is_category else "[color=white]"
		var type_s = ""
		var value_s = ""
		if not is_category:
			type_s = ": [color=orange]{0}[/color]".format([NodeTree.TypesNormal[type]])
			if type == TYPE_ARRAY:
				value_s = " = [color=yellow][Array: {0} elements][/color]".format([selected.get(prop["name"]).size()])
			elif type == TYPE_DICTIONARY:
				value_s = " = [color=yellow][Dictionary: {0} elements][/color]".format([selected.get(prop["name"]).size()])
			else:
				if type != TYPE_OBJECT:
					continue
				value_s = " = [color=yellow]"+str(selected.get(prop["name"]))+"[/color]"
				if type == TYPE_STRING:
					value_s = " = [color=yellow]"+str((selected.get(prop["name"]) as String).c_escape().replace("[","|").replace("]","|"))+"[/color]"
				if str(selected.get(prop["name"])) == "" and (type == TYPE_STRING or type == TYPE_STRING_NAME or type == TYPE_NODE_PATH):
					value_s = " = [color=yellow]\"\"[/color]"
		else:
			continue
		prop_tree += ("    ┖╴" if i == props.size() else "    ┠╴") + color + prop["name"] + type_s + value_s + "[/color]" + "\n"
	NELogger.info_logged.emit(true,false,prop_tree)

func cd(args: PackedStringArray):
	var last_selected = selected
	if args.size() <= 0:
		return
	var path = args[0]
	if resource_mode:
		if path != ".." and selected_collection != null:
			if selected_collection is Array and path.is_valid_int():
				var index: int = path.to_int()
				var value = selected_collection[index]
				if value is Object:
					selected = value
					selected_obj_name = str(value)
				elif value is Dictionary or value is Array:
					selected_collection = value
					selected_collection_name = path
			elif selected_collection is Dictionary:
				if selected_collection.has(str_to_var(path)):
					var value = selected_collection[str_to_var(path)]
					if value is Object:
						selected = value
						selected_obj_name = path
					elif value is Dictionary or value is Array:
						selected_collection = value
						selected_collection_name = path
		if path == "..":
			if selected_collection != null:
				selected_collection = null
				selected_collection_name = ""
			return
		var props = selected.get_property_list().map(func(dict): return dict["name"])
		if props.has(path):
			var value = selected.get(path)
			if value is Object:
				selected = value
				selected_obj_name = path
			elif value is Dictionary or value is Array:
				selected_collection = value
				selected_collection_name = path
		return
	if path == "..":
		if selected is Node and not selected == get_tree().get_root():
			selected = (selected as Node).get_parent()
		if selected is Object and selected is not Node:
			selected = get_tree().get_root()
	elif path.begins_with("/"):
		selected = get_node(path)
		if selected == null:
			selected = get_tree().get_root()
	elif NodeTree.BuiltinSingletons.has(path):
		selected = Engine.get_singleton(path)
		selected_obj_name = path
	else:
		if selected is Node:
			selected = selected.get_node(path)
	if selected == null:
		selected = last_selected
	selected_property = ""
	selected_method = ""

func props(args: PackedStringArray):
	var props: Array[Dictionary] = selected.get_property_list()
	var prop_tree = " ┖╴" + "[color=cyan]" + (selected.get_name() if selected is Node else selected_obj_name) + "[/color]" + "\n"
	var i: int = 0
	for prop in props:
		i += 1
		var type: int = prop["type"]
		var is_category = (prop["usage"] == PROPERTY_USAGE_GROUP or prop["usage"] == PROPERTY_USAGE_CATEGORY or prop["usage"] == PROPERTY_USAGE_SUBGROUP)
		var color = "[color=red]" if is_category else "[color=white]"
		var type_s = ""
		var value_s = ""
		if not is_category:
			type_s = ": [color=orange]{0}[/color]".format([NodeTree.TypesNormal[type]])
			if type == TYPE_ARRAY:
				value_s = " = [color=yellow][Array: {0} elements][/color]".format([selected.get(prop["name"]).size()])
			elif type == TYPE_DICTIONARY:
				value_s = " = [color=yellow][Dictionary: {0} elements][/color]".format([selected.get(prop["name"]).size()])
			else:
				value_s = " = [color=yellow]"+str(selected.get(prop["name"]))+"[/color]"
				if type == TYPE_STRING:
					value_s = " = [color=yellow]"+str((selected.get(prop["name"]) as String).c_escape().replace("[","|").replace("]","|"))+"[/color]"
				if str(selected.get(prop["name"])) == "" and (type == TYPE_STRING or type == TYPE_STRING_NAME or type == TYPE_NODE_PATH):
					value_s = " = [color=yellow]\"\"[/color]"
		prop_tree += ("    ┖╴" if i == props.size() else "    ┠╴") + color + prop["name"] + type_s + value_s + "[/color]" + "\n"
	NELogger.info_logged.emit(true,false,prop_tree)

func collection_values(args: PackedStringArray):
	if resource_mode and selected_collection != null:
		if selected_collection is Array:
			var prop_tree = " ┖╴" + "[color=cyan]" + (selected_collection_name) + "[/color]" + "\n"
			var i: int = 0
			for el in selected_collection:
				i += 1
				var element: String
				if el is Array:
					element = "[color=orange]" + NodeTree.TypesNormal[typeof(el)].replace("Nil","Variant") + "[/color] " + "= [color=yellow][Array: {0} elements][/color]".format([el.size()])
				elif el is Dictionary:
					element = "[color=orange]" + NodeTree.TypesNormal[typeof(el)].replace("Nil","Variant") + "[/color] " + "= [color=yellow][Dictionary: {0} elements][/color]".format([el.size()])
				else:
					element = "[color=orange]" + NodeTree.TypesNormal[typeof(el)].replace("Nil","Variant") + "[/color] " + "= [color=yellow]"+str(el)+"[/color]"
				prop_tree += ("    ┖╴" if i == selected_collection.size() else "    ┠╴") + str(i) + ": " + element + "\n"
			NELogger.info_logged.emit(true,false,prop_tree)
		elif selected_collection is Dictionary:
			var prop_tree = " ┖╴" + "[color=cyan]" + (selected_collection_name) + "[/color]" + "\n"
			var i: int = 0
			for el in selected_collection.values():
				i += 1
				var element: String
				if el is Array:
					element = "[color=orange]" + NodeTree.TypesNormal[typeof(el)].replace("Nil","Variant") + "[/color] " + "= [color=yellow][Array: {0} elements][/color]".format([el.size()])
				elif el is Dictionary:
					element = "[color=orange]" + NodeTree.TypesNormal[typeof(el)].replace("Nil","Variant") + "[/color] " + "= [color=yellow][Dictionary: {0} elements][/color]".format([el.size()])
				else:
					element = "[color=orange]" + NodeTree.TypesNormal[typeof(el)].replace("Nil","Variant") + "[/color] " + "= [color=yellow]"+str(el)+"[/color]"
				prop_tree += ("    ┖╴" if i == selected_collection.size() else "    ┠╴") + str(selected_collection.keys()[i-1]) + ": " + element + "\n"
			NELogger.info_logged.emit(true,false,prop_tree)
	else:
		NELogger.warn("No collection resource selected to view the contents of.")
	pass

func methods(args: PackedStringArray):
	var methods: Array[Dictionary] = selected.get_method_list()
	var method_tree = " ┖╴" + "[color=cyan]" + (selected.get_name() if selected is Node else selected_obj_name) + "[/color]" + "\n"
	var i: int = 0
	for method in methods:
		i += 1
		var method_signature: String = get_method_signature(method)
		method_tree += ("    ┖╴" if i == methods.size() else "    ┠╴") + method_signature + "\n"
	NELogger.info_logged.emit(true,false,method_tree)

func signals(args: PackedStringArray):
	var signals: Array[Dictionary] = selected.get_signal_list()
	var signal_tree = " ┖╴" + "[color=cyan]" + (selected.get_name() if selected is Node else selected_obj_name) + "[/color]" + "\n"
	var i: int = 0
	for _signal in signals:
		i += 1
		var signal_signature: String = get_method_signature(_signal)
		signal_signature = signal_signature.replace("void","signal").replace("gray","red")
		if selected.get_signal_connection_list(_signal["name"]).size() == 0:
			signal_signature += " -> [color=gray]" + str(selected.get_signal_connection_list(_signal["name"]).size()) + " objects connected.[/color]"
		elif selected.get_signal_connection_list(_signal["name"]).size() == 1:
			signal_signature += " -> [color=yellow]" + str(selected.get_signal_connection_list(_signal["name"]).size()) + " object connected.[/color]"
		else:
			signal_signature += " -> [color=yellow]" + str(selected.get_signal_connection_list(_signal["name"]).size()) + " objects connected.[/color]"
		signal_tree += ("    ┖╴" if i == signals.size() else "    ┠╴") + signal_signature + "\n"
	NELogger.info_logged.emit(true,false,signal_tree)

func prop(args: PackedStringArray):
	if args.size() <= 0:
		return
	var subcommand = args[0]
	match subcommand:
		"select":
			if args.size() <= 1:
				return
			var prop = args[1]
			var props = selected.get_property_list().map(func(dict): return dict["name"])
			if props.has(prop):
				selected_property = prop
			pass
		"unselect":
			selected_property = ""
			pass
		"has":
			if args.size() <= 1:
				return
			var prop = args[1]
			var props = selected.get_property_list().map(func(dict): return dict["name"])
			if props.has(prop):
				NELogger.info_logged.emit(true,false,"true: [color=red]"+str(selected.get(prop))+"[/color]")
			else:
				NELogger.info_logged.emit(false,false,"false")
		"set":
			if args.size() <= 1:
				return
			var prop = args[1]
			var props = selected.get_property_list().map(func(dict): return dict["name"])
			if props.has(prop):
				var set_args: PackedStringArray = args.slice(2)
				var s: String
				for arg in set_args:
					s += arg + " "
				s = s.strip_edges()
				var old_value = selected.get(prop)
				selected.set(prop,str_to_var(s))
				NELogger.info_logged.emit(false,false,prop + " = " + str(old_value) + " -> " + s)
				pass
			else:
				if selected_property != "":
					var set_args: PackedStringArray = args.slice(1)
					var s: String
					for arg in set_args:
						s += arg + " "
					s = s.strip_edges()
					var old_value = selected.get(selected_property)
					selected.set(selected_property,str_to_var(s))
					NELogger.info_logged.emit(false,false,selected_property + " = " + str(old_value) + " -> " + str(s))
			pass

func method(args: PackedStringArray):
	if args.size() <= 0:
		return
	var subcommand = args[0]
	match subcommand:
		"select":
			if args.size() <= 1:
				return
			var method = args[1]
			var methods = selected.get_method_list().map(func(dict): return dict["name"])
			if methods.has(method):
				selected_method = method
			pass
		"unselect":
			selected_method = ""
		"has":
			if args.size() <= 1:
				return
			var method = args[1]
			var methods = selected.get_method_list().map(func(dict): return dict["name"])
			var name_key_methods: Dictionary = {}
			var i: int = 0
			for m in methods:
				name_key_methods[m] = selected.get_method_list()[i]
				i += 1
			
			if methods.has(method):
				NELogger.info_logged.emit(true,false,"true: "+get_method_signature(name_key_methods[method]))
			else:
				NELogger.info_logged.emit(false,false,"false")
		"call":
			var method: String = ""
			if args.size() >= 2: method = args[1]
			var methods = selected.get_method_list().map(func(dict): return dict["name"])
			if methods.has(method):
				var combine_args: PackedStringArray = args.slice(2)
				var s: String = ""
				for arg in combine_args:
					s += arg + " "
				s = s.strip_edges()
				var call_arg_string_array: PackedStringArray = s.split(";",false)
				var call_args: Array = []
				for call_arg_s in call_arg_string_array:
					call_args.append(str_to_var(call_arg_s))
				var result = selected.callv(method,call_args)
				NELogger.info_logged.emit(true,false,"{0} -> [color=cyan]{1}[/color]".format([method,str(result)]))
			else:
				if selected_method != "":
					var combine_args: PackedStringArray = args.slice(1)
					var s: String = ""
					for arg in combine_args:
						s += arg + " "
					s = s.strip_edges()
					var call_arg_string_array: PackedStringArray = s.split(";",false)
					var call_args: Array = []
					for call_arg_s in call_arg_string_array:
						call_args.append(str_to_var(call_arg_s))
					var result = selected.callv(selected_method,call_args)
					NELogger.info_logged.emit(true,false,"{0} -> [color=cyan]{1}[/color]".format([selected_method,result]))
					

func cmd_signal(args: PackedStringArray):
	if args.size() <= 0:
		return
	var subcommand = args[0]
	match subcommand:
		"select":
			if args.size() <= 1:
				return
			var _signal = args[1]
			var signals = selected.get_signal_list().map(func(dict): return dict["name"])
			if signals.has(_signal):
				selected_signal = _signal
			pass
		"unselect":
			selected_signal = ""
		"connections":
			var _signal: String = ""
			if args.size() >= 2: _signal = args[1]
			var signals = selected.get_signal_list().map(func(dict): return dict["name"])
			if signals.has(_signal):
				var connections_list: Array[Dictionary] = selected.get_signal_connection_list(_signal)
				var name_key_signals: Dictionary = {}
				var j: int = 0
				for s in selected.get_signal_list():
					name_key_signals[selected.get_signal_list()[j]["name"]] = s
					j += 1
				var signal_signature: String = get_method_signature(name_key_signals[_signal])
				signal_signature = signal_signature.replace("void","signal").replace("gray","red")
				var connection_tree = " ┖╴" + (signal_signature) + "\n"
				var i: int = 0
				for con in connections_list:
					i += 1
					var signal_con_signature: String = str(con["callable"])
					if (con["callable"] as Callable).get_object() is Node:
						signal_con_signature += " at [color=cyan]" + str(((con["callable"] as Callable).get_object() as Node).get_path()) + "[/color]"
					connection_tree += ("    ┖╴" if i == connections_list.size() else "    ┠╴") + signal_con_signature + "\n"
				NELogger.info_logged.emit(true,false,connection_tree)
				pass
			else:
				if selected_signal != "":
					var connections_list: Array[Dictionary] = selected.get_signal_connection_list(selected_signal)
					var name_key_signals: Dictionary = {}
					var j: int = 0
					for s in selected.get_signal_list():
						name_key_signals[selected.get_signal_list()[j]["name"]] = s
						j += 1
					var signal_signature: String = get_method_signature(name_key_signals[selected_signal])
					signal_signature = signal_signature.replace("void","signal").replace("gray","red")
					var connection_tree = " ┖╴" + (signal_signature) + "\n"
					var i: int = 0
					for con in connections_list:
						i += 1
						var signal_con_signature: String = str(con["callable"])
						if (con["callable"] as Callable).get_object() is Node:
							signal_con_signature += " at [color=cyan]" + str(((con["callable"] as Callable).get_object() as Node).get_path())  + "[/color]"
						connection_tree += ("    ┖╴" if i == connections_list.size() else "    ┠╴") + signal_con_signature + "\n"
					NELogger.info_logged.emit(true,false,connection_tree)
					pass
		"emit":
			var _signal: String = ""
			if args.size() >= 2: _signal = args[1]
			var signals = selected.get_signal_list().map(func(dict): return dict["name"])
			if signals.has(_signal):
				var combine_args: PackedStringArray = args.slice(2)
				var s: String = ""
				for arg in combine_args:
					s += arg + " "
				s = s.strip_edges()
				var call_arg_string_array: PackedStringArray = s.split(";",false)
				var call_args: Array = []
				for call_arg_s in call_arg_string_array:
					call_args.append(str_to_var(call_arg_s))
				selected.emit_signal(_signal,call_args)
				NELogger.info("Emitted: {0}({1})".format([_signal,call_args]))
			else:
				if selected_signal != "":
					var combine_args: PackedStringArray = args.slice(1)
					var s: String = ""
					for arg in combine_args:
						s += arg + " "
					s = s.strip_edges()
					var call_arg_string_array: PackedStringArray = s.split(";",false)
					var call_args: Array = []
					for call_arg_s in call_arg_string_array:
						call_args.append(str_to_var(call_arg_s))
					selected.emit_signal(selected_signal,call_args)
					NELogger.info("Emitted: {0}({1})".format([_signal,call_args]))
		_:
			pass

func res(args: PackedStringArray):
	resource_mode = !resource_mode
	if not resource_mode:
		selected_collection = null
		selected_collection_name = ""
	NELogger.info("Resource mode toggled.")

func unselect_all(args: PackedStringArray):
	selected_method = ""
	selected_property = ""
	selected_signal = ""

func call_global(args: PackedStringArray):
	if args.size() <= 0:
		return
	var combine_args: PackedStringArray = args.slice(1)
	var s: String = ""
	for arg in combine_args:
		s += arg + " "
	s = s.strip_edges()
	var call_arg_string_array: PackedStringArray = s.split(";",false)
	var call_args: Array = []
	for call_arg_s in call_arg_string_array:
		call_args.append(str_to_var(call_arg_s))
	var method: String = args[0]
	var global_method_names: Array = GlobalScope.map(func(c: Callable): return c.get_method())
	var i: int = global_method_names.find(method)
	var result = GlobalScope[i].callv(call_args)
	NELogger.info_logged.emit(true,false,"{0} -> [color=cyan]{1}[/color]".format([method,str(result)]))
	pass

func call_res(args: PackedStringArray):
	if args.size() <= 0 or !resource_mode:
		return
	var combine_args: PackedStringArray = args.slice(1)
	var s: String = ""
	for arg in combine_args:
		s += arg + " "
	s = s.strip_edges()
	var call_arg_string_array: PackedStringArray = s.split(";",false)
	var call_args: Array = []
	for call_arg_s in call_arg_string_array:
		call_args.append(str_to_var(call_arg_s))
	var method: String = args[0]
	var result = Callable.create(selected_collection,method).callv(call_args)
	NELogger.info_logged.emit(true,false,"{0} -> [color=cyan]{1}[/color]".format([method,str(result)]))
	pass

func exit(args: PackedStringArray):
	active = false

var commands: Dictionary = {
	"": [activate,"Activates the program: ne"],
	"help": [help,"Shows info about commands: help (command)"],
	"tree": [tree,"Selects the scene tree: tree"],
	"ls": [ls,"Shows a tree of the selected node and its children: ls (-all,-ns)\n	-all: Shows the entire scene tree\n	-ns: Hides singletons"],
	"c": [cd,"Changes the selected node: c [path]"],
	"props": [props,"Prints out all of the properies of the selected node: props"],
	"methods": [methods,"Prints out all of the methods of the selected node: methods"],
	"signals": [signals,"Prints out all of the signals of the selected node: signals"],
	"prop": [prop,"Property manipulation on the selected node: prop [select/unselect/has/set]\n	prop select [name]\n	prop unselect\n	prop has [name]\n	prop set (name) [value]"],
	"method": [method,"Method calling on the selected node: method [select/unselect/has/call]\n	method select [name]\n	method unselect\n	method has [name]\n	method call (name) [args...]"],
	"signal": [cmd_signal,"View the connections of or emit a signal in the specified node: signal [select/unselect/connections/emit]\n	signal select [name]\n	signal unselect\n	signal connections (name)\n	signal emit (name) [args...]"],
	"rm": [res,"Enables resource mode: rm"],
	"rs": [resources,"Limited view of \"props\", that includes only objects or collections: rs"],
	"contents": [collection_values,"(Only in resource mode) Prints out the elements of the selected collection: contents"],
	"unselect_all": [unselect_all,"Resets selections, selecting the root node of the scene tree once again: unselect_all"],
	"call_global": [call_global,"Calls a global function: call_global [name] (args...)"],
	"call_res": [call_res,"(Only in resource mode) Calls the provided method on the selected resource: call_res [name] (args...)"],
	"exit": [exit, "Exits the program: exit"]
}

func print_tree_custom(node: Node, prefix: String, last: bool, only_direct_children: bool, no_singletons: bool = false, depth: int = 0) -> String:
	var new_prefix: String = " ┖╴" if last else " ┠╴"
	if node == get_tree().get_root() and not no_singletons:
		new_prefix = " ┠╴"
	var is_selected: String = "[color=cyan]" if node == selected else "[color=white]"
	var return_tree: String = prefix + new_prefix + is_selected + node.get_name() + "[/color]" + "\n"
	if depth > 0 and only_direct_children:
		return return_tree
	depth += 1
	for i in node.get_child_count():
		var child = node.get_child(i)
		if node == get_tree().get_root() and not no_singletons:
			new_prefix = " ┃ "
		else:
			new_prefix = "   " if last else " ┃ "
		return_tree += print_tree_custom(child,prefix + new_prefix,i == node.get_child_count() - 1,only_direct_children,no_singletons,depth)
	if node == get_tree().get_root() and not no_singletons:
		var i: int = 0
		for singleton in NodeTree.BuiltinSingletons:
			i += 1
			var child = Engine.get_singleton(singleton)
			is_selected = "[color=cyan]" if child == selected else "[color=yellow]"
			var new_p: String = " ┖╴" if i == NodeTree.BuiltinSingletons.size() else " ┠╴"
			return_tree += prefix + new_p + is_selected + singleton + "[/color]" + "\n"
	return return_tree

func get_method_signature(method: Dictionary) -> String:
	var const_flag = method["flags"] &   0b0000100
	var virtual_flag = method["flags"] & 0b0001000
	var vararg_flag = method["flags"] &  0b0010000
	var static_flag = method["flags"] &  0b0100000
	var flags_s: String
	if const_flag:
		flags_s += " [color=cyan]const[/color] "
	if virtual_flag:
		flags_s += " [color=cyan]virtual[/color] "
	if vararg_flag:
		flags_s += " [color=cyan]varargs[/color] "
	if static_flag:
		flags_s += " [color=cyan]static[/color] "
	flags_s = flags_s.strip_edges()
	var is_local: String = "[color=yellow]" if (not ClassDB.class_has_method(selected.get_class(),method["name"],false) and selected.has_method(method["name"])) else "[color=white]"
	var type_s: String = "[color=orange]{0}[/color]".format([NodeTree.TypesNormal[method["return"]["type"]]])
	#methods having "Nil" as their return type are actually "void" methods
	type_s = type_s.replace("Nil","void")
	if type_s.contains("void"):
		type_s = type_s.replace("orange","gray")
	var method_args: Array = method["args"]
	var args_s: String = ""
	var j: int = 0
	for method_arg in method_args:
		j += 1
		if j > method_args.size()-method["default_args"].size():
			var default_arg: String = str(method["default_args"][(j-1)-(method_args.size()-method["default_args"].size())])
			var arg_type: String = NodeTree.TypesNormal[method_arg["type"]]
			if arg_type == "String" or arg_type == "StringName" or arg_type == "NodePath":
				default_arg = "\"" + default_arg + "\""
			#Can't have an arg of type "nil", arg is actually of "Variant" type
			if arg_type == "Nil":
				arg_type = "Variant"
			args_s += "{0}: [color=orange]{1}[/color] = [color=red]{2}[/color], ".format([method_arg["name"],arg_type,default_arg])
		else:
			var arg_type: String = NodeTree.TypesNormal[method_arg["type"]]
			if arg_type == "Nil":
				arg_type = "Variant"
			
			args_s += "{0}: [color=orange]{1}[/color], ".format([method_arg["name"],arg_type])
	args_s = args_s.left(-2)
	return type_s + " " + is_local + method["name"] + "[/color]" + "(" + args_s + ") " + flags_s

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	name = "NeCLI"
	selected = get_tree().get_root()
	if threaded:
		var error: int = thread.start(input_loop)
		if error:
			NELogger.error("Failed to create input thread because {0}!".format([error_string(error)]))
			NELogger.warn("Node explorer CLI failed to start!")
			queue_free()
			return
	NELogger.info("Node explorer CLI ready!")

func input_loop() -> void:
	while true:
		var input = OS.read_string_from_stdin(8192)
		if input.replace("\n","").replace("\r","") == "ne":
			call_deferred_thread_group("parse_action","",[])
			continue
		if input.begins_with("ne ") or active:
			var last_active = active
			if active: input = "ne "+input
			var text = input.right(-3).replace("\n","").replace("\r","")
			var command: String = text.split(" ")[0]
			var args: PackedStringArray = text.split(" ").slice(1)
			#parse_action(command,args)
			call_deferred_thread_group("parse_action",command,args)
			if active == last_active: active = true

func parse_action(command: String, args: PackedStringArray):
	if not is_instance_valid(selected):
		NELogger.warn("Currently selected object is no longer available, selections have been reset.")
		selected_method = ""
		selected_property = ""
		selected_signal = ""
		selected = get_tree().get_root()
		#turned on so "res" can turn it off always
		resource_mode = false
		selected_collection = null
		selected_collection_name = ""
		print_current_state()
		return
	if commands.has(command): (commands[command][0] as Callable).call(args)
	print_current_state()

func print_current_state():
	if active:
		if selected_signal == "":
			if selected_method == "":
				if selected_property == "":
					NELogger.info_logged.emit(false,true,"\n{0}> ".format([selected.get_path() if selected is Node else selected_obj_name]))
				else:
					NELogger.info_logged.emit(false,true,"\n{0}@{1}> ".format([selected_property,selected.get_path() if selected is Node else selected_obj_name]))
			else:
				if selected_property == "":
					NELogger.info_logged.emit(false,true,"\n{0}::{1}> ".format([selected.get_path() if selected is Node else selected_obj_name,selected_method]))
				else:
					NELogger.info_logged.emit(false,true,"\n{0}@{1}::{2}> ".format([selected_property,selected.get_path() if selected is Node else selected_obj_name,selected_method]))
		else:
			if selected_method == "":
				if selected_property == "":
					NELogger.info_logged.emit(false,true,"\n->{1}] {0}> ".format([selected.get_path() if selected is Node else selected_obj_name,selected_signal]))
				else:
					NELogger.info_logged.emit(false,true,"\n->{2}] {0}@{1}> ".format([selected_property,selected.get_path() if selected is Node else selected_obj_name,selected_signal]))
			else:
				if selected_property == "":
					NELogger.info_logged.emit(false,true,"\n->{2}] {0}::{1}> ".format([selected.get_path() if selected is Node else selected_obj_name,selected_method,selected_signal]))
				else:
					NELogger.info_logged.emit(false,true,"\n->{3}] {0}@{1}::{2}> ".format([selected_property,selected.get_path() if selected is Node else selected_obj_name,selected_method,selected_signal]))
		if resource_mode:
			if selected_collection != null:
				NELogger.info_logged.emit(false,true,"RES: {0}> ".format([selected_collection_name]))
			else:
				NELogger.info_logged.emit(false,true,"RES> ")
	NELogger.info_logged.emit(false,false,"\n")

func test():
	NELogger.info("test success")
