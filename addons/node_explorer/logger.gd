extends Node

signal info_logged(color: bool, raw: bool, s: String)
signal warn_logged(color: bool, raw: bool, s: String)
signal error_logged(color: bool, raw: bool, s: String)

func _ready() -> void:
	info_logged.connect(log_to_stdout,CONNECT_REFERENCE_COUNTED)
	warn_logged.connect(log_to_stdout,CONNECT_REFERENCE_COUNTED)
	error_logged.connect(log_to_stdout,CONNECT_REFERENCE_COUNTED)

func info(s) -> void:
	if EngineDebugger.is_active():
		var type := "INFO"
		var time := Time.get_time_string_from_system()
		if get_stack().size() > 1:
			var trace = get_stack()[1]
			var trace_name: String = trace["source"]
			trace_name = trace_name.replace("res://","").split("/")[-1]
			var trace_function: String = trace["function"]
			var trace_line: int = trace["line"]
			if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer is not OfflineMultiplayerPeer:
				if OS.has_feature("web"):
					info_logged.emit(false,false,"[{0}] [{1}]  ({2}::{3}:{4}) [{6}] {5}".format([time,type,trace_name,trace_function,trace_line,s,multiplayer.get_unique_id()]))
				else:
					info_logged.emit(true,false,"[color=yellow][{0}][/color] [color=green][{1}][/color]  [color=cyan]({2}::{3}:{4})[/color] [color=magenta][{6}][/color] {5}".format([time,type,trace_name,trace_function,trace_line,s,multiplayer.get_unique_id()]))
			else:
				if OS.has_feature("web"):
					info_logged.emit(false,false,"[{0}] [{1}]  ({2}::{3}:{4}) {5}".format([time,type,trace_name,trace_function,trace_line,s]))
				else:
					info_logged.emit(true,false,"[color=yellow][{0}][/color] [color=green][{1}][/color]  [color=cyan]({2}::{3}:{4})[/color] {5}".format([time,type,trace_name,trace_function,trace_line,s]))
	else:
		var type := "INFO"
		var time := Time.get_time_string_from_system()
		if  multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer is not OfflineMultiplayerPeer:
			if OS.has_feature("web"):
				info_logged.emit(false,false,"[{0}] [{1}] [{3}] {2}".format([time,type,s,multiplayer.get_unique_id()]))
			else:
				info_logged.emit(true,false,"[color=yellow][{0}][/color] [color=green][{1}][/color] [color=magenta][{3}][/color] {2}".format([time,type,s,multiplayer.get_unique_id()]))
		else:
			if OS.has_feature("web"):
				info_logged.emit(false,false,"[{0}] [{1}] {2}".format([time,type,s,multiplayer.get_unique_id()]))
			else:
				info_logged.emit(true,false,"[color=yellow][{0}][/color] [color=green][{1}][/color] {2}".format([time,type,s,multiplayer.get_unique_id()]))
		
func warn(s) -> void:
	if EngineDebugger.is_active():
		var type := "WARN"
		var time := Time.get_time_string_from_system()
		if get_stack().size() > 1:
			var trace = get_stack()[1]
			var trace_name: String = trace["source"]
			trace_name = trace_name.replace("res://","").split("/")[-1]
			var trace_function: String = trace["function"]
			var trace_line: int = trace["line"]
			if  multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer is not OfflineMultiplayerPeer:
				if OS.has_feature("web"):
					warn_logged.emit(false,false,"[{0}] [{1}]  ({2}::{3}:{4}) [{6}] {5}".format([time,type,trace_name,trace_function,trace_line,s,multiplayer.get_unique_id()]))
				else:
					warn_logged.emit(true,false,"[color=yellow][{0}][/color] [color=orange][{1}][/color]  [color=cyan]({2}::{3}:{4})[/color] [color=magenta][{6}][/color] {5}".format([time,type,trace_name,trace_function,trace_line,s,multiplayer.get_unique_id()]))
			else:
				if OS.has_feature("web"):
					warn_logged.emit(false,false,"[{0}] [{1}]  ({2}::{3}:{4}) {5}".format([time,type,trace_name,trace_function,trace_line,s]))
				else:
					warn_logged.emit(true,false,"[color=yellow][{0}][/color] [color=orange][{1}][/color]  [color=cyan]({2}::{3}:{4})[/color] {5}".format([time,type,trace_name,trace_function,trace_line,s]))
	else:
		var type := "WARN"
		var time := Time.get_time_string_from_system()
		if  multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer is not OfflineMultiplayerPeer:
			if OS.has_feature("web"):
				warn_logged.emit(false,false,"[{0}] [{1}] [{3}] {2}".format([time,type,s,multiplayer.get_unique_id()]))
			else:
				warn_logged.emit(true,false,"[color=yellow][{0}][/color] [color=orange][{1}][/color] [color=magenta][{3}][/color] {2}".format([time,type,s,multiplayer.get_unique_id()]))
		else:
			if OS.has_feature("web"):
				warn_logged.emit(false,false,"[{0}] [{1}] {2}".format([time,type,s]))
			else:
				warn_logged.emit(true,false,"[color=yellow][{0}][/color] [color=orange][{1}][/color] {2}".format([time,type,s]))
	
func error(s) -> void:
	if EngineDebugger.is_active():
		var type := "ERROR"
		var time := Time.get_time_string_from_system()
		if get_stack().size() > 1:
			var trace = get_stack()[1]
			var trace_name: String = trace["source"]
			trace_name = trace_name.replace("res://","").split("/")[-1]
			var trace_function: String = trace["function"]
			var trace_line: int = trace["line"]
			if  multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer is not OfflineMultiplayerPeer:
				if OS.has_feature("web"):
					error_logged.emit(false,false,"[{0}] [{1}]  ({2}::{3}:{4}) [{6}]] {5}".format([time,type,trace_name,trace_function,trace_line,s,multiplayer.get_unique_id()]))
				else:
					error_logged.emit(true,false,"[color=yellow][{0}][/color] [color=red][{1}][/color] [color=cyan]({2}::{3}:{4})[/color] [color=magenta][{6}][/color] {5}".format([time,type,trace_name,trace_function,trace_line,s,multiplayer.get_unique_id()]))
			else:
				if OS.has_feature("web"):
					error_logged.emit(false,false,"[{0}] [{1}]  ({2}::{3}:{4}) {5}".format([time,type,trace_name,trace_function,trace_line,s]))
				else:
					error_logged.emit(true,false,"[color=yellow][{0}][/color] [color=red][{1}][/color] [color=cyan]({2}::{3}:{4})[/color] {5}".format([time,type,trace_name,trace_function,trace_line,s]))
	else:
		var type := "ERROR"
		var time := Time.get_time_string_from_system()
		if  multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer is not OfflineMultiplayerPeer:
			if OS.has_feature("web"):
				error_logged.emit(false,false,"[{0}] [{1}] [{3}] {2}".format([time,type,s,multiplayer.get_unique_id()]))
			else:
				error_logged.emit(true,false,"[color=yellow][{0}][/color] [color=red][{1}][/color] [color=magenta][{3}][/color] {2}".format([time,type,s,multiplayer.get_unique_id()]))
		else:
			if OS.has_feature("web"):
				error_logged.emit(false,false,"[{0}] [{1}] {2}".format([time,type,s]))
			else:
				error_logged.emit(true,false,"[color=yellow][{0}][/color] [color=red][{1}][/color] {2}".format([time,type,s]))

func log_to_stdout(color: bool, raw:bool, s: String):
	if raw:
		printraw(s)
		return
	if color:
		print_rich(s)
	else:
		print(s)
