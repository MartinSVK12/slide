package sunsetsatellite.slide

import godot.api.MenuButton
import godot.annotation.Script
import godot.api.FileDialog
import godot.core.lambdaCallable1

@Script
class FileButton: MenuButton() {
    // Called when the node enters the scene tree for the first time.
    override fun _ready() {
        getPopup()!!.idPressed.connect(lambdaCallable1 {
			index -> when(index) {
		        0L -> {
			        val dialog = getNode<FileDialog>("%OpenFolderDialog")
			        dialog.dirSelected.connect(lambdaCallable1 { path ->
						IDE().projectPath = path
			        })
			        dialog.popupFileDialog()
		        }
	        }
        })
    }

    // Called every frame. 'delta' is the elapsed time since the previous frame.
    override fun _process(delta: Double) {
        
    }
}
