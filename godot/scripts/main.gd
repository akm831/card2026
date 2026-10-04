extends Control
const Core = preload("res://scripts/battle_engine.gd")
const SAVE_PATH = "user://battle_v1.json"
const GOLD = Color("e4b760")
const PAPER = Color("e9dfc5")
const INK = Color("15242e")
var game = Core.new()
var body: VBoxContainer
var player_label: Label
var enemy_label: Label
var selected: int = -1
var busy: bool = false
var muted: bool = false
var playing: bool = false
var audio: AudioStreamPlayer
var fonts: Font
var soft_choice: String = "finance"
var notice: String = ""
var hand_panels: Array = []
var targeting: bool = false
var detail_box: VBoxContainer
const AFF_COLORS = {"admin":Color("328cd8"),"politics":Color("ca5460"),"press":Color("8f72cf"),"business":Color("b18a36"),"community":Color("39876b"),"noir":Color("746782")}

func _ready():
	fonts = load("res://fonts/NotoSansJP.ttf") if ResourceLoader.exists("res://fonts/NotoSansJP.ttf") else SystemFont.new()
	var theme = Theme.new()
	var weighted = FontVariation.new()
	weighted.base_font = fonts
	weighted.variation_opentype = {"wght":650}
	theme.default_font = weighted
	theme.default_font_size = 21
	self.theme = theme
	audio = AudioStreamPlayer.new()
	audio.volume_db = -18
	add_child(audio)
	var bg = ColorRect.new()
	bg.color = INK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,12)
	add_child(margin)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",8)
	margin.add_child(body)
	show_menu()

func clear_body():
	hand_panels.clear()
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
	box.set_corner_radius_all(5)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	return box

func button(value: String, parent: Node, action: Callable, disabled: bool = false, accent: bool = false) -> Button:
	var btn = Button.new()
	btn.text = value
	btn.custom_minimum_size.y = 48
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
	p.add_theme_stylebox_override("panel",style(color,Color("526d79")))
	parent.add_child(p)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation",8)
	p.add_child(box)
	return box

func show_menu():
	playing = false
	selected = -1
	targeting = false
	clear_body()
	text("KASUMIGASEKI  /  GODOT PROTOTYPE 02",body,18,GOLD)
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
	text("政局の手札 / 国会決戦",header,25,GOLD)
	text("第%dターン  コスト%d/3  山札%d / 捨て札%d" % [b.turn,b.energy,b.pile.size(),b.discard.size()],header,22)
	button("設定",header,show_settings)
	var arena = row()
	arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var own = panel(arena)
	player_label = text("内閣  HP %d / 30   ブロック %d" % [b.hp,b.block],own,27,Color("94d6b5"))
	text("次の攻撃＋%d / 次ターン追加ドロー%d" % [b.boost,b.nextDraw],own,18)
	for index in range(3):
		if index >= b.allies.size():
			text("— 人物配置枠 —",own,20,Color("8ea3ad"))
			continue
		var ally = b.allies[index]
		var g = b.get("growth",{}).get(ally.id,{"progress":0,"level":0})
		var growth = "成長済 ★" if g.level else "成長%d/%d" % [g.progress,game.data.growth[ally.id]]
		button(game.card(ally.id).name+"  "+growth+(" 停止中" if ally.disabledUntil >= b.turn else " 有効"),own,func(): show_person(ally.id),false)
	var enemy = panel(arena,Color("352e39"))
	enemy_label = text("国会  HP %d / 30   ブロック %d" % [b.enemyHP,b.enemyBlock],enemy,27,Color("f3b0a6"))
	text("予告攻撃%d / 防御後%d" % [game.forecast(),maxi(0,game.forecast()-int(b.block))],enemy,22,GOLD)
	text("敵人物：次の検証で追加予定",enemy,17,Color("bfc7d1"))
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
			target_btn.add_theme_font_size_override("font_size",18)
		else: text(label,enemy,17)
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
	hand.custom_minimum_size.y = 152
	# Overflow cards remain individually reachable without shrinking every card.
	var hand_scroll = ScrollContainer.new()
	hand_scroll.name = "HandOverflow"
	hand_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hand_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	hand.add_child(hand_scroll)
	var cards = HBoxContainer.new()
	cards.add_theme_constant_override("separation",8)
	cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_scroll.add_child(cards)
	for i in range(b.hand.size()):
		var c = game.card(b.hand[i])
		var holder = Button.new()
		holder.name = "HandCard%d" % i
		holder.custom_minimum_size = Vector2(166,140)
		holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
		var title = text("%d  %s" % [game.cost(c),c.name],content,19,INK)
		title.custom_minimum_size.x = 1
		title.max_lines_visible = 2
		title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		var art = TextureRect.new()
		art.texture = load("res://art/placeholders/"+c.type+".svg") if c.type in ["attack","defense","prep","disrupt","person"] else load("res://art/placeholders/disrupt.svg")
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.size_flags_vertical = Control.SIZE_EXPAND_FILL
		art.modulate = AFF_COLORS.get(c.aff,INK)
		content.add_child(art)
		text(game.data.attributes[c.aff]+" / "+{"attack":"攻撃","defense":"防御","prep":"準備","disrupt":"妨害","person":"人物"}.get(c.type,"負担"),content,17,INK)
		for child in content.get_children(): child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var actions = row()
	var status = game.result if game.done else ("手札超過：カードを選んで捨てる" if b.hand.size() > 7 else notice)
	var status_label = text(status,actions,18,GOLD)
	status_label.max_lines_visible = 2
	button("ログ",actions,show_log)
	button("1手戻す",actions,func(): undo_action(false),game.history.is_empty() or game.done)
	button("ターンを戻す",actions,func(): undo_action(true),game.history.is_empty() or game.done)
	button("勝利を確定" if b.outcome == "win" else "ターン終了",actions,end_action,game.done or targeting or b.hand.size() > 7 and b.outcome == null,true)

func activate_selected():
	if busy or selected < 0: return
	if game.target_effect(game.card(game.b.hand[selected])) != null:
		targeting = true
		notice = "金色の敵予告から対象を選んでください。"
		render_battle()
	else: use_card(selected,null)

func show_person(id: String):
	var dialog = AcceptDialog.new()
	dialog.title = game.card(id).name
	dialog.dialog_text = game.card(id).text+"\n停止・手札戻しでも成長は保持します。"
	var retire = dialog.add_button("配置解除",true,"retire")
	retire.disabled = busy or game.done or game.b.outcome != null or targeting
	dialog.custom_action.connect(func(_action): dialog.queue_free(); retire_person(id))
	add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(680,260))

func show_log():
	var dialog = AcceptDialog.new()
	dialog.title = "戦闘ログ / seed %d" % game.initial_seed
	var log_text = TextEdit.new()
	log_text.editable = false
	log_text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	log_text.custom_minimum_size = Vector2(780,400)
	log_text.text = "\n".join(game.b.log)
	dialog.add_child(log_text)
	add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered()

func show_settings():
	var dialog = AcceptDialog.new()
	dialog.title = "設定"
	dialog.dialog_text = "戦闘は自動保存されます。"
	dialog.add_button("SE切替",true,"sound")
	dialog.add_button("初期画面",true,"menu")
	dialog.custom_action.connect(func(action):
		dialog.queue_free()
		if action == "sound": muted = not muted; render_battle()
		else: show_menu())
	add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered()

func show_description(c: Dictionary):
	var dialog = AcceptDialog.new()
	dialog.title = c.name+" — "+game.data.attributes[c.aff]
	dialog.dialog_text = "コスト%d\n\n%s" % [game.cost(c),c.text]
	dialog.min_size = Vector2i(650,300)
	add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered()

func select_card(index: int):
	if busy: return
	selected = index
	targeting = false
	render_battle()

func use_card(index: int, uid):
	if busy: return
	var before = game.b.duplicate(true)
	var name = game.card(game.b.hand[index]).name
	if not game.play(index,uid): return
	selected = -1
	targeting = false
	notice = name+"を使用。"
	persist()
	busy = true
	freeze_buttons(body)
	if index < hand_panels.size():
		var chosen = hand_panels[index]
		chosen.pivot_offset = chosen.size / 2
		var lift = create_tween().set_parallel(true)
		lift.tween_property(chosen,"scale",Vector2(1.04,1.04),0.13)
		lift.tween_property(chosen,"modulate",Color(1.0,0.84,0.48,0.5),0.13)
		await lift.finished
	await animate_action(before)

func freeze_buttons(node: Node):
	if node is BaseButton: node.disabled = true
	for child in node.get_children(): freeze_buttons(child)

func end_action():
	if busy or targeting: return
	var before = game.b.duplicate(true)
	game.end_turn()
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

func animate_action(before: Dictionary):
	busy = true
	render_battle()
	var delta = int(before.enemyHP-game.b.enemyHP)
	var own_delta = int(before.hp-game.b.hp)
	var block_delta = int(game.b.block-before.block)
	var label = enemy_label if delta > 0 else player_label
	var color = Color("ffaaa0") if delta > 0 or own_delta > 0 else Color("96d8ff")
	var message = "−%d" % delta if delta > 0 else ("−%d" % own_delta if own_delta > 0 else ("防御＋%d" % block_delta if block_delta > 0 else "行動"))
	var grown = game.events.any(func(e): return e.kind == "growth")
	if grown:
		message += "  成長 ★"
		color = GOLD
	play_tone(880 if grown else (180 if own_delta > 0 else (330 if delta > 0 else 660)))
	var floating = Label.new()
	floating.text = message
	floating.add_theme_font_size_override("font_size",36)
	floating.add_theme_color_override("font_color",color)
	floating.position = Vector2(500,100)
	floating.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(floating)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(label,"modulate",color,0.08)
	tween.tween_property(floating,"position:y",50,0.35)
	tween.tween_property(floating,"modulate:a",0,0.35)
	await tween.finished
	floating.queue_free()
	busy = false
	game.events.clear()
	render_battle()

func play_tone(hz: int):
	if muted: return
	var bytes = PackedByteArray()
	var rate = 22050
	var length = 2646
	bytes.resize(length*2)
	for i in range(length):
		var wave = 1.0 if sin(TAU*hz*i/rate) > 0 else -1.0
		var sample = int(wave * 5000 * pow(1.0-float(i)/length,2))
		bytes.encode_s16(i*2,sample)
	var sound = AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = rate
	sound.data = bytes
	audio.stream = sound
	audio.play()

func _notification(what):
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST: persist()

func show_credits():
	var dialog = AcceptDialog.new()
	dialog.title = "クレジット・ライセンス"
	var content = TextEdit.new()
	content.editable = false
	content.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	content.custom_minimum_size = Vector2(800,480)
	content.text = "政局の手札 — Godot試作\n\nGodot Engine\n" + Engine.get_license_text() + "\n\nNoto Sans JP\n" + FileAccess.get_file_as_string("res://fonts/OFL.txt") + "\n\nGodot dependencies\n" + JSON.stringify(Engine.get_copyright_info(),"  ") + "\n" + JSON.stringify(Engine.get_license_info(),"  ")
	dialog.add_child(content)
	add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered()
