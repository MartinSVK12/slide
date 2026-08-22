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

	var currentThread: Thread? = null

	// Called when the node enters the scene tree for the first time.
	override fun _ready() {

	}

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
				if(time - lastShiftPress < 1000) {
					val node = getNode<FindAnything>("%FindAnything")
					node.popupCentered(Vector2i(600,400))
					node.getNode<LineEdit>("VBox/SearchLine").grabFocus()
				}
				lastShiftPress = time
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