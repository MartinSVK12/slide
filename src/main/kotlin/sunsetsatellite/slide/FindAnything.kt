package sunsetsatellite.slide

import godot.api.PopupPanel
import godot.annotation.Script
import godot.api.LineEdit
import godot.api.Tree
import godot.api.VBoxContainer
import godot.core.lambdaCallable0
import godot.core.lambdaCallable1
import godot.global.GD
import java.io.File
import java.io.IOException

@Script
class FindAnything: PopupPanel() {

	val results by lazy { getNode<Tree>("VBox/Results") }
	val search by lazy { getNode<LineEdit>("VBox/SearchLine") }
	val editor by lazy { getNode<ScriptContainer>("%ScriptContainer") }

    // Called when the node enters the scene tree for the first time.
    override fun _ready() {
        search.textChanged.connect(lambdaCallable1 { text ->
			results.clear()
	        val root = results.createItem()
	        try {
		        val r = File(IDE().projectPath).walkTopDown().filter { it.isFile && it.name.contains(search.text) }
		        r.forEachIndexed { index, it ->
					val result = results.createItem(root)
					result?.setText(0, it.name)
			        result?.setMetadata(0, it.absolutePath)
			        result?.setIconMaxWidth(0,16)
			        if(it.extension == "sl"){
						result?.setIcon(0, GD.load("uid://bddln6gx8xxuu"))
			        } else {
				        result?.setIcon(0,GD.load("uid://bk816age1oe3w"))
			        }
			        if(index == 0) result?.select(0)
				}
	        } catch (e: IOException) {}
        })
	    results.itemActivated.connect(lambdaCallable0 {
			IDE().openFile(results.getSelected()?.getMetadata(0) as String)
		    hide()
	    })
    }

    // Called every frame. 'delta' is the elapsed time since the previous frame.
    override fun _process(delta: Double) {
        
    }
}
