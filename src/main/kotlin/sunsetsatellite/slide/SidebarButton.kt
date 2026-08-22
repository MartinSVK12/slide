package sunsetsatellite.slide

import godot.annotation.Export
import godot.api.Button
import godot.annotation.Script
import godot.api.Control
import godot.api.Node

@Script
class SidebarButton: Button() {
	@Export
    var screen: Control? = null

	override fun _toggled(toggledOn: Boolean) {
		screen?.visible = toggledOn
	}
}
