package godot

import godot.annotation.RegisterClass
import godot.annotation.RegisterFunction
import godot.api.*
import godot.core.*
import sunsetsatellite.sunlite.lang.Sunlite
import sunsetsatellite.sunlite.lang.Type
import sunsetsatellite.sunlite.vm.CallFrame
import sunsetsatellite.sunlite.vm.SLClass
import sunsetsatellite.sunlite.vm.SLClassInstance

@RegisterClass
class Debugger: Node() {

	var currentBreakpointLine: Int = -1
	var currentBreakpointFile: String? = null
	var currentVM: Sunlite? = null
	var currentBreakpointFrame: CallFrame? = null
	var frames: MutableList<CallFrame> = mutableListOf()

	// Called when the node enters the scene tree for the first time.
	@RegisterFunction
	override fun _ready() {

	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	@RegisterFunction
	override fun _process(delta: Double) {
		val label = getNode("%DebuggerStatusLabel".asNodePath()) as Label
		if(RunScript.currentThread?.isAlive == true && RunScript.currentInterpreter?.uninitialized == false && RunScript.currentInterpreter?.vm?.breakpointHit == false) {
			label.setText("Running...")
			label.labelSettings?.setFontColor(Color("40ff40"))
		} else if(RunScript.currentInterpreter == null) {
			label.setText("No program is running.")
			label.labelSettings?.setFontColor(Color("808080"))
			if(currentVM != null) {
				_on_resume_button_pressed()
			}
		}
	}

	fun breakpointHit(line: Int, file: String?, sunlite: Sunlite) {
		(getNode("%DebuggerButton".asNodePath()) as Button).setPressed(true)
		currentBreakpointLine = line
		currentBreakpointFile = file
		currentBreakpointFrame = sunlite.vm.frameStack.peek()
		currentVM = sunlite
		val tree = this.getNode("%ProjectStructureTree".asNodePath()) as Tree?
		(tree?.get("load_file".asStringName()) as Callable).call(file)
		val tabs = this.getNode("%ScriptTabs".asNodePath()) as TabContainer?
		val scriptTab = tabs?.getCurrentTabControl() as CodeEdit?
		val stackTraces = getNode("%StackTraces".asNodePath()) as VBoxContainer?
		stackTraces?.getChildren()?.forEach {
			it.queueFree()
		}

		frames.addAll(sunlite.vm.frameStack)
		frames.reverse()
		frames.forEachIndexed { index, it ->
			val traceButton = Button()
			traceButton.setText(it.toString())
			traceButton.alignment = HorizontalAlignment.LEFT
			traceButton.setMeta("env_index".asStringName(),index)
			traceButton.addThemeStyleboxOverride("focus".asStringName(), StyleBoxEmpty())
			traceButton.pressed.connect(flags = ConnectFlags.REFERENCE_COUNTED.id.toInt()) {
				val index = (traceButton.getMeta("env_index".asStringName()) as Long).toInt()
				displayEnvValues(frames[index])
			}
			stackTraces?.callDeferred("add_child".asStringName(),traceButton)
		}

		currentBreakpointFrame?.let { displayEnvValues(it) }
		scriptTab?.setLineBackgroundColor(line-1, Color(1, 0, 0, 0.25))
		val statusLabel = getNode("%DebuggerStatusLabel".asNodePath()) as Label
		statusLabel.setText("Breakpoint hit at line $line!")
		statusLabel.labelSettings?.setFontColor(Color("ff4040"))
		(getNode("./VBox/Panel/HBoxContainer/ResumeButton".asNodePath()) as Button).disabled = false
		//(getNode("%Evaluator".asNodePath()) as LineEdit).editable = true
	}

	private fun displayEnvValues(frame: CallFrame){
		val frameStack = getNode("%EnvVars".asNodePath()) as Tree?
		frameStack?.clear()
		val root = frameStack?.createItem(null)
		frame.locals.forEachIndexed { i, it ->
			val stackEntry = root?.createChild()
			stackEntry?.setCollapsed(true)
			val info = frame.closure.function.chunk.debugInfo
			stackEntry?.setText(0,"${info.locals.getOrNull(i)}: ${Type.fromValue(it.value, currentVM!!)} = $it")
			loadValues(stackEntry, it.value)
		}
	}

	private fun shortName(value: Any?): String {
		return value?.javaClass?.simpleName?.replace("SL","")?.replace("Obj","") ?: "Unknown"
	}

	private fun loadValues(parent: TreeItem?, value: Any?){
		when (value) {
			is SLClass -> {
				value.methods.forEach { (t, u) ->
					val method = parent?.createChild()
					method?.setText(0,"$t = ${u.value} (${shortName(u.value)})")
					loadValues(method,u.value)
				}
			}
			is SLClassInstance -> {
				value.fields.forEach { (t, u) ->
					val field = parent?.createChild()
					field?.setText(0,"$t = ${u.value} (${shortName(u.value)})")
					loadValues(field,u.value)
				}
			}
		}

	}

	@RegisterFunction
	fun _on_resume_button_pressed(){
		(getNode("./VBox/Panel/HBoxContainer/ResumeButton".asNodePath()) as Button).disabled = true
		(getNode("%Evaluator".asNodePath()) as LineEdit).editable = false
		val scriptTab = ((this.getNode("%ScriptTabs".asNodePath()) as TabContainer).getCurrentTabControl() as CodeEdit?)
		val stackTraces = getNode("%StackTraces".asNodePath()) as VBoxContainer?
		val envVars = getNode("%EnvVars".asNodePath()) as Tree?
		stackTraces?.getChildren()?.forEach {
			it.queueFree()
		}
		envVars?.clear()
		scriptTab?.setLineBackgroundColor(currentBreakpointLine-1,Color(0,0,0,0))
		currentVM?.vm?.continueExecution = true
		currentBreakpointLine = -1
		currentBreakpointFile = null
		currentBreakpointFrame = null
		currentVM = null
		frames.clear()
	}

	@RegisterFunction
	fun _on_evaluator_text_submitted(new_test: String){
		/*if(currentVM != null){
			val parsed = currentVM?.parse("print($new_test);")
			val function = parsed?.let { currentVM?.compile(it.second) }
			currentVM?.vm?.overrideFunction = function
		}*/
	}

}
