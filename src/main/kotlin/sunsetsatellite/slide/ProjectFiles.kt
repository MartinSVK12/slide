package sunsetsatellite.slide

import godot.annotation.Register
import godot.api.Tree
import godot.annotation.Script
import godot.api.DirAccess
import godot.api.TextureButton
import godot.api.TreeItem
import godot.core.lambdaCallable0
import godot.global.GD
import java.io.IOException
import kotlin.io.path.Path
import kotlin.io.path.absolute

@Script
class ProjectFiles: Tree() {

	// Called when the node enters the scene tree for the first time.
	override fun _ready() {
		reload()
		itemActivated.connect(lambdaCallable0 { onItemActivated() })
		getNode<TextureButton>("%FileSystemRefreshButton").pressed.connect(lambdaCallable0 { onRefreshButtonPressed() })
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	override fun _process(delta: Double) {

	}

	fun reload(){
		clear()
		val path = Path(IDE().projectPath)
		val root = createItem(null)!!
		root.setText(0, path.fileName.toString())
		root.setIconMaxWidth(0,16)
		root.setMetadata(0, path.absolute().toString())
		root.setIcon(0,GD.load("uid://b8cbna6eg2c7q"))
		root.setSelectable(0, false)
		traverseFileSystem(IDE().projectPath, root)
	}

	fun traverseFileSystem(path: String, d: TreeItem) {
		try {
			val dirs = DirAccess.getDirectoriesAt(path)
			val files = DirAccess.getFilesAt(path)
			dirs.forEach {
				val dir = createItem(d)!!
				dir.setText(0, it)
				dir.setIconMaxWidth(0,16)
				dir.setMetadata(0, it)
				dir.setIcon(0,GD.load("uid://b8cbna6eg2c7q"))
				dir.setSelectable(0, false)
				traverseFileSystem(path+"/$it", dir)
			}
			files.forEach {
				val file = createItem(d)!!
				file.setText(0, it)
				file.setIconMaxWidth(0,16)
				file.setMetadata(0, path+"/$it")
				if(it.endsWith(".sl")) {
					file.setIcon(0,GD.load("uid://bddln6gx8xxuu"))
				} else {
					file.setIcon(0,GD.load("uid://bk816age1oe3w"))
				}

				file.setSelectable(0, true)
			}
		} catch (e: IOException) {
			GD.printErr("Error reading project: $e")
		}
	}

	@Register
	fun onRefreshButtonPressed() {
		reload()
	}

	@Register
	fun onItemActivated() {
		val selected = getSelected() ?: return
		val path = selected.getMetadata(0) as String
		IDE().openFile(path)
	}
}
