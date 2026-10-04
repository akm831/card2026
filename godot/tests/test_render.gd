extends SceneTree
func _initialize(): call_deferred("run")
func run():
	root.size = Vector2i(1280,720)
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.start_battle("admin")
	scene.game.b.hand = ["delay","budgetReview","lobby","answer","official","report","leader"]
	scene.game.b.allies = [{"id":"official","disabledUntil":0},{"id":"leader","disabledUntil":0},{"id":"reporter","disabledUntil":0}]
	while scene.game.b.plan.size() < 3: scene.game.b.plan.append(scene.game.b.plan[0].duplicate(true))
	scene.select_card(0)
	for frame in range(12): await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://../build")
	var screenshot = root.get_texture().get_image()
	if screenshot.is_empty(): push_error("No rendered pixels"); quit(1); return
	screenshot.save_png("res://../build/godot_ui05_selected.png")
	# Essential text must have positive layout height, not just exist as a node.
	for label in [scene.player_label,scene.enemy_label]:
		if label.size.y < 24: push_error("Collapsed HP label"); quit(1); return
	scene.activate_selected()
	for frame in range(12): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../build/godot_ui05_targeting.png")
	scene.targeting = false
	scene.selected = -1
	scene.game.b.enemyHP = 0
	scene.game.b.outcome = "win"
	scene.render_battle()
	for frame in range(12): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../build/godot_ui05_victory.png")
	# Fewer cards leave empty space, and the same artwork remains entirely visible.
	for count in [1,2,4]:
		scene.game.b.outcome = null
		scene.game.b.hand = ["delay","budgetReview","official","report"].slice(0,count)
		scene.render_battle()
		for frame in range(12): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../build/godot_ui05_hand%d.png" % count)
	scene.simulated_safe = Rect2(0,0,1280,696)
	scene.simulated_cutouts = [Rect2(0,280,44,100)]
	scene.wide_margin = true
	scene.apply_safe_area()
	scene.render_battle()
	for frame in range(12): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../build/godot_ui05_safe.png")
	scene.show_settings()
	for frame in range(12): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../build/godot_ui05_settings.png")
	scene.close_popup()
	scene.queue_free()
	for frame in range(6): await process_frame
	print("PASS: OpenGL rendered selected, targeting and victory screenshots (desktop, not Android).")
	quit()
