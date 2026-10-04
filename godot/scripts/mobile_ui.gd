extends RefCounted
# Physical coordinates (including cutouts) -> root canvas coordinates.
static func safe_canvas(view: Rect2, screen_to_canvas: Transform2D, window_origin: Vector2, physical_safe: Rect2, cutouts: Array, padding: float) -> Rect2:
	var safe = view
	if physical_safe.size.x > 0 and physical_safe.size.y > 0:
		var a = screen_to_canvas * (physical_safe.position-window_origin)
		var z = screen_to_canvas * (physical_safe.end-window_origin)
		safe = view.intersection(Rect2(a,z-a))
	if safe.size.x < 100 or safe.size.y < 100: safe = view
	for hole in cutouts:
		var a = screen_to_canvas * (Vector2(hole.position)-window_origin)
		var z = screen_to_canvas * (Vector2(hole.end)-window_origin)
		var h = view.intersection(Rect2(a,z-a))
		if h.size.x <= 0 or h.size.y <= 0 or not safe.intersects(h): continue
		var distances = [h.position.x-view.position.x,view.end.x-h.end.x,h.position.y-view.position.y,view.end.y-h.end.y]
		var edge = distances.find(distances.min())
		if edge == 0:
			var end = safe.end
			safe.position.x = maxf(safe.position.x,h.end.x)
			safe.size.x = end.x-safe.position.x
		elif edge == 1: safe.size.x = minf(safe.end.x,h.position.x)-safe.position.x
		elif edge == 2:
			var end = safe.end
			safe.position.y = maxf(safe.position.y,h.end.y)
			safe.size.y = end.y-safe.position.y
		else: safe.size.y = minf(safe.end.y,h.position.y)-safe.position.y
	return safe.grow(-padding)
