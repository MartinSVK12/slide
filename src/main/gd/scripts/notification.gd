extends PanelContainer

var message: String
var color: Color
var timeout: int

func _ready():
	var s = StyleBoxFlat.new()
	s.bg_color = Color(color, 0.376)
	add_theme_stylebox_override("panel",s)
	$HBox/MessageLine.set_text(message)
	$Timer.start(timeout)

func _on_timer_timeout() -> void:
	queue_free()
