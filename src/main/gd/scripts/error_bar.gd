extends PanelContainer
class_name ErrorBar

static var current_errors = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var lastTime := %CodeAnalysis.get("last_analysis_time") as int
	var currentTime := Time.get_ticks_msec()
	if lastTime+10000 < currentTime and get_tree().current_scene.current_file != "":
		show()
		%"ProblemsFound/../../NoProblems".visible = false
		$HBox/ErrorLine.set_text("Code analysis unresponsive.")
		$HBox/ErrorCount.set_text("[{0} errors]".format([1]))
		pass
	pass


func _on_code_analysis_completed(errors: Array, tokens: Array) -> void:
	current_errors = errors
	var s = (%ScriptTabs.get_current_tab_control() as ScriptEdit)
	if errors.is_empty():
		for i in s.get_line_count():
			if s.get_line_background_color(i).r == 0.75:
				s.set_line_background_color(i,Color(0,0,0,0))
		hide()
		%"ProblemsFound/../../NoProblems".visible = true
	else:
		show()
		%"ProblemsFound/../../NoProblems".visible = false
		$HBox/ErrorLine.set_text(errors[0])
		$HBox/ErrorCount.set_text("[{0} errors]".format([errors.size()]))
		for line in extract_line_numbers(errors):
			s.set_line_background_color(line-1,Color(0.75,0,0,0.25))
		
func extract_line_numbers(errors: Array) -> Array[int]:
	var arr: Array[int] = []
	var r = RegEx.create_from_string(r',\sline\s[0-9]+\]')
	for e in errors:
		for m in r.search_all(e):
			arr.append(int(m.get_string()))
	return arr
