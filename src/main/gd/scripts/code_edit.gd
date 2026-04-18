extends CodeEdit
class_name ScriptEdit

var keywords := ["and", "class", "else", "false", "for", "func", "init", "if", "nil", "or", "return", 
"super", "this", "true", "var", "val", "while", "break", "continue", "static", "native", "interface", 
"is", "isnt", "import", "as", "extends", "implements", "try", "catch", "throw", "in", "foreach", 
"operator", "override"]

var type_keywords := ["Any", "String", "Byte", "Short", "Int", "Long", "Float", "Double", "Boolean", "Function", "Class", "Nil", "Array", "Table", "Generic"] ##"Number", "Generic"
var control_keywords := ["if","else","while","for","return","and","or","break","continue","is","isnt","as","in","foreach", "match"]

@export var file: String = ""

@export var keyword_color: Color = Color("ff697d")
@export var type_keyword_color: Color = Color.DARK_ORANGE
@export var control_keyword_color: Color = Color("f788c6")
@export var comment_color: Color = Color.WEB_GRAY
@export var string_color: Color = Color("e3d23d")

func _ready() -> void:
	text = FileAccess.get_file_as_string(file)
	var s: CodeHighlighter = (syntax_highlighter as CodeHighlighter)
	s.clear_color_regions()
	s.clear_keyword_colors()
	s.clear_member_keyword_colors()
	for keyword in keywords:
		s.add_keyword_color(keyword, keyword_color)
	for keyword in type_keywords:
		s.add_keyword_color(keyword, type_keyword_color)
	for keyword in control_keywords:
		s.add_keyword_color(keyword, control_keyword_color)
	s.add_color_region("//","",comment_color,true)
	s.add_color_region("@","",type_keyword_color,true)
	s.add_color_region("\"","\"",string_color)
	#$"./Highlighter".update_cache()
	#symbol_hovered.connect((get_tree().current_scene.get_node("CodeAnalysis") as CodeAnalysis)._on_symbol_hovered, CONNECT_REFERENCE_COUNTED)
	pass

func _on_breakpoint_toggled(line: int) -> void:
	pass
	#print("breakpoint toggled at "+str(line))

func _on_code_completion_requested() -> void:
	var id: int = add_caret(get_caret_line(),get_caret_column()-1)
	var word: String = get_word_under_caret(id)
	var word2 = get_word_under_caret()
	if id != 0 and id != -1:
		remove_caret(id)
	var line = get_line(get_caret_line())
	var chars = line.split("")
	var char = chars[min(get_caret_column(),chars.size()-1)]
	if char == '.':
		get_tree().current_scene.get_node("%CodeAnalysis")._on_member_completion_requested(word, get_caret_line(), get_caret_column(), self)
		update_code_completion_options(true)
		return
	if word == word2:
		update_code_completion_options(true)
		return
	if word.is_empty():
		update_code_completion_options(true)
		return
	get_tree().current_scene.get_node("%CodeAnalysis")._on_code_completion_requested(word, get_caret_line(), get_caret_column(), self)
	for keyword: String in control_keywords:
		if keyword.begins_with(word):
			add_code_completion_option(CodeEdit.KIND_CONSTANT,keyword,keyword.replace(word,""),control_keyword_color)
	for keyword: String in type_keywords:
		if keyword.begins_with(word):
			add_code_completion_option(CodeEdit.KIND_CONSTANT,keyword,keyword.replace(word,""),type_keyword_color)
	for keyword: String in keywords:
		if control_keywords.has(keyword): continue
		if keyword.begins_with(word):
			add_code_completion_option(CodeEdit.KIND_CONSTANT,keyword,keyword.replace(word,""),keyword_color)
	update_code_completion_options(true)

func _filter_code_completion_candidates(candidates: Array[Dictionary]) -> Array[Dictionary]:
	return candidates
	
func _confirm_code_completion(replace: bool) -> void:
	var option: Dictionary = get_code_completion_option(get_code_completion_selected_index())
	if option.is_empty(): return
	var text_to_add = option.insert_text
	update_code_completion_options(true)
	insert_text_at_caret(text_to_add)

func _on_symbol_hovered(symbol: String, line: int, column: int) -> void:
	if(!is_valid_symbol(symbol)): return
	if(get_line(line).begins_with("//")): return
	var type: String = (get_tree().current_scene.get_node("CodeAnalysis") as CodeAnalysis)._on_symbol_hovered(symbol, line, column)
	#print(type)
	%TypePopup.show()
	%TypePopup.global_position = get_global_mouse_position() - Vector2(0,42)
	%TypePopup.text = type
	%TypePopup.size = Vector2.ZERO
	#set_code_hint_draw_below(false)
	#set_code_hint(type)
	#request_code_completion(true)
	#add_code_completion_option(CodeCompletionKind.KIND_PLAIN_TEXT, type, "")
	#update_code_completion_options(true)

func _on_symbol_lookup(symbol: String, line: int, column: int) -> void:
	pass
	#print("symbol lookup: {0} at {1}:{2}".format([symbol,line,column]))

func _on_symbol_validate(symbol: String) -> void:
	set_symbol_lookup_word_as_valid(is_valid_symbol(symbol))
	
func is_valid_symbol(symbol: String) -> bool:
	if(keywords.has(symbol)): return false
	return true
	
func _input(event: InputEvent) -> void:
	#if event is InputEventKey:
		
	if Input.is_action_just_pressed("save"):
		save()

func save():
	var f = FileAccess.open(file,FileAccess.WRITE)
	if f == null: return
	f.store_string(text)
	f.close()
	get_tree().get_root().set_input_as_handled()


func _on_caret_changed() -> void:
	%TypePopup.hide()


func _on_lines_edited_from(from_line: int, to_line: int) -> void:
	if from_line < to_line or from_line == to_line:
		request_code_completion(true)
	pass
	#if to_line < from_line:
	#if to_line < from_line:
		#update_code_completion_options(false)
		#cancel_code_completion()
		#return
	#print("lines edited: from: ", str(from_line), " to: ", str(to_line))
	#print(get_text_for_code_completion())
