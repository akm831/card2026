extends SceneTree
const Mobile = preload("res://scripts/mobile_ui.gd")
var failures: Array = []
func _initialize(): call_deferred("run")
func expect(value: bool, message: String):
	if not value: failures.append(message)
func frames():
	for index in range(6): await process_frame
func run():
	var scene = load("res://main.tscn").instantiate()
	root.size = Vector2i(1280,720)
	root.add_child(scene)
	await frames()
	var settings_before = {"bgm":scene.bgm_volume,"se":scene.se_volume,"wide":scene.wide_margin,"fx":scene.fx_enabled}
	var view = Rect2(0,0,1280,720)
	# Screen-to-canvas includes window translation exactly once.
	var inverse = Transform2D(Vector2(0.5,0),Vector2(0,0.5),Vector2(-50,-100))
	var converted = Mobile.safe_canvas(view,inverse,Vector2.ZERO,Rect2(100,200,2560,1440),[],16)
	expect(converted == Rect2(16,16,1248,688),"Scaled/translated safe area")
	for hole in [Rect2(0,280,44,100),Rect2(1236,280,44,100)]:
		scene.simulated_safe = Rect2(0,0,1280,696)
		scene.simulated_cutouts = [hole]
		for wide in [false,true]:
			scene.wide_margin = wide
			scene.apply_safe_area()
			scene.start_battle("admin")
			scene.game.b.allies = [{"id":"official","disabledUntil":0},{"id":"leader","disabledUntil":0},{"id":"reporter","disabledUntil":0}]
			while scene.game.b.plan.size() < 3: scene.game.b.plan.append(scene.game.b.plan[0].duplicate(true))
			for count in [1,2,4,7,8]:
				scene.game.b.hand = []
				for index in range(count): scene.game.b.hand.append("delay" if index%2 == 0 else "official")
				scene.render_battle()
				await frames()
				for node in scene.body.get_children():
					expect(scene.safe_rect.encloses(node.get_global_rect().grow(-0.5)),"Safe bounds %s (%s wide=%s count=%d)" % [node.name,node.get_global_rect(),wide,count])
				for card in scene.hand_panels:
					expect(card.size.is_equal_approx(scene.card_size),"Fixed card size")
					var art = card.get_child(0).get_child(1)
					expect(art.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED,"Uncropped art")
				if count < 8:
					var first = scene.hand_panels[0].get_global_rect()
					var last = scene.hand_panels[-1].get_global_rect()
					expect(absf((first.position.x+last.end.x)/2-scene.safe_rect.get_center().x)<2,"Centered hand")
				else:
					var hand_scroll = scene.body.find_child("HandOverflow",true,false)
					hand_scroll.scroll_horizontal = 10000
					await frames()
					expect(scene.hand_panels[-1].get_global_rect().end.x <= scene.safe_rect.end.x+1,"Overflow last card reachable")
			scene.game.b.log = []
			for index in range(100): scene.game.b.log.append("ログ %d：カードの使用と予告の変化を記録。" % index)
			scene.show_log()
			await frames()
			expect(scene.safe_rect.encloses(scene.popup_layer.get_node("PopupPanel").get_global_rect()),"Safe popup %s / %s" % [scene.popup_layer.get_node("PopupPanel").get_global_rect(),scene.safe_rect])
			var scroll = scene.popup_layer.find_child("TouchScroll",true,false)
			var touch = InputEventScreenTouch.new()
			touch.index = 0; touch.pressed = true; touch.position = scroll.get_global_rect().get_center()
			root.push_input(touch)
			await process_frame
			var drag = InputEventScreenDrag.new()
			drag.index = 0; drag.position = touch.position+Vector2(0,-80); drag.relative = Vector2(0,-80)
			root.push_input(drag)
			await process_frame
			expect(scroll.scroll_vertical > 0,"Viewport touch drags log")
			touch.pressed = false; touch.position = drag.position; root.push_input(touch)
			scroll.scroll_vertical = 100000
			await frames()
			expect(scroll.scroll_vertical > 500,"Long log reaches final entries")
			scene.close_popup()
			await frames()
	# Settings don't alter engine state; volume zero, pause/resume and reduced FX work.
	scene.show_settings()
	await frames()
	var sliders = [scene.popup_layer.find_child("bgm_volume",true,false),scene.popup_layer.find_child("se_volume",true,false)]
	sliders[0].value = 25
	sliders[1].value = 75
	expect(scene.bgm_volume == 25 and scene.se_volume == 75,"Independent volume slider callbacks")
	scene.close_popup()
	await frames()
	var engine_before = JSON.stringify(scene.game.b)
	scene.bgm_volume = 0; scene.se_volume = 0; scene.fx_enabled = false
	scene.apply_audio_settings()
	expect(scene.bgm.stream_paused,"BGM mute")
	for p in scene.se_players: p.stop()
	scene.play_sound("hit")
	expect(not scene.se_players.any(func(p): return p.playing),"SE mute")
	scene.save_settings(); scene.bgm_volume = 100; scene.se_volume = 100; scene.fx_enabled = true; scene.load_settings()
	expect(scene.bgm_volume == 0 and scene.se_volume == 0 and not scene.fx_enabled,"Settings persistence")
	scene.bgm_volume = 40; scene.apply_audio_settings()
	scene._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	expect(scene.bgm.stream_paused,"Background pauses music")
	scene._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	expect(not scene.bgm.stream_paused,"Resume music")
	expect(JSON.stringify(scene.game.b) == engine_before,"Settings preserve battle state")
	expect(scene.bgm.stream.loop and scene.bgm.stream.get_length()>63,"64-second looping BGM")
	for sound in ["select","paper","confirm","hit","block","intervene","growth","victory"]:
		var stream = load("res://audio/"+sound+".wav")
		expect(stream != null and stream.get_length()>0,"SE resource "+sound)
	scene.bgm_volume = settings_before.bgm; scene.se_volume = settings_before.se
	scene.wide_margin = settings_before.wide; scene.fx_enabled = settings_before.fx; scene.save_settings()
	scene.queue_free(); await frames()
	if failures.is_empty():
		print("PASS: physical safe-area scale/translation, left/right cutouts, bottom inset, wide margins, 1/2/4/7/8 fixed uncropped cards, touch log, modal bounds, audio settings/pause/resources (synthetic input, not physical Android).")
		call_deferred("quit",0)
	else:
		for failure in failures: push_error(failure)
		call_deferred("quit",1)
