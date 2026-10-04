extends ScrollContainer
var touch_index: int = -1
var last_y: float = 0
func _gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_index = event.index
			last_y = event.position.y
		elif event.index == touch_index: touch_index = -1
		accept_event()
	elif event is InputEventScreenDrag and event.index == touch_index:
		scroll_vertical = maxi(0,scroll_vertical-int(event.relative.y))
		last_y = event.position.y
		accept_event()
