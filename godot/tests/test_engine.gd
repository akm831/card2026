extends SceneTree
const EngineCore = preload("res://scripts/battle_engine.gd")
var errors: int = 0
func _initialize():
	var fixtures = JSON.parse_string(FileAccess.get_file_as_string("res://tests/parity_fixtures.json"))
	var comparisons = 0
	for fixture in fixtures:
		var game = EngineCore.new()
		for step in fixture.steps:
			match step.op:
				"start": game.start(fixture.type,fixture.soft,int(fixture.seed))
				"play":
					if not game.play(int(step.index),step.uid): fail("Illegal port action",fixture,step)
				"undo": game.undo()
				"discard": game.discard_overflow(int(step.index))
				"end": game.end_turn()
			comparisons += 1
			var actual = JSON.parse_string(JSON.stringify(game.snapshot()))
			if actual != step.expected:
				fail("State differs at comparison %d" % comparisons,fixture,step)
				for key in step.expected.battle:
					if actual.battle.get(key) != step.expected.battle.get(key): print(key, " actual: ", actual.battle.get(key), " expected: ",step.expected.battle.get(key))
				print("seed actual: ",actual.seed," expected: ",step.expected.seed)
				var f = FileAccess.open("user://parity_failure.json",FileAccess.WRITE)
				f.store_string(JSON.stringify({"actual":actual,"expected":step.expected},"  "))
				quit(1)
				return
	# Snapshot restoration also retains RNG, history and confirmation state.
	var game = EngineCore.new()
	game.start("admin","finance",123)
	game.save_game("user://test_save.json")
	var restored = EngineCore.new()
	if not restored.load_game("user://test_save.json") or JSON.parse_string(JSON.stringify(restored.snapshot())) != JSON.parse_string(JSON.stringify(game.snapshot())):
		push_error("Save roundtrip failed")
		errors += 1
	print("PASS: %d HTML/Godot state comparisons across %d battles; save roundtrip." % [comparisons,fixtures.size()])
	quit(1 if errors else 0)
func fail(text,fixture,step):
	push_error("%s / %s / %s / seed %s / %s" % [text,fixture.type,fixture.soft,fixture.seed,step.op])
	errors += 1
