extends Node
## Headless assertions for every game system.  godot --headless --path . res://tools/SystemsTest.tscn
var _fails := 0
var _passes := 0

func check(cond: bool, what: String) -> void:
	if cond:
		_passes += 1
		print("  [PASS] ", what)
	else:
		_fails += 1
		print("  [FAIL] ", what)

func _ready() -> void:
	var root := get_tree().root
	get_parent().call_deferred("remove_child", self)
	root.call_deferred("add_child", self)
	await get_tree().process_frame
	await get_tree().process_frame
	_data()
	_shop()
	_equip()
	_items()
	_cooking()
	_titles()
	_ex()
	_save_load()
	await _battle()
	await _ui()
	print("SYSTEMS TEST DONE: %d passed, %d failed" % [_passes, _fails])
	get_tree().quit(1 if _fails > 0 else 0)

func _data() -> void:
	print("== data")
	check(DB.recipes.size() >= 10, "recipes loaded")
	check(DB.titles.size() >= 15, "titles loaded")
	check(DB.ex_skills.has("lloyd"), "ex skills loaded")
	check(DB.shops.has("iselia") and DB.shops.has("triet"), "shops loaded")
	for sid in DB.shops:
		for it in DB.shops[sid]["items"]:
			check(DB.items.has(it), "shop %s item %s exists" % [sid, it])
	for r in DB.recipes:
		for ing in DB.recipes[r]["ingredients"]:
			check(DB.items.has(ing), "recipe %s ingredient %s exists" % [r, ing])
	check(DB.story_script.size() == 83, "83 script scenes loaded")

func _shop() -> void:
	print("== shop")
	Game.new_game()
	var g := Game.gald
	check(Game.buy("apple_gel", 2), "buy 2 apple gels")
	check(Game.gald == g - 200, "gald charged 200")
	check(Game.item_count("apple_gel") == 5, "now 5 apple gels")
	check(Game.sell("apple_gel", 1), "sell 1")
	check(Game.gald == g - 150, "sold at half price")
	Game.gald = 10
	check(not Game.buy("steel_sword"), "cannot buy without gald")
	Game.add_item("sorcerers_ring", 1)
	check(not Game.sell("sorcerers_ring"), "cannot sell key items")

func _equip() -> void:
	print("== equipment")
	Game.new_game()
	var atk0 := Game.stat("lloyd", "atk")
	Game.add_item("iron_sword", 1)
	check(Game.can_equip("lloyd", "iron_sword", "weapon"), "lloyd can equip iron sword")
	check(not Game.can_equip("genis", "iron_sword", "weapon"), "genis cannot equip iron sword")
	check(Game.equip("lloyd", "weapon", "iron_sword"), "equip iron sword")
	check(Game.stat("lloyd", "atk") == atk0 + 12, "atk +12 (22-10)")
	check(Game.has_item("wooden_blade"), "old weapon returned to bag")
	Game.add_item("talisman", 1)
	check(Game.equip("lloyd", "acc1", "talisman"), "equip accessory")
	Game.unequip("lloyd", "acc1")
	check(Game.has_item("talisman"), "unequip returns accessory")
	check(not Game.can_equip("lloyd", "talisman", "weapon"), "accessory not weapon")

func _items() -> void:
	print("== items")
	Game.new_game()
	Game.members["lloyd"]["hp"] = 10
	check(Game.use_item("apple_gel", "lloyd"), "use apple gel")
	check(int(Game.members["lloyd"]["hp"]) > 10, "hp restored")
	check(not Game.use_item("life_bottle", "lloyd"), "no life bottle in bag")
	Game.add_item("life_bottle", 1)
	check(not Game.use_item("life_bottle", "lloyd"), "life bottle on living ally fails")
	Game.members["genis"]["hp"] = 0
	check(Game.use_item("life_bottle", "genis"), "revive genis")
	check(int(Game.members["genis"]["hp"]) > 0, "genis alive")

func _cooking() -> void:
	print("== cooking")
	Game.new_game()
	check(not Game.cook("sandwich", "genis")["ok"], "cannot cook unknown recipe")
	check(Game.learn_recipe("sandwich"), "learn sandwich")
	check(not Game.can_cook("sandwich"), "no ingredients yet")
	var oks := 0
	for i in 12:
		Game.add_item("bread", 1)
		Game.add_item("lettuce", 1)
		Game.add_item("tomato", 1)
		Game.members["lloyd"]["hp"] = 1
		var r: Dictionary = Game.cook("sandwich", "genis")
		if r["ok"]:
			oks += 1
	check(oks >= 6, "genis (best cook) succeeds most of the time (%d/12)" % oks)
	check(not Game.has_item("bread"), "ingredients consumed")
	check(Game.cook_skill("genis", "sandwich") == oks, "cooking skill tracked")
	check(Game.get_flag("cook_10", false) == (oks >= 10), "cook_10 flag")

func _titles() -> void:
	print("== titles")
	Game.new_game()
	check((Game.members["lloyd"]["titles"] as Array).has("lloyd_drifting"), "start title")
	Game.set_flag("exiled", true)
	check((Game.members["lloyd"]["titles"] as Array).has("lloyd_exiled"), "title earned by flag")
	var atk := Game.stat("lloyd", "atk")
	Game.set_title("lloyd", "lloyd_exiled")
	check(Game.stat("lloyd", "atk") >= atk, "title modifies stats")

func _ex() -> void:
	print("== EX skills")
	Game.new_game()
	var hp := Game.max_hp("lloyd")
	check(not Game.set_ex_gem("lloyd", 1, "tough"), "no gem -> cannot set")
	Game.add_item("ex_gem_1", 1)
	check(Game.set_ex_gem("lloyd", 1, "tough"), "set Tough")
	check(Game.max_hp("lloyd") > hp, "Tough raises max HP")
	check(not Game.has_item("ex_gem_1"), "gem consumed")
	check(Game.set_ex_gem("lloyd", 1, ""), "remove gem")
	check(Game.has_item("ex_gem_1"), "gem returned")

func _save_load() -> void:
	print("== save/load")
	Game.new_game()
	Game.learn_recipe("omelet")
	Game.gald = 1234
	Game.set_flag("temple_done", true)
	Game.save(9)
	Game.new_game()
	check(Game.load_save(9), "load slot 9")
	check(Game.gald == 1234, "gald restored")
	check(Game.recipes.has("omelet"), "recipes restored")
	check(Game.get_flag("temple_done", false), "flags restored")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://save_9.json"))

func _battle() -> void:
	print("== battle")
	Game.new_game()
	Router.start_battle({"enemies": ["wolf", "wolf"], "advantage": "normal", "map": "iselia_forest"})
	var bm: BattleManager = null
	for i in 240:
		await get_tree().process_frame
		if get_tree().current_scene is BattleManager and (get_tree().current_scene as BattleManager).phase == BattleManager.Phase.FIGHT:
			bm = get_tree().current_scene
			break
	check(bm != null, "battle reached FIGHT")
	if bm == null:
		return
	var lloyd: PlayerBattler = bm.party[0]
	# Over Limit
	lloyd.add_ol(150.0)
	check(lloyd.in_over_limit(), "over limit triggers at 100")
	var atk_base := float(lloyd.stats["atk"])
	check(lloyd.stat("atk") > atk_base, "over limit boosts atk")
	# Unison
	bm.unison_gauge = 100.0
	var hp_before := 0
	for e in bm.enemies:
		hp_before += int(e.stats["hp"])
	bm.try_unison()
	check(bm.phase == BattleManager.Phase.UNISON, "unison phase entered")
	for i in 360:
		await get_tree().process_frame
		if bm.phase != BattleManager.Phase.UNISON:
			break
	var hp_after := 0
	for e in bm.enemies:
		hp_after += int(e.stats["hp"])
	check(hp_after < hp_before, "unison dealt damage (%d -> %d)" % [hp_before, hp_after])
	check(bm.unison_gauge == 0.0, "unison gauge consumed")
	# Item in battle
	lloyd.stats["hp"] = 5
	var gels := Game.item_count("apple_gel")
	check(bm.hud._apply_item("apple_gel", lloyd), "battle item applied")
	check(int(lloyd.stats["hp"]) > 5, "battle item healed")
	check(Game.item_count("apple_gel") == gels - 1, "battle item consumed")
	# Win
	for e in bm.enemies:
		if e.is_alive():
			e.take_hit(null, 999999, 0.0, false, true, false)
	for i in 300:
		await get_tree().process_frame
		if bm.phase == BattleManager.Phase.WIN:
			break
	check(bm.phase == BattleManager.Phase.WIN, "battle won")

func _tap(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
	for i in 3:
		await get_tree().process_frame

func _ui() -> void:
	print("== UI (real input)")
	Game.new_game()
	for f in ["oracle_seen", "frank_talked", "temple_done", "colette_house_done"]:
		Game.set_flag(f, true)
	Game.set_party(["lloyd", "genis"])
	Router.goto_map("iselia_village", "from_forest")
	var f: Field = null
	for i in 300:
		await get_tree().process_frame
		var sc := get_tree().current_scene
		if sc is Field and (sc as Field).map_id == "iselia_village" and (sc as Field).player and (sc as Field).player.can_move:
			f = sc
			break
	check(f != null, "field ready")
	if f == null:
		return
	# --- shop: Comprar -> first item (apple gel) -> back -> exit
	var gels := Game.item_count("apple_gel")
	var g := Game.gald
	var done := [false]
	(func(): await f.open_shop("iselia"); done[0] = true).call()
	await _tap("confirm")
	await _tap("confirm")
	await _tap("cancel")
	await _tap("cancel")
	for i in 30:
		await get_tree().process_frame
	check(done[0], "shop closed with cancel")
	check(Game.item_count("apple_gel") == gels + 1 and Game.gald == g - 100, "bought an apple gel through the shop UI")
	# --- pause menu: Cocina -> sandwich -> Genis
	Game.learn_recipe("sandwich")
	for it in ["bread", "lettuce", "tomato"]:
		Game.add_item(it, 1)
	var done2 := [false]
	(func(): await f._pause.open(); done2[0] = true).call()
	await get_tree().process_frame
	for i in 3:
		await _tap("move_down")
	await _tap("confirm")   # Cocina
	await _tap("confirm")   # sandwich
	await _tap("move_down") # genis (party: lloyd, genis)
	await _tap("confirm")   # cook
	check(not Game.has_item("bread"), "cooked through the pause menu (ingredients used)")
	await _tap("cancel")
	await _tap("cancel")
	for i in 30:
		await get_tree().process_frame
	check(done2[0], "pause menu closed")
	# --- Sorcerer's Ring stuns a monster in front of the player
	Game.add_item("sorcerers_ring", 1)
	var m := FieldMonster.new()
	m.setup(f, ["wolf"], 99)
	f.add_child(m)
	var fwd := Vector3(sin(f.player.rotation.y), 0, cos(f.player.rotation.y))
	m.global_position = f.player.global_position + fwd * 4.0
	m.wander_center = m.global_position
	await get_tree().physics_frame
	await _tap("arte")
	var stunned := false
	for i in 90:
		await get_tree().physics_frame
		if m.stun_t > 0:
			stunned = true
			break
	check(stunned, "ring fireball stuns the monster")
	m.queue_free()
