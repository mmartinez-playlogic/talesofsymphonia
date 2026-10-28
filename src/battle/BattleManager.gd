class_name BattleManager
extends Node3D
## Orchestrates one battle: arena, spawning, phases, targeting helpers, spells, results.

enum Phase { INTRO, FIGHT, WIN, LOSE, MENU, UNISON }

var phase: Phase = Phase.INTRO
var arena_radius := 14.0
var party: Array[PlayerBattler] = []
var enemies: Array[EnemyBattler] = []
var controlled: PlayerBattler
var hud: BattleHUD
var camera: BattleCamera
var encounter: Dictionary = {}
var _fx_root: Node3D
var _results_ready := false
var _elapsed := 0.0
var _damage_taken := 0
var _kos := 0
var unison_gauge := 0.0        # 0..100, fills with party hits
var _max_combo := 0

func _ready() -> void:
	encounter = Router.consume_pending_battle()
	if encounter.is_empty():
		encounter = {"enemies": ["wolf", "wolf"], "advantage": "normal"}
	_build_arena()
	_fx_root = Node3D.new()
	add_child(_fx_root)
	hud = BattleHUD.new()
	hud.manager = self
	add_child(hud)
	camera = BattleCamera.new()
	camera.manager = self
	add_child(camera)
	_spawn_party()
	_spawn_enemies()
	camera.global_position = Vector3(0, 4, 14)
	camera.current = true
	phase = Phase.INTRO
	var adv: String = encounter.get("advantage", "normal")
	hud.show_center("¡A luchar!" if adv == "normal" else ("¡Ataque sorpresa!" if adv == "player" else "¡Emboscada!"), 1.0)
	await get_tree().create_timer(0.9).timeout
	phase = Phase.FIGHT

func _build_arena() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var mat := ProceduralSkyMaterial.new()
	mat.sky_top_color = Color(0.25, 0.45, 0.85)
	mat.sky_horizon_color = Color(0.75, 0.85, 0.95)
	mat.ground_bottom_color = Color(0.2, 0.25, 0.2)
	mat.ground_horizon_color = Color(0.6, 0.7, 0.6)
	sky.sky_material = mat
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.7
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 20, 0)
	sun.light_energy = 1.4
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 60
	sun.shadow_blur = 2.0
	add_child(sun)
	# ground disc
	var ground := StaticBody3D.new()
	ground.collision_layer = 16
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = arena_radius + 20
	cm.bottom_radius = arena_radius + 20
	cm.height = 0.2
	cm.radial_segments = 32
	mi.mesh = cm
	mi.position.y = -0.1
	mi.set_surface_override_material(0, ToonMaterial.make(Color(0.32, 0.56, 0.28), false))
	ground.add_child(mi)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200, 0.2, 200)
	cs.shape = box
	cs.position.y = -0.1
	ground.add_child(cs)
	add_child(ground)
	# arena ring marker
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = arena_radius - 0.15
	tm.outer_radius = arena_radius
	tm.rings = 48
	tm.ring_segments = 4
	ring.mesh = tm
	ring.position.y = 0.02
	ring.set_surface_override_material(0, ToonMaterial.make(Color(0.75, 0.7, 0.5), false))
	add_child(ring)
	# scattered trees around for depth
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 26:
		var a := rng.randf_range(0, TAU)
		var r := rng.randf_range(arena_radius + 4, arena_radius + 16)
		var pos := Vector3(cos(a) * r, 0, sin(a) * r)
		if pos.z > 6:
			continue
		_tree(pos, rng.randf_range(0.9, 1.6))

func _tree(pos: Vector3, s: float) -> void:
	var trunk := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.2 * s
	cm.bottom_radius = 0.3 * s
	cm.height = 2.4 * s
	trunk.mesh = cm
	trunk.set_surface_override_material(0, ToonMaterial.make(Color(0.36, 0.24, 0.14), true, 0.02))
	trunk.position = pos + Vector3(0, 1.2 * s, 0)
	add_child(trunk)
	for i in 2:
		var leaves := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = (1.7 - i * 0.4) * s
		sm.height = sm.radius * 1.6
		sm.radial_segments = 10
		sm.rings = 6
		leaves.mesh = sm
		leaves.set_surface_override_material(0, ToonMaterial.make(Color(0.17, 0.5, 0.22).lightened(i * 0.1), true, 0.03))
		leaves.position = pos + Vector3(0, (2.6 + i * 1.0) * s, 0)
		add_child(leaves)

func _spawn_party() -> void:
	var adv: String = encounter.get("advantage", "normal")
	var n := Game.party.size()
	for i in n:
		var cid: String = Game.party[i]
		var b := PlayerBattler.new()
		b.manager = self
		add_child(b)
		b.setup_from_member(cid)
		var x: float = -5.0 - i * 1.6
		var z: float = (i - (n - 1) / 2.0) * 1.4
		if adv == "enemy":
			x = -1.0 - i * 1.2
		b.global_position = Vector3(x, 0, z)
		b.set_facing(1)
		b.died.connect(_on_battler_died)
		party.append(b)
		hud.add_party_member(b)
	controlled = party[0]
	controlled.controlled = true
	for b in party:
		b.target = null

func _spawn_enemies() -> void:
	var adv: String = encounter.get("advantage", "normal")
	var ids: Array = encounter.get("enemies", ["wolf"])
	var n := ids.size()
	for i in n:
		var b := EnemyBattler.new()
		b.manager = self
		add_child(b)
		b.setup_from_data(ids[i])
		var x: float = 5.0 + i * 1.8
		var z: float = (i - (n - 1) / 2.0) * 1.6
		if adv == "player":
			x = 2.0 + i * 1.4
		b.global_position = Vector3(x, 0, z)
		b.set_facing(-1)
		b.died.connect(_on_battler_died)
		if adv == "player":
			b.ai_cooldown = 2.0
		enemies.append(b)
	for b in party:
		b.target = nearest_opponent(b)

# ---------- queries ----------
func opponents_of(b: Battler) -> Array:
	return enemies if b.player_side else party

func allies_of(b: Battler) -> Array:
	return party if b.player_side else enemies

func nearest_opponent(b: Battler) -> Battler:
	var best: Battler = null
	var bd := INF
	for o in opponents_of(b):
		if not o.is_alive():
			continue
		var d: float = o.global_position.distance_to(b.global_position)
		if d < bd:
			bd = d
			best = o
	return best

func random_opponent(b: Battler) -> Battler:
	var alive: Array = opponents_of(b).filter(func(o): return o.is_alive())
	if alive.is_empty():
		return null
	# enemies prefer the controlled character slightly
	if not b.player_side and controlled and controlled.is_alive() and randf() < 0.45:
		return controlled
	return alive[randi() % alive.size()]

func next_opponent(b: Battler, current: Battler) -> Battler:
	var alive: Array = opponents_of(b).filter(func(o): return o.is_alive())
	if alive.is_empty():
		return null
	var idx: int = alive.find(current)
	return alive[(idx + 1) % alive.size()]

func lowest_hp_ally(b: Battler) -> Battler:
	var best: Battler = null
	var br := 2.0
	for a in allies_of(b):
		if a.is_alive() and a.hp_ratio() < br:
			br = a.hp_ratio()
			best = a
	return best

# ---------- events ----------
var debug_log := false

func on_damage(attacker: Battler, victim: Battler, dmg: int, crit: bool) -> void:
	if debug_log:
		print("[DMG] f%d %s -> %s %d (hp %d/%d)" % [Engine.get_physics_frames(), attacker.id if attacker else "?", victim.id, dmg, victim.stats["hp"], victim.stats["max_hp"]])
	var color := Color(1, 1, 1)
	if victim.player_side:
		color = Color(1, 0.4, 0.4)
		_damage_taken += dmg
	elif crit:
		color = Color(1, 0.9, 0.3)
	spawn_popup(victim.global_position + Vector3(randf_range(-0.3, 0.3), 1.7, 0.4), str(dmg), color, 1.3 if crit else 1.0)
	if attacker and attacker.player_side:
		hud.register_hit(dmg)
		if phase == Phase.FIGHT:
			unison_gauge = min(100.0, unison_gauge + 4.0)
		_max_combo = max(_max_combo, hud.combo_hits())
	if crit:
		camera.shake(0.12)
	Effects.flash(_fx_root, victim.global_position + Vector3(0, 1.0, 0.3), Color(1, 1, 1, 0.8), 0.25)

func spawn_popup(pos: Vector3, text: String, color: Color, scale_f := 1.0) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = int(72 * scale_f)
	l.outline_size = 16
	l.modulate = color
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.position = pos
	_fx_root.add_child(l)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(l, "position:y", pos.y + 1.2, 0.7).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "modulate:a", 0.0, 0.7).set_delay(0.3)
	t.chain().tween_callback(l.queue_free)

func announce_arte(b: Battler, name: String) -> void:
	if b.player_side:
		hud.announce_arte(name)
	spawn_popup(b.global_position + Vector3(0, 2.2, 0), name, Color(0.9, 0.95, 1.0), 0.6)

func show_cast_circle(b: Battler, duration: float) -> void:
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.9
	tm.outer_radius = 1.05
	tm.rings = 32
	tm.ring_segments = 4
	mi.mesh = tm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.6, 0.8, 1.0, 0.9)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = m
	mi.position = Vector3(0, 0.05, 0)
	b.add_child(mi)
	var t := create_tween()
	t.tween_property(mi, "rotation:y", TAU * 2, duration)
	t.tween_callback(mi.queue_free)

func spawn_projectile(b: Battler, arte: Dictionary) -> void:
	var p := Projectile.new()
	_fx_root.add_child(p)
	p.global_position = b.global_position + Vector3(b.facing * 0.8, 0, 0)
	p.setup(b, arte)

## Resolve a cast spell/heal/support at its target(s).
func resolve_spell(caster: PlayerBattler, a: Dictionary) -> void:
	var kind: String = a.get("type", "spell")
	var elem: String = a.get("element", "none")
	var color := Effects.element_color(elem)
	match kind:
		"heal":
			var targets: Array = []
			if a.get("target", "ally") == "all_allies":
				targets = allies_of(caster).filter(func(x): return x.is_alive())
			else:
				var t: Battler = caster.target_ally if caster.target_ally and is_instance_valid(caster.target_ally) else lowest_hp_ally(caster)
				if t:
					targets = [t]
			for t in targets:
				t.heal(int(t.stats["max_hp"] * float(a.get("heal", 0.3))))
				Effects.pillar(_fx_root, t.global_position, Color(0.6, 1.0, 0.7), 3.5, 0.6)
			caster.target_ally = null
		"support":
			var t: Battler = caster.target_ally if caster.target_ally else controlled
			var buff: Dictionary = a.get("buff", {})
			for k in buff:
				if k != "duration":
					t.apply_buff(k, float(buff[k]), float(buff.get("duration", 20)))
			Effects.ring(_fx_root, t.global_position, Color(0.9, 0.9, 0.5), 2.0, 0.6)
		_:
			var t: Battler = caster.target if caster.target and is_instance_valid(caster.target) and caster.target.is_alive() else nearest_opponent(caster)
			if t == null:
				return
			var hits := int(a.get("hits", 1))
			var power := float(a.get("power", 1.0))
			var pos := t.global_position
			match elem:
				"fire":
					for h in hits:
						caster.schedule_hit(h * 0.18, func():
							if t.is_alive():
								Effects.fire_burst(_fx_root, t.global_position, color, 3, 0.5)
								caster.deal_magic(t, power / hits, elem, 0.6)
						)
				"earth":
					Effects.ring(_fx_root, pos, color, 2.5, 0.5)
					for h in hits:
						caster.schedule_hit(0.1 + h * 0.15, func():
							if t.is_alive():
								Effects.pillar(_fx_root, t.global_position + Vector3(randf_range(-0.6, 0.6), 0, 0), color, 2.0, 0.35)
								caster.deal_magic(t, power / hits, elem, 0.5)
						)
				"lightning":
					Effects.pillar(_fx_root, pos, color, 8.0, 0.35)
					camera.shake(0.1)
					caster.schedule_hit(0.05, func():
						if t.is_alive():
							caster.deal_magic(t, power, elem, 1.0)
					)
				"light":
					Effects.flash(_fx_root, pos + Vector3(0, 1, 0), color, 1.2)
					for h in hits:
						caster.schedule_hit(0.05 + h * 0.12, func():
							if t.is_alive():
								caster.deal_magic(t, power / hits, elem, 0.6)
						)
				_:
					for h in hits:
						caster.schedule_hit(h * 0.15, func():
							if t.is_alive():
								Effects.fire_burst(_fx_root, t.global_position, color, 2, 0.4)
								caster.deal_magic(t, power / hits, elem, 0.8)
						)

## Unison Attack: freeze enemies and have every living party member fire an arte at the controlled target.
func try_unison() -> void:
	if phase != Phase.FIGHT or unison_gauge < 100.0:
		return
	var t: Battler = controlled.target if controlled.target and is_instance_valid(controlled.target) and controlled.target.is_alive() else nearest_opponent(controlled)
	if t == null:
		return
	unison_gauge = 0.0
	phase = Phase.UNISON
	hud.show_center("¡UNISON ATTACK!", 1.2)
	camera.shake(0.2)
	for e in enemies:
		e.hitstun = 0.0
		e.velocity = Vector3.ZERO
	await get_tree().create_timer(0.5).timeout
	for b in party:
		if not b.is_alive() or b.known_artes.is_empty():
			continue
		b.target = t
		b.state = Battler.State.IDLE
		b.action_timer = 0.0
		b.pending_hits.clear()
		var arte_id: String = b.arte_shortcuts[0] if b.arte_shortcuts.size() > 0 else b.known_artes[0]
		var a: Dictionary = DB.artes.get(arte_id, {})
		var saved_tp: int = int(b.stats["tp"])
		b.stats["tp"] = max(int(b.stats["tp"]), int(a.get("tp", 0)))  # unison artes are free
		if a.get("type", "base") in ["spell", "heal", "support", "angel"]:
			# instant cast during unison
			announce_arte(b, a.get("name", arte_id))
			resolve_spell(b, a)
		else:
			b.use_arte(arte_id)
		b.stats["tp"] = saved_tp
		await get_tree().create_timer(0.55).timeout
	await get_tree().create_timer(0.8).timeout
	if phase == Phase.UNISON:
		phase = Phase.FIGHT
		_check_end()

## Battle item menu (pauses the fight).
func open_item_menu() -> void:
	if phase != Phase.FIGHT:
		return
	phase = Phase.MENU
	await hud.item_menu(self)
	if phase == Phase.MENU:
		phase = Phase.FIGHT
		_check_end()

func _on_battler_died(b: Battler) -> void:
	if not b.player_side:
		_kos += 1
		var eb := b as EnemyBattler
		# fade the corpse away
		var t := create_tween()
		t.tween_interval(1.0)
		t.tween_property(eb.model, "scale", Vector3.ONE * 0.01, 0.4)
		t.tween_callback(func(): eb.visible = false)
	call_deferred("_check_end")

func _process(delta: float) -> void:
	if phase == Phase.FIGHT:
		_elapsed += delta
		if Input.is_action_just_pressed("menu"):
			open_item_menu()
	if phase == Phase.WIN and _results_ready and Input.is_action_just_pressed("confirm"):
		_results_ready = false
		for b in party:
			b.sync_back()
		Router.return_from_battle()
	if phase == Phase.LOSE and _results_ready and Input.is_action_just_pressed("confirm"):
		_results_ready = false
		Router.goto_scene("res://src/Main.tscn")

func _check_end() -> void:
	if phase != Phase.FIGHT:
		return
	if enemies.all(func(e): return not e.is_alive()):
		phase = Phase.WIN
		_win()
	elif party.all(func(p): return not p.is_alive()):
		phase = Phase.LOSE
		_lose()

func _win() -> void:
	for b in party:
		if b.is_alive():
			b.velocity = Vector3.ZERO
			b.play("win", 1.0, true)
	hud.show_center("¡Victoria!", 1.5)
	# rewards
	var exp_total := 0
	var gald := 0
	var drops: Array = []
	for e in enemies:
		exp_total += int(e.data.get("exp", 0))
		gald += int(e.data.get("gald", 0))
		for d in e.data.get("drops", []):
			if randf() < float(d[1]):
				drops.append(d[0])
				Game.add_item(d[0], 1)
	var gald_bonus := 1.0
	for b in party:
		gald_bonus = max(gald_bonus, 1.0 + float(b.ex.get("gald", 0.0)))
	gald = int(gald * gald_bonus)
	Game.gald += gald
	if _max_combo >= 10:
		Game.set_flag("combo_10", true)
	# grade: Symphonia-like: base + fast + no damage - KO
	var grade: float = 0.5 + (1.0 if _elapsed < 20.0 else 0.0) + (0.5 if _damage_taken == 0 else 0.0)
	Game.grade += grade
	var text := "[b]Resultados[/b]\n\n"
	text += "EXP: [color=#f0d070]%d[/color]    Gald: [color=#f0d070]%d[/color]    Grado: [color=#90d0ff]%.1f[/color]\n\n" % [exp_total, gald, grade]
	for b in party:
		var gained: Array = Game.grant_exp(b.id, exp_total)
		var line: String = "%s  Lv %d" % [b.display_name, Game.members[b.id]["level"]]
		if gained.size() > 0:
			line += "   [color=#80ff80]¡Subida de nivel!  +%d[/color]" % gained.size()
			b.stats["max_hp"] = Game.max_hp(b.id)
			b.stats["max_tp"] = Game.max_tp(b.id)
			var new_artes: Array = Game.members[b.id]["artes"].filter(func(x): return not b.known_artes.has(x))
			for na in new_artes:
				line += "\n     [color=#a0c0ff]Nueva arte: %s[/color]" % DB.artes[na]["name"]
		text += line + "\n"
	if drops.size() > 0:
		text += "\nObjetos: " + ", ".join(drops.map(func(x): return DB.items.get(x, {}).get("name", x)))
	text += "\n\n[color=#aaaaaa]Pulsa Confirmar para continuar[/color]"
	await get_tree().create_timer(1.6).timeout
	hud.show_results(text)
	_results_ready = true

func _lose() -> void:
	hud.show_center("Derrota...", 2.0)
	await get_tree().create_timer(2.2).timeout
	hud.show_results("[b]Game Over[/b]\n\nLa party ha caído.\n\n[color=#aaaaaa]Pulsa Confirmar para volver al título[/color]")
	_results_ready = true
