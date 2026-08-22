package sunsetsatellite.slide

import godot.api.Button
import godot.annotation.Script
import godot.api.Input
import godot.api.InputEventAction
import godot.api.LineEdit
import godot.api.RichTextLabel
import godot.api.TextureButton
import godot.api.VBoxContainer
import godot.api.VSplitContainer
import godot.core.asStringName
import godot.core.lambdaCallable0
import sunsetsatellite.sunlite.lang.LogEntryReceiver
import sunsetsatellite.sunlite.lang.Sunlite
import java.io.PrintWriter
import java.io.StringWriter
import kotlin.concurrent.thread

@Script
class RunButton: Button(), LogEntryReceiver {

	val stop by lazy { getNode<Button>("%StopButton") }
	val console by lazy { getNode<VBoxContainer>("%Console") }
	val output by lazy { getNode<RichTextLabel>("%ConsoleOutput") }
	val tabs by lazy { getNode<ScriptContainer>("%ScriptContainer") }

    // Called when the node enters the scene tree for the first time.
    override fun _ready() {
		stop.pressed.connect(lambdaCallable0 {
			IDE().currentThread?.stop()
		})
	    getNode<TextureButton>("%ClearConsoleOutputButton").pressed.connect(lambdaCallable0 {
			output.clear()
	    })
    }

    // Called every frame. 'delta' is the elapsed time since the previous frame.
    override fun _process(delta: Double) {
		if(!IDE().hasFocusedFile() || IDE().focusedEditor?.ext != "sl") {
			disabled = true
		} else {
			disabled = false
		}
        if(IDE().currentThread?.isAlive == true) {
			hide()
			stop.show()
        } else {
			show()
			stop.hide()
        }
    }

	override fun _pressed() {
		Input.parseInputEvent(InputEventAction().apply { action = "save".asStringName(); pressed = true })
		val breakpoints: MutableMap<String,IntArray> = mutableMapOf()
		tabs.getChildren().forEach { node ->
			val tab = node as SunliteCodeEdit
			breakpoints[tab.path] = tab.getBreakpointedLines().map { it.inc() }.toIntArray()
		}
		IDE().currentThread = thread(start = false, name = "Sunlite") {
			godot.api.Thread.setThreadSafetyChecksEnabled(false)
			val sl = Sunlite(arrayOf(
				IDE().focusedFile,
				IDE().projectPath,
				getNode<LineEdit>("%VMOptions").text
			))
			sl.logEntryReceivers.add(this@RunButton)
			sl.breakpointListeners.add(debugger())
			sl.breakpoints = breakpoints
			sl.start()
			IDE().currentThread = null
			godot.api.Thread.setThreadSafetyChecksEnabled(true)
		}
		IDE().currentThread?.setUncaughtExceptionHandler { t, e ->
			if(e is ThreadDeath) return@setUncaughtExceptionHandler
			godot.api.Thread.setThreadSafetyChecksEnabled(false)
			err("Exception in thread \"" + t.name + "\"")
			val sw = StringWriter()
			e.printStackTrace(PrintWriter(sw))
			val s = sw.toString()
			err(s)
			godot.api.Thread.setThreadSafetyChecksEnabled(true)
		}
		IDE().currentThread?.start()
		console.show()
		getNode<Button>("%ConsoleButton").buttonPressed = true
		(console.getParent()?.getParent() as? VSplitContainer)?.splitOffset = -300
		output.clear()

	}

	override fun info(message: String) {
		output.appendText(message+"\n")
	}

	override fun warn(message: String) {
		output.appendText("[color=orange]$message[/color]\n")
	}

	override fun err(message: String) {
		output.appendText("[color=red]$message[/color]\n")
	}
}
