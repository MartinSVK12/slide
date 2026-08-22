package sunsetsatellite.slide

import godot.annotation.Register
import godot.api.TabContainer
import godot.annotation.Script
import godot.api.PackedScene
import godot.api.PopupMenu
import godot.core.asStringName
import godot.core.lambdaCallable1
import godot.core.toGodotName
import godot.global.GD
import kotlin.io.path.Path
import kotlin.io.path.extension

@Script
class ScriptContainer: TabContainer() {

	val packedEditor by lazy { GD.load<PackedScene>("uid://dbrvfvd5lmbpl")!! }

    // Called when the node enters the scene tree for the first time.
    override fun _ready() {
		tabButtonPressed.connect(lambdaCallable1 {
			val child = getChild(it.toInt())!!
			child.queueFree()
			if(IDE().focusedFile == (child as? SunliteCodeEdit)?.path) {
				IDE().focusedFile = ""
			}
		})
    }

    // Called every frame. 'delta' is the elapsed time since the previous frame.
    override fun _process(delta: Double) {
        
    }

	@Register
	fun loadFile(file: String): SunliteCodeEdit {
		getChildren().forEachIndexed { index, it ->
			if(it !is SunliteCodeEdit) return@forEachIndexed
			if(it.path == file) {
				setCurrentTab(index)
				return it
			}
		}
		val path = Path(file)
		val editor = packedEditor.instantiate()!! as SunliteCodeEdit
		editor.path = file
		editor.name = path.fileName.toString().asStringName()
		addChild(editor)
		setTabTitle(editor.getIndex(), path.fileName.toString())
		setTabButtonIcon(editor.getIndex(), GD.load("uid://opdvvnvv3xia"))
		if(path.extension == "sl") setTabIcon(editor.getIndex(), GD.load("uid://bddln6gx8xxuu"))
		else setTabIcon(editor.getIndex(), GD.load("uid://bk816age1oe3w"))
		setCurrentTab(editor.getIndex())
		return editor
	}
}
