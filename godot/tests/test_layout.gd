extends SceneTree
var failures: Array = []
func _initialize(): call_deferred("run")
func check_screen(scene):
	var view = scene.get_viewport_rect()
	for node in scene.body.get_children():
		if node.get_global_rect().end.y > view.end.y + 1:
			failures.append("Vertical overflow: %s %s / %s" % [node.name,node.get_global_rect(),view])
	for card in scene.hand_panels:
		if card.get_global_rect().end.x > view.end.x + 1: failures.append("Seven-card horizontal overflow")
func check_labels(node):
	for child in node.get_children():
		if child is Label and not child.text.is_empty() and child.size.y < 1:
			failures.append("Collapsed text: "+child.text)
		check_labels(child)
func run():
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	if not scene.theme.default_font is FontFile:
		failures.append("Expected static font file")
	if scene.theme.default_font.get_string_size("資料答弁",HORIZONTAL_ALIGNMENT_LEFT,-1,24).x < 40:
		failures.append("Missing Japanese glyph advance")
	for viewport_size in [Vector2i(1280,720),Vector2i(1560,720),Vector2i(1536,709)]:
		root.size = viewport_size
		scene.start_battle("admin")
		# Discover representative people from data rather than depend on display names.
		var people: Array = []
		for id in scene.game.data.growth: people.append(id)
		scene.game.b.hand = [people[0],people[1],people[2],people[3],people[4],people[5],people[0]]
		scene.game.b.allies = []
		for id in people.slice(0,3): scene.game.b.allies.append({"id":id,"disabledUntil":0})
		while scene.game.b.plan.size() < 3: scene.game.b.plan.append(scene.game.b.plan[0].duplicate(true))
		scene.render_battle()
		for frame in range(5): await process_frame
		check_screen(scene)
		check_labels(scene.body)
		scene.notice = "長い案内文を表示する場面でも操作ボタンが画面外へ押し出されないことを確認します。".repeat(3)
		scene.render_battle()
		for frame in range(5): await process_frame
		check_screen(scene)
		check_labels(scene.body)
		scene.select_card(0)
		for frame in range(5): await process_frame
		check_screen(scene)
		check_labels(scene.body)
		scene.game.b.outcome = "win"
		scene.render_battle()
		for frame in range(5): await process_frame
		check_screen(scene)
		check_labels(scene.body)
		scene.game.b.outcome = null
		if scene.selected != 0 or not scene.game.history.is_empty(): failures.append("Card selection unexpectedly played a card")
		scene.game.b.hand.append(people[1])
		scene.render_battle()
		for frame in range(5): await process_frame
		# Only the overflow hand row may scroll; footer remains on screen.
		for node in scene.body.get_children():
			if node.get_global_rect().end.y > scene.get_viewport_rect().end.y + 1: failures.append("Overflow hid footer")
		scene.select_card(7)
		scene.discard_card(7)
		if scene.game.b.hand.size() != 7 or scene.selected != -1: failures.append("Overflow selection/discard failed")
	if not failures.is_empty():
		for failure in failures: push_error(failure)
		quit(1)
	else:
		print("PASS: 7 cards, 3 allies, 3 forecasts, selection/detail, overflow discard, footer bounds at three landscape sizes; static Japanese glyph advance and long status/victory (geometry only).")
		quit(0)
