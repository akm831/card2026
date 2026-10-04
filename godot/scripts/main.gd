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

func _ready():
	fonts = load("res://fonts/NotoSansJP.ttf") if ResourceLoader.exists("res://fonts/NotoSansJP.ttf") else SystemFont.new()
	var theme = Theme.new()
	theme.default_font = fonts
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
	var scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	var margin = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for edge in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,22)
	scroll.add_child(margin)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",14)
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
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	return box

func button(value: String, parent: Node, action: Callable, disabled: bool = false, accent: bool = false) -> Button:
	var btn = Button.new()
	btn.text = value
	btn.custom_minimum_size.y = 60
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
	clear_body()
	text("KASUMIGASEKI  /  GODOT PROTOTYPE 01",body,18,GOLD)
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
	game.start(type,soft_choice,int(Time.get_ticks_usec()) & 0xffffffff)
	playing = true
	notice = "敵の予告を確認。使わない手札は次ターンに残ります。"
	persist()
	render_battle()

func resume_battle():
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
	var header = row()
	text("政局の手札  /  国会決戦",header,30,GOLD)
	button("SE：OFF" if muted else "SE：ON",header,func(): muted = not muted; render_battle())
	button("初期画面",header,show_menu)
	text("第%dターン   コスト %d   次の攻撃＋%d   山札%d / 捨て札%d" % [b.turn,b.energy,b.boost,b.pile.size(),b.discard.size()],body,23)
	var arena = row()
	var own = panel(arena)
	player_label = text("内閣  HP %d / 30   ブロック %d" % [b.hp,b.block],own,28,Color("94d6b5"))
	text("人物は最大3人。停止・手札戻しでも成長は保持。",own,17)
	for ally in b.allies:
		var g = b.get("growth",{}).get(ally.id,{"progress":0,"level":0})
		var label = "成長済み ★" if g.level else "成長 %d / %d" % [g.progress,game.data.growth[ally.id]]
		text(game.card(ally.id).name+" ／ "+label+(" ／ 能力停止中" if ally.disabledUntil >= b.turn else " ／ 有効"),own,20,GOLD)
		text(game.card(ally.id).text,own,17)
		button("配置解除："+game.card(ally.id).name,own,func(): retire_person(ally.id),game.done or b.outcome != null or selected >= 0)
	var enemy = panel(arena,Color("352e39"))
	enemy_label = text("国会  HP %d / 30   ブロック %d" % [b.enemyHP,b.enemyBlock],enemy,28,Color("e69992"))
	text("予告攻撃 %d ／ 現在の防御後 %d" % [game.forecast(),maxi(0,game.forecast()-int(b.block))],enemy,22,GOLD)
	for forecast in b.plan:
		var effects: Array = []
		for e in forecast.effects:
			if e.op == "damage": effects.append("攻撃%d" % e.n)
			elif e.op == "block": effects.append("次手番防御%d" % e.n)
			else: effects.append(("手札戻し" if e.op == "bounce" else "能力停止")+"："+(game.card(forecast.target).name if forecast.get("target") != null else "対象なし"))
		var aff = game.data.attributes.get(forecast.get("aff",""),"無属性")
		var issue = game.data.issues.get(forecast.get("issue",""),{}).get("name","疑惑" if forecast.get("issue") == "scandal" else "共通防御")
		text("属性："+aff+" ／ 論点："+issue,enemy,16,Color("b9b7c6"))
		var label = "%s［%d］%s" % [forecast.name,forecast.cost,"無効／延期済み" if forecast.cancelled else "・".join(effects)]
		if selected >= 0:
			var e = game.target_effect(game.card(b.hand[selected]))
			var valid = e != null and game.targets(e).any(func(p): return p.uid == forecast.uid)
			button(label,enemy,func(): use_card(selected,forecast.uid),not valid,true)
		else: text(label,enemy,19)
	if game.done:
		text(game.result+" — 今回のGodot試作はここまでです。",body,34,GOLD)
		button("初期画面へ",body,show_menu,false,true)
	elif b.outcome == "win": text("相手を倒しました。勝利確定まではUndoできます。",body,25,GOLD)
	if b.hand.size() > 7 and b.outcome == null: notice = "手札上限7枚。超過分を選んで捨ててください。"
	text(notice,body,21,GOLD)
	if selected >= 0: button("対象選択をキャンセル",body,func(): selected = -1; render_battle())
	var hand = HFlowContainer.new()
	hand.add_theme_constant_override("h_separation",12)
	hand.add_theme_constant_override("v_separation",12)
	body.add_child(hand)
	for i in range(b.hand.size()):
		var c = game.card(b.hand[i])
		var holder = PanelContainer.new()
		holder.custom_minimum_size = Vector2(282,230)
		holder.add_theme_stylebox_override("panel",style(PAPER,Color("957448")))
		hand.add_child(holder)
		hand_panels.append(holder)
		var content = VBoxContainer.new()
		holder.add_child(content)
		text("%s  コスト%d" % [c.name,game.cost(c)],content,22,INK)
		text(game.data.attributes[c.aff]+" ／ "+{"attack":"攻撃","defense":"防御","prep":"準備","disrupt":"妨害","person":"人物"}.get(c.type,"負担"),content,17,Color("48616b"))
		var description = text(c.text,content,17,INK)
		description.custom_minimum_size.x = 248
		description.size_flags_vertical = Control.SIZE_EXPAND_FILL
		if b.hand.size() > 7 and b.outcome == null:
			button("上限超過：捨てる",content,func(): discard_card(i),game.done)
		else:
			button("使用",content,func(): select_card(i),not game.can(c.id) or selected >= 0,true)
		button("説明を拡大",content,func(): show_description(c))
	var actions = row()
	button("勝利を確定" if b.outcome == "win" else "ターン終了",actions,end_action,game.done or selected >= 0 or b.hand.size() > 7 and b.outcome == null,true)
	button("1手戻す",actions,func(): undo_action(false),game.history.is_empty() or game.done)
	button("ターンを戻す",actions,func(): undo_action(true),game.history.is_empty() or game.done)
	text("seed：%d ／ 非公開の敵手札・山札は表示しません。" % game.initial_seed,body,16,Color("98a8af"))
	var logbox = panel(body)
	for line in b.log.slice(0,6): text(line,logbox,17)

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
	if game.target_effect(game.card(game.b.hand[index])) != null:
		selected = index
		notice = "対象の敵予告を選んでください。"
		render_battle()
	else: use_card(index,null)

func use_card(index: int, uid):
	if busy: return
	var before = game.b.duplicate(true)
	var name = game.card(game.b.hand[index]).name
	if not game.play(index,uid): return
	selected = -1
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
	if busy or selected >= 0: return
	var before = game.b.duplicate(true)
	game.end_turn()
	notice = "敵の行動が解決しました。次の予告を確認してください。"
	persist()
	await animate_action(before)

func undo_action(all_turn: bool):
	if busy: return
	game.undo(all_turn)
	selected = -1
	notice = "操作を取り消しました。乱数も復元しています。"
	persist()
	render_battle()

func discard_card(index: int):
	if busy: return
	game.discard_overflow(index)
	persist()
	render_battle()

func retire_person(id: String):
	if busy or selected >= 0: return
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
