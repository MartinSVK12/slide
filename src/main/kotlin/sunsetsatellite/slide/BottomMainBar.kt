package sunsetsatellite.slide

import godot.annotation.Script
import godot.api.Control
import godot.api.HSplitContainer

@Script
class BottomMainBar: HSplitContainer() {

    // Called when the node enters the scene tree for the first time.
    override fun _ready() {
        
    }

    // Called every frame. 'delta' is the elapsed time since the previous frame.
    override fun _process(delta: Double) {
	    if (getChildren().none { it is Control && it.visible }) {
		    hide()
	    } else {
			show()
	    }
    }
}
