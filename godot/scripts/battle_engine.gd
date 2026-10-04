class_name BattleEngine
extends RefCounted

var data: Dictionary
var b: Dictionary = {}
var seed: int = 1
var initial_seed: int = 1
var history: Array = []
var done: bool = false
var result: String = ""
var events: Array = []

func _init():
	data = JSON.parse_string(FileAccess.get_file_as_string("res://data/game.json"))

func random_value() -> float:
	seed = (seed * 1664525 + 1013904223) & 0xffffffff
	return float(seed) / 4294967296.0

func shuffled(items: Array) -> Array:
	var out = items.duplicate(true)
	for i in range(out.size() - 1, 0, -1):
		var j = int(floor(random_value() * (i + 1)))
		var tmp = out[i]
		out[i] = out[j]
		out[j] = tmp
	return out

func start(deck_type: String, soft: String, value: int):
	seed = value & 0xffffffff
	initial_seed = seed
	done = false
	result = ""
	history.clear()
	events.clear()
	b = {"kind":"final", "hp":30,"maxHP":30,"enemyHP":30,"maxEnemy":30,"energy":3,"block":0,"enemyBlock":0,"turn":0,
		"pile":shuffled(data.decks[deck_type]),"hand":[],"discard":[],"removed":[],"allies":[],
		"enemyPile":shuffled(data.enemies[soft]),"enemyDiscard":[],"enemyHand":[],"plan":[],"deferred":[],
		"used":{},"counts":{},"boost":0,"protect":0,"invest":0,"nextDraw":0,"nextBlock":0,"discount":false,
		"returnQueue":[],"log":[],"outcome":null}
	next_turn()

func card(id: String) -> Dictionary:
	return data.cards[id]

func active(engine: String) -> Array:
	return b.allies.filter(func(a): return a.disabledUntil < b.turn and card(a.id).get("engine", "") == engine)

func say(text: String):
	b.log.push_front(text)
	if b.log.size() > 40: b.log.pop_back()

func draw(n: int):
	for i in range(n):
		if b.pile.is_empty():
			b.pile = shuffled(b.discard)
			b.discard = []
		if not b.pile.is_empty(): b.hand.append(b.pile.pop_back())

func next_turn():
	b.turn += 1
	b.energy = 3 + b.invest + b.get("nextEnergy",0)
	b.nextEnergy = 0
	b.block = b.nextBlock
	for a in b.allies:
		if a.id == "official" and a.disabledUntil < b.turn and b.get("growth",{}).get(a.id,{}).get("level",0) > 0:
			b.block += 5
			say("敏腕官僚：ターン開始ブロック5。")
	b.boost = 0
	b.protect = 0
	b.used = {}
	b.counts = {}
	b.discount = false
	draw((5 if b.turn == 1 else 1) + b.invest + b.nextDraw)
	b.hand.append_array(b.returnQueue)
	b.returnQueue = []
	b.invest = 0
	b.nextDraw = 0
	b.nextBlock = 0
	plan_turn()
	say("第%dターン。予告を確認してください。" % b.turn)

func person_value(a: Dictionary) -> float:
	var base = {"official":3,"leader":2,"reporter":3,"economist":2,"organizer":2,"broker":2}.get(a.id,2)
	var growth = b.get("growth",{}).get(a.id,{})
	return base + ((4 if a.id == "official" else 2) if growth.get("level",0) else minf(1, growth.get("progress",0) * 0.3))

func enemy_target(c: Dictionary):
	var effect = null
	for e in c.effects:
		if e.op in ["suppress","bounce"]:
			effect = e
			break
	if effect == null: return null
	var best = null
	var score = -INF
	for a in b.allies:
		if effect.get("aff", "") != "" and effect.aff != card(a.id).aff: continue
		if effect.op == "suppress" and a.disabledUntil >= b.turn + 1: continue
		if person_value(a) > score:
			best = a.id
			score = person_value(a)
	return best

func plan_score(plan: Array) -> float:
	var damage = 0.0
	var block = 0.0
	var interference = {}
	var spent = 0.0
	for c in plan:
		spent += c.cost
		for e in c.effects:
			if e.op == "damage": damage += e.n
			if e.op == "block": block += e.n
			if e.op in ["bounce","suppress"]:
				for a in b.allies:
					if a.id != c.get("target"): continue
					if e.get("aff", "") != "" and e.aff != card(a.id).aff: continue
					if e.op == "suppress" and a.disabledUntil >= b.turn + 1: continue
					var value = person_value(a) * (0.7 if e.op == "bounce" else 1.0)
					interference[a.id] = maxf(interference.get(a.id, 0), value)
	var net = maxf(0, damage - b.block)
	var attack = minf(b.hp,net) + (18 if net >= b.hp and b.hp > 0 else 0) + damage * 0.05
	var expected = minf(20, maxf(6, (b.get("lastPlayerDamage",0) if b.get("lastPlayerDamage",0) else 6) + 2))
	var defense = minf(block, expected) * (1.3 if b.enemyHP <= 12 else 0.65)
	for value in interference.values(): attack += value
	return attack + defense - spent * 0.08

func plan_turn():
	for i in range(5 if b.turn == 1 else 1):
		if b.enemyPile.is_empty():
			b.enemyPile = shuffled(b.enemyDiscard)
			b.enemyDiscard = []
		if not b.enemyPile.is_empty(): b.enemyHand.append(b.enemyPile.pop_back())
	while b.enemyHand.size() > 7:
		var worst = 0
		var score = INF
		for i in range(b.enemyHand.size()):
			var c = b.enemyHand[i].duplicate(false)
			c.target = enemy_target(c)
			var value = plan_score([c]) / c.cost
			if value < score:
				worst = i
				score = value
		b.enemyDiscard.append(b.enemyHand.pop_at(worst))
	var reserved: Array = []
	var budget = 3
	for item in b.deferred:
		var c = item.duplicate(true)
		c.delayed = true
		c.cancelled = false
		c.target = enemy_target(c)
		reserved.append(c)
		budget -= c.cost
	b.deferred = []
	var best: Array = []
	var best_score = plan_score(reserved)
	for mask in range(1, 1 << b.enemyHand.size()):
		var costs = 0
		var candidates: Array = []
		for i in range(b.enemyHand.size()):
			if mask & (1 << i):
				var c = b.enemyHand[i].duplicate(false)
				costs += c.cost
				c.target = enemy_target(c)
				candidates.append(c)
		if costs > maxi(0,budget): continue
		var value = plan_score(reserved + candidates)
		if value > best_score + 0.000000001:
			best_score = value
			best = candidates
	b.plan = reserved + best
	for c in b.plan:
		c.cancelled = false
		b.uidCounter = b.get("uidCounter",0) + 1
		c.uid = b.uidCounter
	b.enemyTurnStartHP = b.enemyHP

func cost(c: Dictionary) -> int:
	var n = int(c.cost)
	if c.type != "person" and c.aff == "politics" and b.discount: n -= 1
	if c.type == "disrupt" and not active("disruptDiscount").is_empty() and not b.used.get("disruptDiscount",false): n -= 1
	return maxi(0,n)

func matches(e: Dictionary, p: Dictionary) -> bool:
	return (not e.has("issue") or e.issue == p.get("issue")) and (not e.has("issues") or p.get("issue") in e.issues) and (not e.has("affs") or p.get("aff") in e.affs)

func has_damage(p: Dictionary, positive: bool = false) -> bool:
	return p.effects.any(func(e): return e.op == "damage" and (not positive or e.n > 0))

func targets(e: Dictionary) -> Array:
	return b.plan.filter(func(p): return not p.cancelled and matches(e,p) and (not e.has("issues") and not e.has("affs") or has_damage(p)))

func can(id: String) -> bool:
	if done or b.hand.size() > 7 or b.outcome != null: return false
	var c = card(id)
	if c.get("chapter",1) > 1 or c.get("bad",false) or cost(c) > b.energy or c.get("once",false) and b.used.get(id,false): return false
	if c.type == "person" and (b.allies.size() >= 3 or b.allies.any(func(a): return a.id == id)): return false
	for e in c.effects:
		if e.op in ["cancel","delay"] and targets(e).is_empty(): return false
	var reducers = c.effects.filter(func(e): return e.op in ["reduceIssue","reduceAff"])
	if not reducers.is_empty() and not reducers.any(func(e): return b.plan.any(func(p): return not p.cancelled and matches(e,p) and has_damage(p,true))): return false
	return true

func target_effect(c: Dictionary):
	for e in c.effects:
		if e.op in ["cancel","delay"]: return e
	return null

func snap():
	history.append({"battle":b.duplicate(true),"seed":seed})

func undo(all_turn: bool = false):
	if history.is_empty() or done: return
	var previous = history[0] if all_turn else history.back()
	b = previous.battle.duplicate(true)
	seed = int(previous.seed)
	if all_turn: history.clear()
	else: history.pop_back()
	events.clear()

func reporter_draw():
	if b.used.get("reporterDraw",false): return
	b.used.reporterDraw = true
	draw(1)

func changed():
	if b.get("currentCard") != null:
		for a in active("planDraw"): train(a.id)
	if not active("planDraw").is_empty() and b.used.get("planDraw",0) < 1:
		b.used.planDraw = b.used.get("planDraw",0) + 1
		reporter_draw()

func train(id: String):
	if not b.has("growth"): b.growth = {}
	if not b.growth.has(id): b.growth[id] = {"progress":0,"level":0}
	var g = b.growth[id]
	if g.level: return
	g.progress += 1
	if g.progress >= data.growth[id]:
		g.level = 1
		events.append({"kind":"growth","name":card(id).name})
		say(card(id).name + "が成長！")
		match id:
			"official": b.block += 5
			"leader": b.boost += 3
			"reporter": reporter_draw()
			"economist": b.nextBlock += 2
			"organizer": b.hp = mini(30,b.hp+3)
			"broker": b.protect += 1

func effect(e: Dictionary, uid):
	match e.op:
		"damage":
			var bonus = 0
			if e.get("condition","") == "scandal" and b.plan.any(func(p): return p.get("issue") == "scandal" and not p.cancelled): bonus = e.get("bonus",0)
			if e.get("condition","") == "business" and b.counts.get("business",0) >= 2: bonus = e.get("bonus",0)
			if e.get("condition","") == "community" and b.allies.any(func(a): return card(a.id).aff == "community" and a.disabledUntil < b.turn): bonus = e.get("bonus",0)
			if b.currentCost >= 2 and b.allies.any(func(a): return a.disabledUntil < b.turn and card(a.id).aff == b.currentAff and b.get("growth",{}).get(a.id,{}).get("level",0) > 0): bonus += 4
			var n = e.n + bonus + b.boost
			b.boost = 0
			var blocked = minf(n,b.enemyBlock)
			b.enemyBlock -= blocked
			b.enemyHP = maxf(0,b.enemyHP-n+blocked)
		"block": b.block += e.n
		"draw": draw(e.n)
		"heal": b.hp = mini(30,b.hp+e.n)
		"boost": b.boost += e.n
		"energy": b.energy += e.n
		"protect": b.protect += e.n
		"invest": b.invest += e.n
		"nextDraw": b.nextDraw += e.n
		"burden":
			for i in range(e.n): b.discard.append("burden")
		"scandal":
			for i in range(e.n): b.enemyPile.append({"id":"scandal","name":"疑惑追及","issue":"scandal","aff":"noir","cost":1,"effects":[{"op":"damage","n":5}]})
			b.enemyPile = shuffled(b.enemyPile)
		"cancel", "delay":
			for p in b.plan:
				if p.uid == uid:
					p.cancelled = true
					if e.op == "delay": b.deferred.append(p.duplicate(true))
					changed()
		"reduceAff", "reduceIssue":
			var count = 0
			for p in b.plan:
				if not p.cancelled and matches(e,p):
					for x in p.effects:
						if x.op == "damage":
							x.n = maxf(0,x.n-e.n)
							count += 1
			if count: changed()
		"reverse":
			b.plan.reverse()
			changed()
		"clean":
			var count = int(e.n)
			for zone in ["hand","discard","pile"]:
				var cleaned: Array = []
				for id in b[zone]:
					if count > 0 and card(id).get("bad",false): count -= 1
					else: cleaned.append(id)
				b[zone] = cleaned
		"recover":
			if not b.removed.is_empty(): b.hand.append(b.removed.pop_back())
			else: draw(1)

func play(index: int, uid = null) -> bool:
	if index < 0 or index >= b.hand.size(): return false
	var id = b.hand[index]
	if not can(id): return false
	var c = card(id)
	var target = target_effect(c)
	if target != null and not targets(target).any(func(p): return p.uid == uid): return false
	snap()
	events.clear()
	b.currentAff = c.aff
	b.currentCost = c.cost
	b.currentCard = id
	var n = cost(c)
	b.energy -= n
	b.hand.remove_at(index)
	if c.aff == "politics" and c.type != "person" and b.discount: b.discount = false
	if c.type == "disrupt" and not active("disruptDiscount").is_empty(): b.used.disruptDiscount = true
	b.used[id] = true
	if c.type != "person": b.counts[c.aff] = b.counts.get(c.aff,0) + 1
	if c.type == "person":
		b.allies.append({"id":id,"disabledUntil":0})
		if not b.has("growth"): b.growth = {}
		if not b.growth.has(id): b.growth[id] = {"progress":0,"level":0}
		b.block += 3
		if not active("deployDiscount").is_empty(): b.discount = true
	else: b.discard.append(id)
	for e in c.effects: effect(e,uid)
	if c.aff == "business" and not active("reserveBlock").is_empty() and not b.used.get("reserveBlock",false):
		b.nextBlock += 2
		b.used.reserveBlock = true
	if c.aff == "community" and not active("rescue").is_empty() and not b.used.get("communityHeal",false):
		b.hp = mini(30,b.hp+1)
		b.used.communityHeal = true
	if c.type != "person":
		for a in b.allies.duplicate():
			if a.disabledUntil < b.turn and card(a.id).aff == c.aff and a.id != "reporter": train(a.id)
	b.currentCard = null
	say(c.name + "を使用（%dコスト）。" % n)
	if b.enemyHP <= 0: b.outcome = "win"
	if c.type != "person":
		for a in b.allies:
			var grown = b.get("growth",{}).get(a.id,{}).get("level",0)
			if a.disabledUntil >= b.turn or not grown or card(a.id).aff != c.aff or b.used.get("grown_"+a.id,false) or a.id == "reporter" and c.type != "attack": continue
			b.used["grown_"+a.id] = true
			match a.id:
				"leader", "broker": b.boost += 2
				"reporter": reporter_draw()
				"economist": b.nextBlock += 1
				"organizer": b.hp = mini(30,b.hp+1)
	return true

func forecast() -> int:
	var total = 0
	for p in b.plan:
		if not p.cancelled:
			for e in p.effects:
				if e.op == "damage": total += int(e.n)
	return total

func discard_overflow(index: int):
	if done or b.outcome != null or b.hand.size() <= 7 or index < 0 or index >= b.hand.size(): return
	snap()
	b.discard.append(b.hand.pop_at(index))

func retire(id: String):
	if done or b.outcome != null: return
	for i in range(b.allies.size()):
		if b.allies[i].id == id:
			snap()
			b.allies.remove_at(i)
			b.removed.append(id)
			return

func end_turn():
	if done or b.hand.size() > 7 and b.outcome == null: return
	if b.outcome == "win":
		done = true
		result = "勝利"
		history.clear()
		return
	history.clear()
	b.lastPlayerDamage = maxf(0,b.get("enemyTurnStartHP",b.enemyHP)-b.enemyHP)
	b.enemyBlock = 0
	for p in b.plan:
		if p.cancelled: continue
		for e in p.effects:
			if e.op == "damage":
				var blocked = minf(b.block,e.n)
				b.block -= blocked
				b.hp = maxf(0,b.hp-e.n+blocked)
				say(p.name + "：%dダメージ。" % (e.n-blocked))
			elif e.op == "block": b.enemyBlock += e.n
			elif e.op in ["suppress","bounce"]:
				for a in b.allies.duplicate():
					if a.id != p.get("target"): continue
					if b.protect:
						b.protect -= 1
						say("人物干渉を防いだ。")
						break
					if e.op == "suppress": a.disabledUntil = b.turn + 1
					else:
						b.allies.erase(a)
						if not active("rescue").is_empty() and not b.used.get("rescue",false):
							b.nextDraw += 1
							b.used.rescue = true
						b.returnQueue.append(a.id)
					break
			if b.hp <= 0:
				done = true
				result = "敗北"
				return
	for p in b.plan:
		if p.get("delayed",false): continue
		for i in range(b.enemyHand.size()):
			if b.enemyHand[i].id == p.id:
				b.enemyDiscard.append(b.enemyHand.pop_at(i))
				break
	next_turn()

func snapshot() -> Dictionary:
	var out = b.duplicate(true)
	out.erase("log")
	out.erase("currentCard")
	out.erase("currentCost")
	out.erase("currentAff")
	return {"battle":out,"seed":seed}

func save_game(path: String):
	var f = FileAccess.open(path,FileAccess.WRITE)
	if f: f.store_string(JSON.stringify({"schema":1,"battle":b,"seed":seed,"initial_seed":initial_seed,"history":history,"done":done,"result":result}))

func load_game(path: String) -> bool:
	if not FileAccess.file_exists(path): return false
	var x = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not x is Dictionary or x.get("schema") != 1 or not x.get("battle") is Dictionary: return false
	if not x.battle.get("hand") is Array or not x.battle.has("plan"): return false
	for zone in ["hand","pile","discard","removed"]:
		for id in x.battle.get(zone,[]):
			if not data.cards.has(id) or card(id).get("chapter",1) > 1: return false
	b = x.battle
	seed = int(x.seed)
	initial_seed = int(x.initial_seed)
	history = x.get("history",[])
	done = x.get("done",false)
	result = x.get("result","")
	return true
