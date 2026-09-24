package sunsetsatellite.slide

import godot.annotation.Dir
import godot.annotation.Export
import godot.annotation.Register
import godot.annotation.Script
import godot.api.Engine
import godot.api.InputEvent
import godot.api.InputEventKey
import godot.api.Label
import godot.api.LineEdit
import godot.api.Node
import godot.api.Panel
import godot.api.Time
import godot.core.Key
import godot.core.Vector2i

@Script
class IDE: Panel() {

	@Export @Dir(global = true)
	var projectPath: String = ""
		set(value) {
			field = value
			if (isInsideTree()) {
				getNode<ProjectFiles>("%ProjectFiles").reload()
			}
		}

	var focusedFile: String = ""
	var focusedEditor: SunliteCodeEdit? = null
	var lastShiftPress: Long = 0
	var shiftBlock: Boolean = false
	var lastCtrlPress: Long = 0
	var ctrlBlock: Boolean = false

	var settings: MutableMap<String, Setting> = mutableMapOf()

	var currentThread: Thread? = null

	// Called when the node enters the scene tree for the first time.
	override fun _ready() {
		settings["advancedHighlighting"] = Setting("Use advanced syntax highlighting",true)
	}

	inner class Setting(val name: String, var value: Any, var onChange: (String, Any)->Unit = {id, value -> settings[id]?.value = value})

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	override fun _process(delta: Double) {
		getNode<Label>("%IdeInfo").text = "${focusedFile.replace("\\","/").replace(projectPath, "")} | Project: ${projectPath} | FPS ${Engine.getFramesPerSecond()} | Display: $size"
	}

	@Register
	fun hasFocusedFile(): Boolean {
		return focusedFile.isNotEmpty() && projectPath.isNotEmpty() && focusedEditor != null
	}

	override fun _input(event: InputEvent) {
		if(event is InputEventKey){
			if (event.physicalKeycode == Key.SHIFT && event.pressed) {
				val time = Time.getTicksMsec()
				if(time - lastShiftPress < 1000 && !shiftBlock) {
					val node = getNode<FindAnything>("%FindAnything")
					node.popupCentered(Vector2i(600,400))
					node.getNode<LineEdit>("VBox/SearchLine").grabFocus()
				}
				shiftBlock = true
				lastShiftPress = time
			}
			if (event.physicalKeycode == Key.SHIFT && !event.pressed) {
				shiftBlock = false
			}

			if (event.physicalKeycode == Key.CTRL && event.pressed) {
				val time = Time.getTicksMsec()
				if(time - lastCtrlPress < 1000 && !ctrlBlock) {
					val node = getNode<Settings>("%Settings")
					node.popupCentered(Vector2i(600,400))
					node.getNode<LineEdit>("VBox/SearchLine").grabFocus()
					node.reload("")
				}
				ctrlBlock = true
				lastCtrlPress = time
			}
			if (event.physicalKeycode == Key.CTRL && !event.pressed) {
				ctrlBlock = false
			}
		}
	}

	@Register
	fun openFile(path: String): SunliteCodeEdit {
		return getNode<ScriptContainer>("%ScriptContainer").loadFile(path)
	}
}

fun <T> Node.getNode(path: String): T {
	return getNode(path) as T
}

fun Node.IDE(): IDE {
	return getNode<IDE>("/root/IDE")
}

fun Node.analysis(): CodeAnalysis {
	return getNode<CodeAnalysis>("%CodeAnalysis")
}

fun Node.debugger(): Debugger {
	return getNode<Debugger>("%Debugger")
}
