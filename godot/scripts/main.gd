extends Control
const Core = preload("res://scripts/battle_engine.gd")
const MobileUI = preload("res://scripts/mobile_ui.gd")
const TouchLog = preload("res://scripts/touch_log.gd")
const SETTINGS_PATH = "user://ui_settings.json"
const SAVE_PATH = "user://battle_v1.json"
const GOLD = Color("e4b760")
const PAPER = Color("e9dfc5")
const INK = Color("15242e")
var game = Core.new()
var body: VBoxContainer
var player_label: Label
var enemy_label: Label
var player_bar: ProgressBar
var enemy_bar: ProgressBar
var selected: int = -1
var busy: bool = false
var muted: bool = false
var playing: bool = false
var audio: AudioStreamPlayer
var fonts: Font
var soft_choice: String = "finance"
var notice: String = ""
var hand_panels: Array = []
var forecast_nodes: Dictionary = {}
var person_nodes: Dictionary = {}
var targeting: bool = false
var detail_box: VBoxContainer
var margin: MarginContainer
var safe_rect: Rect2
var simulated_safe: Rect2 = Rect2()
var simulated_cutouts: Array = []
var wide_margin: bool = false
var fx_enabled: bool = true
var bgm_volume: float = 40
var se_volume: float = 65
var bgm: AudioStreamPlayer
var se_players: Array = []
var popup_layer: Control
var card_size: Vector2 = Vector2(156,156)
var settings_loaded: bool = false
var resize_pending: bool = false
const AFF_COLORS = {"admin":Color("328cd8"),"politics":Color("ca5460"),"press":Color("8f72cf"),"business":Color("b18a36"),"community":Color("39876b"),"noir":Color("746782")}

func _ready():
	fonts = load("res://fonts/NotoSansJP-Bold.ttf") if ResourceLoader.exists("res://fonts/NotoSansJP-Bold.ttf") else SystemFont.new()
	var theme = Theme.new()
	theme.default_font = fonts
	theme.default_font_size = 21
	self.theme = theme
	load_settings()
	bgm = AudioStreamPlayer.new()
	bgm.stream = load("res://audio/quiet_chamber.ogg")
	bgm.stream.loop = true
	add_child(bgm)
	for index in range(4):
		var player = AudioStreamPlayer.new()
		add_child(player)
		se_players.append(player)
	apply_audio_settings()
	bgm.play()
	apply_audio_settings()
	var backdrop = TextureRect.new()
	backdrop.texture = load("res://art/generated/chamber.jpg")
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	var bg = ColorRect.new()
	bg.color = Color(0.04,0.07,0.10,0.60)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	apply_safe_area()
	add_child(margin)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",3)
	margin.add_child(body)
	get_viewport().size_changed.connect(on_resize)
	show_menu()

func clear_body():
	hand_panels.clear()
	forecast_nodes.clear()
	person_nodes.clear()
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()

func text(value: String, parent: Node = body, size: int = 21, color: Color = PAPER) -> Label:
	var label = Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label

func style(color: Color, border: Color) -> StyleBoxFlat:
	var box = StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(3)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	return box

func button(value: String, parent: Node, action: Callable, disabled: bool = false, accent: bool = false) -> Button:
	var btn = Button.new()
	btn.text = value
	btn.clip_text = true
	btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	btn.custom_minimum_size = Vector2(maxf(86,fonts.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,21).x+24),48)
	btn.add_theme_stylebox_override("normal",style(GOLD if accent else Color("263d49"),GOLD if accent else Color("67808b")))
	btn.add_theme_stylebox_override("hover",style(Color("365664"),GOLD))
	btn.add_theme_stylebox_override("pressed",style(Color("4c6b77"),PAPER))
	if accent: btn.add_theme_color_override("font_color",INK)
	btn.disabled = disabled or busy
	btn.pressed.connect(action)
	parent.add_child(btn)
	return btn

func row(parent: Node = body) -> HBoxContainer:
	var box = HBoxContainer.new()
	box.add_theme_constant_override("separation",12)
	parent.add_child(box)
	return box

func panel(parent: Node, color: Color = Color("20333f")) -> VBoxContainer:
	var p = PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.size_flags_stretch_ratio = 1.0
	p.add_theme_stylebox_override("panel",style(color,Color("887449")))
	parent.add_child(p)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation",4)
	p.add_child(box)
	return box

func show_menu():
	playing = false
	selected = -1
	targeting = false
	clear_body()
	text("FICTIONAL REPUBLIC  /  GODOT PROTOTYPE 05",body,18,GOLD)
	text("政局の手札",body,42,GOLD)
	text("夢の超特急 — 国会決戦",body,28)
	text("実機確認用の1戦です。準備戦・報酬・キャンペーンはHTML版に残しています。\n今回は準備成果を選んで本戦へ進みます。HP30／基本3コスト／手札保持・通常1枚ドロー。")
	var preparation = OptionButton.new()
	for label in ["財源を対策済み","議会対立を対策済み","報道を対策済み","対策なし"]: preparation.add_item(label)
	var options = ["finance","parliament","press","none"]
	preparation.selected = options.find(soft_choice)
	preparation.custom_minimum_size.y = 60
	preparation.item_selected.connect(func(index): soft_choice = options[index])
	body.add_child(preparation)
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation",14)
	grid.add_theme_constant_override("v_separation",14)
	body.add_child(grid)
	for type in ["admin","regional","noir","economic"]:
		var btn = button(game.data.labels[type]+"で開始",grid,func(): start_battle(type),false,true)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if FileAccess.file_exists(SAVE_PATH): button("保存した戦闘を再開",body,resume_battle)
	button("クレジット・ライセンス",body,show_credits)
	text("人物・組織・案件は架空です。APKは試遊用。横画面を推奨します。",body,18,Color("9cabb2"))

func start_battle(type: String):
	selected = -1
	targeting = false
	game.start(type,soft_choice,int(Time.get_ticks_usec()) & 0xffffffff)
	playing = true
	notice = "敵の予告を確認。使わない手札は次ターンに残ります。"
	persist()
	render_battle()

func resume_battle():
	selected = -1
	targeting = false
	if game.load_game(SAVE_PATH):
		playing = true
		notice = "保存した戦闘を再開しました。"
		render_battle()
	else: text("保存データを読み込めませんでした。新しい戦闘を開始できます。",body,21,GOLD)

func persist():
	if playing: game.save_game(SAVE_PATH)

func render_battle():
	clear_body()
	var b = game.b
	if selected >= b.hand.size(): selected = -1; targeting = false
	var header = row()
	header.name = "BattleHeader"
	text("政局の手札 / 国会決戦",header,25,GOLD)
	var stats = text("第%dターン  コスト%d/3  山札%d / 捨て札%d" % [b.turn,b.energy,b.pile.size(),b.discard.size()],header,22)
	stats.max_lines_visible = 2
	button("設定",header,show_settings)
	var arena = row()
	arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var own = panel(arena,Color(0.06,0.12,0.17,0.96))
	player_label = text("内閣  HP %d / 30   ブロック %d" % [b.hp,b.block],own,27,Color("94d6b5"))
	player_bar = health_bar(player_label,b.hp,Color("94d6b5"))
	text("次の攻撃＋%d / 次ターン追加ドロー%d" % [b.boost,b.nextDraw],own,18)
	for index in range(3):
		if index >= b.allies.size():
			text("— 人物配置枠 —",own,20,Color("8ea3ad"))
			continue
		var ally = b.allies[index]
		var g = b.get("growth",{}).get(ally.id,{"progress":0,"level":0})
		var growth = "成長済 ★" if g.level else "成長%d/%d" % [g.progress,game.data.growth[ally.id]]
		var person_row = row(own)
		var portrait = TextureRect.new()
		portrait.texture = card_art(game.card(ally.id))
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.custom_minimum_size = Vector2(48,48)
		person_row.add_child(portrait)
		var person_button = button(game.card(ally.id).name+"  "+growth+(" 停止中" if ally.disabledUntil >= b.turn else " 有効"),person_row,func(): show_person(ally.id),false)
		person_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		person_nodes[ally.id] = person_button
		if ally.disabledUntil >= b.turn:
			portrait.modulate = Color(0.5,0.5,0.5)
			person_button.add_theme_color_override("font_color",Color("8ea3ad"))
		elif g.level:
			person_button.add_theme_stylebox_override("normal",style(Color("263d49"),GOLD))
	var enemy = panel(arena,Color(0.18,0.12,0.15,0.96))
	enemy_label = text("国会  HP %d / 30   ブロック %d" % [b.enemyHP,b.enemyBlock],enemy,27,Color("f3b0a6"))
	enemy_bar = health_bar(enemy_label,b.enemyHP,Color("f3b0a6"))
	text("予告攻撃%d / 防御後%d" % [game.forecast(),maxi(0,game.forecast()-int(b.block))],enemy,22,GOLD)
	for forecast in b.plan:
		var effects: Array = []
		for e in forecast.effects:
			if e.op == "damage": effects.append("攻撃%d" % e.n)
			elif e.op == "block": effects.append("次手番防御%d" % e.n)
			else: effects.append(("手札戻し" if e.op == "bounce" else "停止")+"："+(game.card(forecast.target).name if forecast.get("target") != null else "対象なし"))
		var aff = game.data.attributes.get(forecast.get("aff",""),"無属性")
		var issue = game.data.issues.get(forecast.get("issue",""),{}).get("name","疑惑" if forecast.get("issue") == "scandal" else "共通防御")
		var label = "%s / %s  %s［%d］\n%s" % [aff,issue,forecast.name,forecast.cost,"無効・延期済" if forecast.cancelled else " / ".join(effects)]
		if targeting and selected >= 0:
			var effect = game.target_effect(game.card(b.hand[selected]))
			var valid = effect != null and game.targets(effect).any(func(p): return p.uid == forecast.uid)
			var target_btn = button(label,enemy,func(): use_card(selected,forecast.uid),not valid,true)
			target_btn.add_theme_font_size_override("font_size",16)
			target_btn.custom_minimum_size.x = 1
			forecast_nodes[forecast.uid] = target_btn
		else: forecast_nodes[forecast.uid] = text(label,enemy,16)
	var detail = panel(body)
	detail_box = detail
	var detail_row = row(detail)
	var description = VBoxContainer.new()
	description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_row.add_child(description)
	if selected >= 0:
		var c = game.card(b.hand[selected])
		text("%s / %s / コスト%d" % [c.name,game.data.attributes[c.aff],game.cost(c)],description,23,GOLD)
		var full = text(c.text,description,20)
		full.max_lines_visible = 2
		full.custom_minimum_size.x = 1
		full.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		if b.hand.size() > 7 and b.outcome == null:
			button("超過分を捨てる",detail_row,func(): discard_card(selected),game.done,true)
		else:
			button("対象を選択中" if targeting else "使用",detail_row,activate_selected,not game.can(c.id) or targeting,true)
		button("全文",detail_row,func(): show_description(c))
		button("解除",detail_row,func(): selected = -1; targeting = false; render_battle())
	else:
		text("手札をタップして選択",description,23,GOLD)
		text("説明を確認して「使用」。人物をタップすると能力と配置解除を表示。",description,20)
	var hand = row()
	hand.custom_minimum_size.y = card_size.y+8
	# Overflow cards remain individually reachable without shrinking every card.
	var hand_scroll = ScrollContainer.new()
	hand_scroll.name = "HandOverflow"
	hand_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hand_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	hand.add_child(hand_scroll)
	var center = CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_scroll.add_child(center)
	var cards = HBoxContainer.new()
	cards.add_theme_constant_override("separation",8)
	cards.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center.add_child(cards)
	for i in range(b.hand.size()):
		var c = game.card(b.hand[i])
		var holder = Button.new()
		holder.name = "HandCard%d" % i
		holder.custom_minimum_size = card_size
		holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		holder.add_theme_stylebox_override("normal",style(PAPER,GOLD if selected == i else Color("71838b")))
		holder.add_theme_stylebox_override("hover",style(Color("fff0cf"),GOLD))
		holder.add_theme_stylebox_override("focus",style(Color(0,0,0,0),GOLD))
		holder.pressed.connect(func(): select_card(i))
		holder.disabled = busy
		cards.add_child(holder)
		hand_panels.append(holder)
		var content = VBoxContainer.new()
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content.offset_left = 8; content.offset_right = -8; content.offset_top = 6; content.offset_bottom = -6
		holder.add_child(content)
		var title = text("%d  %s" % [game.cost(c),c.name],content,17,INK)
		title.custom_minimum_size = Vector2(1,48)
		title.max_lines_visible = 2
		title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		var art = TextureRect.new()
		art.texture = card_art(c)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.size_flags_vertical = Control.SIZE_EXPAND_FILL
		art.custom_minimum_size.y = 56
		content.add_child(art)
		text(game.data.attributes[c.aff]+" / "+{"attack":"攻撃","defense":"防御","prep":"準備","disrupt":"妨害","person":"人物"}.get(c.type,"負担"),content,16,INK)
		for child in content.get_children(): child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var status_row = row()
	var actions = row()
	actions.name = "BattleActions"
	var status = game.result if game.done else ("手札超過：カードを選んで捨てる" if b.hand.size() > 7 else notice)
	var status_label = text(status,status_row,18,GOLD)
	status_label.max_lines_visible = 1
	status_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	status_label.clip_text = true
	button("ログ",actions,show_log)
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(spacer)
	button("1手戻す",actions,func(): undo_action(false),game.history.is_empty() or game.done)
	button("ターンを戻す",actions,func(): undo_action(true),game.history.is_empty() or game.done)
	button("勝利を確定" if b.outcome == "win" else "ターン終了",actions,end_action,game.done or targeting or b.hand.size() > 7 and b.outcome == null,true)

func health_bar(label: Label, hp: int, color: Color) -> ProgressBar:
	var bar = ProgressBar.new()
	bar.max_value = 30
	bar.value = hp
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -3
	bar.offset_bottom = 1
	var background = StyleBoxFlat.new()
	background.bg_color = Color("182c35")
	bar.add_theme_stylebox_override("background",background)
	var fill = StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("fill",fill)
	label.add_child(bar)
	return bar

func activate_selected():
	if busy or selected < 0: return
	if game.target_effect(game.card(game.b.hand[selected])) != null:
		targeting = true
		notice = "金色の敵予告から対象を選んでください。"
		render_battle()
	else: use_card(selected,null)

func select_card(index: int):
	if busy: return
	selected = index
	targeting = false
	play_sound("select")
	render_battle()
	if fx_enabled: call_deferred("animate_selection",index)

func use_card(index: int, uid):
	if busy: return
	var before = game.b.duplicate(true)
	var used_card = game.card(game.b.hand[index])
	var origin = hand_panels[index].get_global_rect().get_center() if index < hand_panels.size() else safe_rect.get_center()
	var name = used_card.name
	if not game.play(index,uid): return
	selected = -1
	targeting = false
	notice = name+"を使用。"
	persist()
	busy = true
	freeze_buttons(body)
	play_sound("paper")
	await animate_action(before,origin,used_card.type,used_card.id)

func freeze_buttons(node: Node):
	if node is BaseButton: node.disabled = true
	for child in node.get_children(): freeze_buttons(child)

func end_action():
	if busy or targeting: return
	var before = game.b.duplicate(true)
	game.end_turn()
	selected = -1
	targeting = false
	play_sound("confirm")
	notice = "敵の行動が解決しました。次の予告を確認してください。"
	persist()
	await animate_action(before)

func undo_action(all_turn: bool):
	if busy: return
	game.undo(all_turn)
	selected = -1
	targeting = false
	notice = "操作を取り消しました。乱数も復元しています。"
	persist()
	render_battle()

func discard_card(index: int):
	if busy: return
	game.discard_overflow(index)
	selected = -1
	targeting = false
	persist()
	render_battle()

func retire_person(id: String):
	if busy or targeting: return
	game.retire(id)
	persist()
	render_battle()

func animate_selection(index: int):
	if index >= hand_panels.size(): return
	var chosen = hand_panels[index]
	chosen.pivot_offset = chosen.size/2
	if not fx_enabled: return
	create_tween().tween_property(chosen,"modulate",Color(1.0,0.95,0.8),0.12)
	var lift = create_tween()
	lift.tween_property(chosen,"position:y",chosen.position.y-4,0.08)
	lift.tween_property(chosen,"position:y",chosen.position.y,0.08)

func animate_action(before: Dictionary, origin: Vector2 = Vector2.ZERO, kind: String = "", used_id: String = ""):
	busy = true
	render_battle()
	var attack = maxi(0,int(before.enemyHP-game.b.enemyHP))
	var harm = maxi(0,int(before.hp-game.b.hp))
	var block_gain = maxi(0,int(game.b.block-before.block))
	var grown = game.events.any(func(e): return e.kind == "growth")
	var person_change = before.allies.size() != game.b.allies.size()
	var win = game.done and game.result == "勝利"
	var action = "victory" if win else ("growth" if grown else ("hit" if attack > 0 or harm > 0 else ("block" if block_gain > 0 else ("intervene" if kind == "disrupt" else "confirm"))))
	play_sound(action)
	var message = "採決成立" if win else ("成長 ★" if grown else ("攻撃 −%d" % attack if attack > 0 else ("被害 −%d" % harm if harm > 0 else ("防御 ＋%d" % block_gain if block_gain > 0 else ("予告に介入" if kind == "disrupt" else ("人物配置・退場" if person_change else "行動完了"))))))
	var target = enemy_label if attack > 0 or kind == "disrupt" else player_label
	# Effects refer to the changed public action, not an AI-specific animation.
	if kind == "disrupt":
		for after_plan in game.b.plan:
			for old_plan in before.plan:
				if after_plan.uid != old_plan.uid: continue
				if JSON.stringify(after_plan) != JSON.stringify(old_plan):
					target = forecast_nodes.get(after_plan.uid,enemy_label)
					message = "予告を延期" if used_id == "delay" else ("予告を無効化" if after_plan.cancelled else "予告を軽減")
					break
	if grown:
		for event in game.events:
			if event.kind == "growth":
				for id in person_nodes:
					if game.card(id).name == event.name: target = person_nodes[id]
	var color = Color("ffb1a2") if attack > 0 or harm > 0 else (Color("a8d8ff") if block_gain > 0 else GOLD)
	if fx_enabled:
		player_bar.value = before.hp
		enemy_bar.value = before.enemyHP
		var hp_tween = create_tween().set_parallel(true)
		hp_tween.tween_property(player_bar,"value",float(game.b.hp),0.35)
		hp_tween.tween_property(enemy_bar,"value",float(game.b.enemyHP),0.35)
		var destination = target.get_global_rect().get_center()
		if origin != Vector2.ZERO:
			var trail = Line2D.new()
			trail.width = 3
			trail.default_color = color
			trail.add_point(origin)
			trail.add_point(origin)
			add_child(trail)
			var travel = create_tween()
			travel.tween_method(func(point): trail.set_point_position(1,point),origin,destination,0.16)
			await travel.finished
			trail.queue_free()
		var floating = Label.new()
		floating.text = message
		floating.add_theme_font_size_override("font_size",30)
		floating.add_theme_color_override("font_color",color)
		floating.position = Vector2(clampf(destination.x-110,safe_rect.position.x,safe_rect.end.x-260),clampf(destination.y+15,safe_rect.position.y+20,safe_rect.end.y-60))
		floating.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(floating)
		var ring = Panel.new()
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ring.position = target.global_position
		ring.size = target.size
		var ring_style = StyleBoxFlat.new()
		ring_style.bg_color = Color(color,0.10)
		ring_style.border_color = color
		ring_style.set_border_width_all(3)
		ring.add_theme_stylebox_override("panel",ring_style)
		add_child(ring)
		var tween = create_tween().set_parallel(true)
		tween.tween_property(floating,"position:y",floating.position.y-20,0.28)
		tween.tween_property(floating,"modulate:a",0,0.28)
		tween.tween_property(ring,"modulate:a",0,0.28)
		await tween.finished
		floating.queue_free()
		ring.queue_free()
	busy = false
	game.events.clear()
	render_battle()

func play_sound(id: String):
	if muted or se_volume <= 0 or se_players.is_empty(): return
	var player = se_players[0]
	for candidate in se_players:
		if not candidate.playing: player = candidate; break
	player.stream = load("res://audio/"+id+".wav")
	player.volume_db = -8+linear_to_db(se_volume/100.0)
	player.play()

func apply_audio_settings():
	if bgm == null: return
	bgm.volume_db = -6+linear_to_db(maxf(bgm_volume/100.0,0.0001))
	bgm.stream_paused = bgm_volume <= 0

func load_settings():
	if FileAccess.file_exists(SETTINGS_PATH):
		var settings = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS_PATH))
		if settings is Dictionary:
			bgm_volume = clampf(settings.get("bgm",40),0,100)
			se_volume = clampf(settings.get("se",65),0,100)
			wide_margin = settings.get("wide_margin",false)
			fx_enabled = settings.get("fx",true)
	settings_loaded = true

func save_settings():
	var file = FileAccess.open(SETTINGS_PATH,FileAccess.WRITE)
	if file: file.store_string(JSON.stringify({"bgm":bgm_volume,"se":se_volume,"wide_margin":wide_margin,"fx":fx_enabled}))

func _notification(what):
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		persist()
		if bgm != null: bgm.stream_paused = true
		for player in se_players: player.stop()
	elif what == NOTIFICATION_APPLICATION_RESUMED: apply_audio_settings()

func apply_safe_area():
	var view = get_viewport_rect()
	var physical_safe = Rect2(DisplayServer.get_display_safe_area())
	var cutouts = DisplayServer.get_display_cutouts()
	var transform = get_screen_transform().affine_inverse()
	var window_origin = Vector2.ZERO
	if simulated_safe.size.x > 0:
		physical_safe = simulated_safe
		cutouts = simulated_cutouts
		transform = Transform2D.IDENTITY
		window_origin = Vector2.ZERO
	safe_rect = MobileUI.safe_canvas(view,transform,window_origin,physical_safe,cutouts,28 if wide_margin else 16)
	if margin != null:
		margin.add_theme_constant_override("margin_left",int(safe_rect.position.x))
		margin.add_theme_constant_override("margin_top",int(safe_rect.position.y))
		margin.add_theme_constant_override("margin_right",int(view.end.x-safe_rect.end.x))
		margin.add_theme_constant_override("margin_bottom",int(view.end.y-safe_rect.end.y))
	card_size = Vector2(minf(156,floor((safe_rect.size.x-48)/7)),156)
	if popup_layer != null: place_popup()

func on_resize():
	if resize_pending: return
	resize_pending = true
	call_deferred("refresh_size")

func refresh_size():
	if busy:
		await get_tree().process_frame
		call_deferred("refresh_size")
		return
	resize_pending = false
	apply_safe_area()
	if playing: render_battle()
	else: show_menu()

func close_popup():
	if popup_layer != null:
		popup_layer.queue_free()
		popup_layer = null

func popup(title: String) -> VBoxContainer:
	close_popup()
	popup_layer = Control.new()
	popup_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(popup_layer)
	var shade = ColorRect.new()
	shade.color = Color(0,0,0,0.7)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup_layer.add_child(shade)
	var holder = PanelContainer.new()
	holder.name = "PopupPanel"
	holder.add_theme_stylebox_override("panel",style(INK,GOLD))
	popup_layer.add_child(holder)
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation",8)
	holder.add_child(content)
	var heading = row(content)
	var heading_label = text(title,heading,24,GOLD)
	heading_label.custom_minimum_size.x = 1
	heading_label.max_lines_visible = 2
	button("閉じる",heading,close_popup)
	place_popup()
	return content

func place_popup():
	if popup_layer == null: return
	var holder = popup_layer.get_node("PopupPanel")
	holder.size = Vector2(minf(900,safe_rect.size.x),minf(480,safe_rect.size.y))
	holder.position = safe_rect.get_center()-holder.size/2

func scroll_text(value: String, parent: Node) -> ScrollContainer:
	var scroll = TouchLog.new()
	scroll.name = "TouchScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)
	var content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(content)
	for line in value.split("\n"):
		var label = text(line,content,20)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	call_deferred("place_popup")
	return scroll

func show_person(id: String):
	var content = popup(game.card(id).name)
	scroll_text(game.card(id).text+"\n停止・手札戻しでも成長は保持します。",content)
	button("配置解除",content,func(): close_popup(); retire_person(id),busy or game.done or game.b.outcome != null or targeting)

func show_log():
	var content = popup("戦闘ログ / seed %d" % game.initial_seed)
	scroll_text("\n".join(game.b.log),content)

func show_description(c: Dictionary):
	var content = popup(c.name+" / "+game.data.attributes[c.aff])
	scroll_text("コスト%d\n\n%s" % [game.cost(c),c.text],content)

func show_settings():
	var content = popup("設定")
	for kind in ["bgm","se"]:
		var control_row = row(content)
		text("BGM音量" if kind == "bgm" else "SE音量",control_row,21)
		var slider = HSlider.new()
		slider.name = kind+"_volume"
		slider.max_value = 100
		slider.step = 5
		slider.value = bgm_volume if kind == "bgm" else se_volume
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.custom_minimum_size = Vector2(300,48)
		control_row.add_child(slider)
		slider.value_changed.connect(func(value):
			if kind == "bgm": bgm_volume = value; apply_audio_settings()
			else: se_volume = value
			save_settings())
	var margin_setting = CheckButton.new()
	margin_setting.text = "画面端の余白を広めにする"
	margin_setting.button_pressed = wide_margin
	content.add_child(margin_setting)
	margin_setting.toggled.connect(func(value): wide_margin = value; save_settings(); apply_safe_area(); render_battle())
	var fx = CheckButton.new()
	fx.text = "演出を表示（OFFで短縮）"
	fx.button_pressed = fx_enabled
	content.add_child(fx)
	fx.toggled.connect(func(value): fx_enabled = value; save_settings())
	button("初期画面",content,func(): close_popup(); show_menu())

func show_credits():
	var content = popup("クレジット・ライセンス")
	scroll_text("政局の手札 — 架空国家の試作\n画像：imagegenによるオリジナル生成\nBGM/SE：scripts/generate_audio.pyによるオリジナル合成\n\nGodot Engine\n"+Engine.get_license_text()+"\n\nNoto Sans JP\n"+FileAccess.get_file_as_string("res://fonts/OFL.txt")+"\n\n"+JSON.stringify(Engine.get_copyright_info()),content)

# Atlas regions are sampled at runtime: no text or rules baked into illustrations.
func card_art(c: Dictionary) -> Texture2D:
	var tiles = {"official":0,"leader":1,"reporter":2,"delay":4,"answer":7,"lobby":6,"report":8,"investigate":8,"brief":8,"budgetReview":5}
	var added_tiles = {"economist":0,"organizer":1,"broker":2,"whip":3,"investigate":4,"invest":5,"network":6,"deal":7,"debate":8}
	var added = added_tiles.has(c.id)
	var tile = added_tiles[c.id] if added else tiles.get(c.id,-1)
	if tile < 0:
		if c.type == "person":
			return load("res://art/placeholders/person.svg")
		tile = {"admin":4,"politics":6,"press":8,"business":5,"community":6,"noir":6}.get(c.aff,4)
	var atlas = load("res://art/generated/political_atlas_v05.jpg" if added else "res://art/generated/political_atlas.jpg")
	var texture = AtlasTexture.new()
	texture.atlas = atlas
	var cell = atlas.get_width()/3.0
	texture.region = Rect2((tile%3)*cell,floor(tile/3.0)*cell,cell,cell)
	texture.filter_clip = true
	return texture

func _exit_tree():
	if bgm != null:
		bgm.stop()
		bgm.stream = null
	for player in se_players:
		player.stop()
		player.stream = null
