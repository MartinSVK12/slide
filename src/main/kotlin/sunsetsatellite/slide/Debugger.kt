package sunsetsatellite.slide

import godot.api.VBoxContainer
import godot.annotation.Script
import godot.api.Button
import godot.api.Label
import godot.api.Tree
import godot.api.TreeItem
import godot.core.Color
import godot.core.Color.Companion.invoke
import godot.core.lambdaCallable0
import sunsetsatellite.sunlite.lang.BreakpointListener
import sunsetsatellite.sunlite.lang.Sunlite
import sunsetsatellite.sunlite.lang.Type
import sunsetsatellite.sunlite.vm.AnySLValue
import sunsetsatellite.sunlite.vm.CallFrame
import sunsetsatellite.sunlite.vm.SLClassInstanceObj
import sunsetsatellite.sunlite.vm.SLClassObj
import sunsetsatellite.sunlite.vm.VM

@Script
class Debugger: VBoxContainer(), BreakpointListener {

	enum class State {
		RUNNING,
		IDLE,
		BREAKPOINT
	}

	var state: State = State.IDLE

	var line: Int = -1
	var file: String? = null
	var vm: VM? = null
	val frames: MutableList<CallFrame> = mutableListOf()

	val stateLabel: Label by lazy { getNode<Label>("TopBar/ProgramState") }
	val continueButton: Button by lazy { getNode<Button>("TopBar/ContinueButton") }
	val frameTree: Tree by lazy { getNode<Tree>("HBox/VBox/StackFrames") }
	val dataTree: Tree by lazy { getNode<Tree>("HBox/VBox2/FrameData") }

    // Called when the node enters the scene tree for the first time.
    override fun _ready() {
        continueButton.pressed.connect(lambdaCallable0 {
			vm?.continueExecution = true
	        file?.let {
		        val editor = IDE().openFile(file!!)
		        editor.setLineBackgroundColor(line-1, Color(0,0,0,0))
	        }
	        changeState(State.RUNNING)
	        frames.clear()
	        frameTree.clear()
	        dataTree.clear()
	        line = -1
	        file = null
	        vm = null
        })
	    frameTree.itemActivated.connect(lambdaCallable0 {
			frameTree.getSelected()?.getMetadata(0)?.let {
				loadData(frames[(it as Long).toInt()])
			}
	    })
    }

    // Called every frame. 'delta' is the elapsed time since the previous frame.
    override fun _process(delta: Double) {
		if(state == State.IDLE && IDE().currentThread?.isAlive == true){
			changeState(State.RUNNING)
		} else if((state == State.RUNNING || state == State.BREAKPOINT) && (IDE().currentThread == null || IDE().currentThread?.isAlive == false)) {
			changeState(State.IDLE)
		}
    }

	fun changeState(state: State) {
		this.state = state
		when(state){
			State.RUNNING -> {
				stateLabel.setText("Running...")
				stateLabel.labelSettings?.setFontColor(Color("40ff40"))
				continueButton.disabled = true
			}
			State.IDLE -> {
				file?.let {
					val editor = IDE().openFile(file!!)
					editor.setLineBackgroundColor(line-1, Color(0,0,0,0))
				}
				frames.clear()
				frameTree.clear()
				dataTree.clear()
				line = -1
				file = null
				vm = null
				stateLabel.setText("No program is running.")
				stateLabel.labelSettings?.setFontColor(Color("808080"))
				continueButton.disabled = true
			}
			State.BREAKPOINT -> {
				stateLabel.setText("Breakpoint hit at line $line!")
				stateLabel.labelSettings?.setFontColor(Color("ff4040"))
				continueButton.disabled = false
			}
		}
	}

	override fun breakpointHit(line: Int, file: String?, vm: VM) {
		this.line = line
		this.file = file
		this.vm = vm
		file?.let {
			val editor = IDE().openFile(file)
			editor.setLineBackgroundColor(line-1, Color(0.80,0,0,0.3))
		}
		frames.clear()
		frameTree.clear()
		dataTree.clear()
		val frameRoot = frameTree.createItem()
		val dataRoot = dataTree.createItem()
		frames.addAll(vm.frameStack.reversed())
		frames.forEachIndexed { index, it ->
			val frame = frameTree.createItem(frameRoot)!!
			frame.setText(0, it.toString())
			frame.setMetadata(0, index)
		}
		changeState(State.BREAKPOINT)
		show()
	}

	fun loadData(frame: CallFrame){
		dataTree.clear()
		val r = dataTree.createItem()
		createItem("PC: ${frame.pc}", r)
		val stack = createItem("Stack", r)
		val locals = createItem("Locals", r)

		frame.stack.forEach {
			createItem("$it (${it.javaClass.simpleName.replace("SL","")})", stack)
		}
		frame.locals.forEachIndexed { index, it ->
			val info = frame.closure.function.chunk.debugInfo
			loadValues(frame,info.locals.getOrNull(index) ?: "<local $index>", it, locals)
		}
	}

	fun loadValues(frame: CallFrame, name: String, it: AnySLValue, parent: TreeItem) {
		val item = createItem(
			"$name: ${Type.fromValue(it.value, vm!!.sunlite)} = $it", parent
		)
		when(it){
			is SLClassObj -> {
				it.value.staticFields.forEach { (name, field) ->
					loadValues(frame, name, field.value, item)
				}
			}
			is SLClassInstanceObj -> {
				it.value.fields.forEach { (name, field) ->
					loadValues(frame, name, field.value, item)
				}
				val statics = createItem("<static>", item)
				it.value.clazz.staticFields.forEach { (name, field) ->
					loadValues(frame, name, field.value, statics)
				}
			}
		}
	}

	fun createItem(text: String, root: TreeItem? = null): TreeItem {
		val item = dataTree.createItem(root)!!
		item.setText(0,text)
		item.setSelectable(0, false)
		return item
	}
}
