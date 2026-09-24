package sunsetsatellite.slide

import godot.annotation.Register
import godot.api.PopupPanel
import godot.annotation.Script
import godot.api.LineEdit
import godot.api.Tree
import godot.api.TreeItem
import godot.api.VBoxContainer
import godot.core.lambdaCallable0
import godot.core.lambdaCallable1
import godot.core.lambdaCallable4
import godot.global.GD
import java.io.File
import java.io.IOException

@Script
class Settings: PopupPanel() {

	val results by lazy { getNode<Tree>("VBox/Results") }
	val search by lazy { getNode<LineEdit>("VBox/SearchLine") }
	val editor by lazy { getNode<ScriptContainer>("%ScriptContainer") }

    // Called when the node enters the scene tree for the first time.
    override fun _ready() {
        search.textChanged.connect(lambdaCallable1 { text ->
			reload(text)
        })
	    /*results.buttonClicked.connect( lambdaCallable4 { item: TreeItem, column: Long, id: Long, mouseButtonIndex: Long ->
			println("item: $item, column: $column, id: $id, mouseButtonIndex: $mouseButtonIndex")
	    } )*/
	    results.itemEdited.connect(lambdaCallable0 {
		    val name = results.getSelected()?.getMetadata(1) as String
		    results.getSelected()?.isChecked(1)?.let { IDE().settings[name]?.onChange?.invoke(name, it) }
		    IDE().settings[name]?.value?.toString()?.let { results.getSelected()?.setText(1, it) }
	    })
	    reload("")
    }

	@Register
	fun reload(text: String){
		results.clear()
		val root = results.createItem()
		IDE().settings.filter { it.key.contains(text) || text.isEmpty() }.forEach { (name, value) ->
			val result = results.createItem(root)
			result?.setText(0, value.name)
			if(value.value is Boolean){
				result?.setCellMode(1, TreeItem.TreeCellMode.CELL_MODE_CHECK)
				result?.setEditable(1, true)
				result?.setChecked(1, value.value as Boolean)
				result?.setMetadata(1, name)
				result?.setText(1, value.value.toString())
			}
		}
	}

    // Called every frame. 'delta' is the elapsed time since the previous frame.
    override fun _process(delta: Double) {
        
    }
}
