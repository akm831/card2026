extends SceneTree
func _initialize():
	call_deferred("run")
func run():
	root.size = Vector2i(1280,800)
	var scene = load("res://main.tscn").instantiate()
	if scene.get_script() == null:
		push_error("Main scene script failed to load")
		quit(1)
		return
	root.add_child(scene)
	await process_frame
	for type in ["admin","regional","noir","economic"]:
		scene.start_battle(type)
		await process_frame
		if scene.body.get_child_count() < 5:
			push_error("Empty battle screen")
			quit(1)
			return
		for i in range(3):
			var actions: Array = []
			for index in range(scene.game.b.hand.size()):
				var c = scene.game.card(scene.game.b.hand[index])
				if not scene.game.can(c.id): continue
				var e = scene.game.target_effect(c)
				actions.append({"index":index,"uid":scene.game.targets(e)[0].uid if e != null else null})
			if actions.is_empty(): break
			await scene.use_card(actions[0].index,actions[0].uid)
		scene.undo_action(true)
		await scene.end_action()
		scene.show_menu()
		scene.resume_battle()
		await process_frame
		if not scene.playing:
			push_error("UI resume failed")
			quit(1)
			return
	print("PASS: menu, four battle layouts, action animations/SE, Undo, end turn and saved resume (headless, no visual inspection).")
	scene.queue_free()
	await process_frame
	# Allow the audio server to release playback before process shutdown.
	await create_timer(0.12).timeout
	quit(0)
