extends Node
## Animation / choreography test (headless). godot --headless --path . --max-fps 0 --fixed-fps 60 res://tools/ArteTest.tscn
var _ok := 0
var _fails := 0
func check(c: bool, what: String) -> void:
	if c:
		_ok += 1
	else:
		_fails += 1
		print("  [FAIL] ", what)

func _ready() -> void:
	var root := get_tree().root
	get_parent().call_deferred("remove_child", self)
	root.call_deferred("add_child", self)
	await get_tree().process_frame
	_anim_names()
	for cid in ["lloyd", "colette", "genis", "raine", "kratos"]:
		await _artes_of(cid)
	await _interrupt()
	await _victory()
	print("ARTE TEST DONE: %d passed, %d failed" % [_ok, _fails])
	get_tree().quit(1 if _fails > 0 else 0)

func _anim_names() -> void:
	print("== animation names used by data")
	var lib := CharacterModel.get_anim_library()
	for id in DB.artes:
		var a: Dictionary = DB.artes[id]
		if a.has("anim"):
			check(lib.has_animation(a["anim"]), "arte %s anim %s exists" % [id, a["anim"]])
		for st in a.get("moves", []):
			check(lib.has_animation(st["anim"]), "arte %s step anim %s exists" % [id, st["anim"]])
	for n in ["Sword_Idle", "Jog_Fwd", "Hit_Chest", "Hit_Knockback", "Death01", "Sword_Block", "Spell_Simple_Idle", "Spell_Simple_Enter", "Spell_Simple_Shoot", "Yes", "LayToIdle", "Idle_FoldArms", "Spell_Simple_Exit", "Walk", "Idle"]:
		check(lib.has_animation(n), "core anim %s exists" % n)

func _wait(pred: Callable, frames := 600) -> bool:
	for i in frames:
		await get_tree().physics_frame
		if pred.call():
			return true
	return false

func _battle(party: Array, enemies: Array, level: int) -> BattleManager:
	while Router._busy:
		await get_tree().process_frame
	get_tree().change_scene_to_file("res://tools/Blank.tscn")
	await get_tree().process_frame
	await get_tree().process_frame
	Game.new_game()
	Game.set_party(party)
	for id in Game.members:
		var m: Dictionary = Game.members[id]
		m["level"] = max(level, int(m["level"]))
		m["artes"] = Game._artes_known(id, int(m["level"]))
		m["hp"] = Game.max_hp(id)
		m["tp"] = Game.max_tp(id)
	var old := get_tree().current_scene
	Router.start_battle({"enemies": enemies, "advantage": "normal", "map": "iselia_forest"})
	await _wait(func(): return get_tree().current_scene != old and get_tree().current_scene is BattleManager and (get_tree().current_scene as BattleManager).phase == BattleManager.Phase.FIGHT, 900)
	var bm: BattleManager = get_tree().current_scene
	return bm

func _artes_of(cid: String) -> void:
	print("== artes of ", cid)
	var bm := await _battle([cid, "genis"] if cid != "genis" else ["genis", "lloyd"], ["golem"], 30)
	if bm == null:
		check(false, "battle for " + cid)
		return
	var b: PlayerBattler = bm.party[0]
	var foe: EnemyBattler = bm.enemies[0]
	for id in b.known_artes:
		var a: Dictionary = DB.artes[id]
		foe.stats["hp"] = 999999
		foe.stats["max_hp"] = 999999
		foe.ai_cooldown = 999.0
		foe.state = Battler.State.IDLE
		foe.velocity = Vector3.ZERO
		b.state = Battler.State.IDLE
		b.action_timer = 0.0
		b.pending_hits.clear()
		b.global_position = Vector3(-2.0, 0, 0)
		b.set_facing(1)
		foe.global_position = Vector3(-0.3 if a.get("type", "base") in ["base", "master"] and not a.has("projectile") else 3.0, 0, 0)
		b.target = foe
		b.stats["tp"] = b.stats["max_tp"]
		var ally: Battler = bm.party[1]
		ally.stats["hp"] = int(ally.stats["max_hp"] * 0.3)
		b.target_ally = ally
		var hp_foe := int(foe.stats["hp"])
		var hp_ally := int(ally.stats["hp"])
		var t0 := Engine.get_physics_frames()
		check(b.use_arte(id), "%s can use %s" % [cid, id])
		var max_y := 0.0
		var done := false
		for i in 600:
			await get_tree().physics_frame
			max_y = max(max_y, b.model.position.y)
			if b.state == Battler.State.IDLE or b.state == Battler.State.MOVE:
				done = true
				break
		var secs := float(Engine.get_physics_frames() - t0) / 60.0
		check(done, "%s/%s finishes (%.2fs)" % [cid, id, secs])
		await _wait(func(): return foe.stats["hp"] < hp_foe or ally.stats["hp"] > hp_ally, 180)
		var kind: String = a.get("type", "base")
		if kind == "heal":
			check(ally.stats["hp"] > hp_ally, "%s/%s heals the ally" % [cid, id])
		elif kind == "support":
			check(not ally.buffs.is_empty() or not b.buffs.is_empty() or not bm.controlled.buffs.is_empty(), "%s/%s applies a buff" % [cid, id])
		else:
			check(foe.stats["hp"] < hp_foe, "%s/%s deals damage (%d)" % [cid, id, hp_foe - int(foe.stats["hp"])])
		check(abs(b.model.position.y) < 0.001, "%s/%s lands back on the ground (y=%.3f)" % [cid, id, b.model.position.y])
		var expect_rot := -PI / 2 if b.facing > 0 else PI / 2
		check(abs(wrapf(b.model.rotation.y - expect_rot, -PI, PI)) < 0.01, "%s/%s ends facing the enemy line" % [cid, id])
		check(Vector2(b.global_position.x, b.global_position.z).length() <= bm.arena_radius, "%s/%s stays inside the arena" % [cid, id])
		if DB.artes[id].has("moves"):
			for st in DB.artes[id]["moves"]:
				if float(st.get("jump", 0.0)) > 0.5:
					check(max_y > 0.5, "%s/%s actually jumps (peak %.2f m)" % [cid, id, max_y])
					break
		print("  %s %-14s %.2fs  peak %.2fm" % [cid, id, secs, max_y])

func _interrupt() -> void:
	print("== interrupted arte")
	var bm := await _battle(["lloyd", "genis"], ["golem"], 30)
	var b: PlayerBattler = bm.party[0]
	var foe: EnemyBattler = bm.enemies[0]
	foe.ai_cooldown = 999.0
	b.global_position = Vector3(-2, 0, 0)
	foe.global_position = Vector3(-0.3, 0, 0)
	b.target = foe
	b.stats["tp"] = b.stats["max_tp"]
	check(b.use_arte("tempest"), "tempest starts")
	for i in 30:
		await get_tree().physics_frame
	check(b.model.position.y > 0.3, "in the air mid-Tempest")
	b.take_hit(foe, 10, 2.0, false, false, false)
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(abs(b.model.position.y) < 0.001, "interrupted Tempest drops Lloyd back to the ground")
	check(b._ch.is_empty(), "choreography cancelled")

func _victory() -> void:
	print("== victory poses and quotes")
	var bm := await _battle(["lloyd", "colette", "genis", "kratos"], ["wolf"], 5)
	for e in bm.enemies:
		e.take_hit(null, 9999999, 0.0, false, true, false)
	await _wait(func(): return bm.phase == BattleManager.Phase.WIN, 200)
	await _wait(func(): return bm.last_victory_quote != "", 120)
	check(bm.last_victory_quote != "", "a victory quote is shown (%s)" % bm.last_victory_quote)
	for p in bm.party:
		check(p.state == Battler.State.WIN, "%s strikes a victory pose" % p.id)
	await get_tree().create_timer(0.6).timeout
	var lloyd: PlayerBattler = bm.party[0]
	check(lloyd.model.current() in ["Sword_Regular_A", "Sword_Idle", "Yes"], "Lloyd's victory sequence plays (%s)" % lloyd.model.current())
