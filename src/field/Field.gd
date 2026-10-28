class_name Field
extends Node3D
## Base class for field maps. Subclasses override build() to construct geometry, NPCs, spawns and
## monsters, on_enter() to start story events when the map loads, and on_resume(event) to continue
## an event after a story battle.

var player: FieldPlayer
var camera: FieldCamera
var dialogue: DialogueBox
var cs: Cutscene
var map_id := "field"
var map_title := ""
var spawns: Dictionary = {}          # name -> Vector3
var _monsters: Array[FieldMonster] = []
var _monster_defs: Array = []        # [{pos, enemies}]
var _world_root: Node3D
var encounter_table := ""            # key into DB.encounters
var bgm := ""
var event_running := false
var _skit_prompt: Label
var _skit_check := 0.0
var _available_skit := ""
var _skit_box: SkitBox
var _pause: PauseMenu
var _shop: ShopMenu
var _hud: CanvasLayer

func _ready() -> void:
	_world_root = Node3D.new()
	_world_root.name = "World"
	add_child(_world_root)
	_setup_environment()
	dialogue = DialogueBox.new()
	add_child(dialogue)
	cs = Cutscene.new(self)
	build()
	_spawn_player()
	_spawn_monsters()
	_build_hud()
	var returning := Game.return_to_field
	if Game.return_to_field:
		Game.return_to_field = false
	call_deferred("_start_events", returning)

func _start_events(returning: bool) -> void:
	await get_tree().process_frame
	var resume: String = str(Game.flags.get("resume_event", ""))
	var resume_map: String = str(Game.flags.get("resume_map", ""))
	if returning and resume != "" and resume_map == map_id:
		Game.flags.erase("resume_event")
		Game.flags.erase("resume_map")
		await run_event(Callable(self, "on_resume").bind(resume))
		return
	if returning:
		await run_event(Callable(self, "on_return"))
		return
	if map_title != "":
		dialogue.show_caption(map_title, 1.6)
	await run_event(Callable(self, "on_enter"))

func build() -> void:
	pass

## Called once the map is ready. Check flags and run story events with run_event()/await.
func on_enter(_cs: Cutscene) -> void:
	pass

## Called after returning from a story battle started with cs.battle(..., event_name).
func on_resume(_cs: Cutscene, _event: String) -> void:
	pass

## Called after returning from a normal (field monster) battle.
func on_return(_cs: Cutscene) -> void:
	pass

func defeated_count() -> int:
	return Game.flags.get("defeated_" + map_id, []).size()

## Run a scripted event: locks the player, awaits fn(cs), unlocks.
func run_event(fn: Callable) -> void:
	if not is_inside_tree():
		return
	event_running = true
	if player:
		player.can_move = false
	await fn.call(cs)
	# wait for any fade/scene change to finish; if this map was replaced, just stop
	while is_inside_tree() and Router._busy:
		await get_tree().process_frame
	if not is_inside_tree() or not is_instance_valid(player):
		return
	event_running = false
	player.can_move = true

func _setup_environment() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var mat := ProceduralSkyMaterial.new()
	mat.sky_top_color = sky_top()
	mat.sky_horizon_color = sky_horizon()
	mat.ground_bottom_color = Color(0.2, 0.25, 0.2)
	mat.ground_horizon_color = Color(0.6, 0.7, 0.6)
	sky.sky_material = mat
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = ambient_energy()
	e.fog_enabled = true
	e.fog_light_color = sky_horizon()
	e.fog_density = 0.004
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_vesperia_post(e)
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.light_energy = sun_energy()
	sun.light_color = sun_color()
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 80
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.shadow_blur = 2.0
	sun.shadow_normal_bias = 2.0
	add_child(sun)

## Vesperia-like post: soft bloom, gentle AO in creases, slightly richer colour.
static func _vesperia_post(e: Environment) -> void:
	e.glow_enabled = true
	e.glow_intensity = 0.6
	e.glow_strength = 0.9
	e.glow_bloom = 0.08
	e.glow_hdr_threshold = 0.95
	e.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	e.ssao_enabled = true
	e.ssao_radius = 0.8
	e.ssao_intensity = 1.2
	e.adjustment_enabled = true
	e.adjustment_saturation = 1.12
	e.adjustment_contrast = 1.04
	e.tonemap_white = 1.2

# Overridable lighting per map (night, desert, interiors).
func sky_top() -> Color: return Color(0.25, 0.45, 0.85)
func sky_horizon() -> Color: return Color(0.75, 0.85, 0.95)
func sun_energy() -> float: return 1.4
func sun_color() -> Color: return Color(1.0, 0.96, 0.88)
func ambient_energy() -> float: return 0.7

func _spawn_player() -> void:
	player = FieldPlayer.new()
	player.name = "Player"
	add_child(player)
	var pos: Vector3 = spawns.get(Game.spawn_point, spawns.get("default", Vector3.ZERO))
	if Game.return_to_field and Game.last_field_position != Vector3.ZERO:
		pos = Game.last_field_position
	player.global_position = pos
	player.rotation.y = float(spawn_yaw.get(Game.spawn_point, PI))
	player.interact_requested.connect(_on_interact)
	camera = FieldCamera.new()
	camera.target = player
	add_child(camera)
	camera.current = true
	camera._snap()
	player.set_camera_yaw(deg_to_rad(camera.yaw_deg))

var spawn_yaw: Dictionary = {}   # spawn name -> yaw radians (default PI = facing north/-Z)

func _build_hud() -> void:
	_hud = CanvasLayer.new()
	_hud.layer = 40
	add_child(_hud)
	_skit_prompt = Label.new()
	_skit_prompt.position = Vector2(1920 - 620, 30)
	_skit_prompt.size = Vector2(580, 50)
	_skit_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_skit_prompt.add_theme_font_size_override("font_size", 26)
	_skit_prompt.add_theme_color_override("font_color", Color(0.95, 0.9, 0.7))
	_skit_prompt.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_skit_prompt.add_theme_constant_override("outline_size", 8)
	_skit_prompt.visible = false
	_hud.add_child(_skit_prompt)
	_skit_box = SkitBox.new()
	add_child(_skit_box)
	_pause = PauseMenu.new()
	_pause.field = self
	add_child(_pause)
	_shop = ShopMenu.new()
	add_child(_shop)
	Game.title_earned.connect(_on_title_earned)

func _on_title_earned(char_id: String, title_id: String) -> void:
	if dialogue:
		dialogue.show_caption("%s ha obtenido el título «%s»" % [str(DB.characters.get(char_id, {}).get("name", char_id)).split(" ")[0], DB.titles[title_id]["name"]], 2.2)

## Open a shop (id from src/data/shops.json). Awaitable; used from NPC handlers.
func open_shop(shop_id: String) -> void:
	await _shop.open(shop_id)

## Inn: ask, charge, fade, heal. Awaitable.
func inn(price: int, keeper := "Posadero") -> void:
	var i: int = await dialogue.show_choice("%s: Una noche son %d Gald. ¿Os quedáis?" % [keeper, price], ["Sí", "No"])
	if i != 0:
		return
	if Game.gald < price:
		await dialogue.show_lines([{"speaker": keeper, "text": "Lo siento, no os llega el dinero."}])
		return
	Game.gald -= price
	await Router.fade_out(0.6)
	Game.heal_all()
	await get_tree().create_timer(0.8).timeout
	await Router.fade_in(0.6)
	await dialogue.show_lines([{"speaker": keeper, "text": "Buenos días. Habéis dormido como troncos."}])

## Merchant NPC helper.
func add_shop_npc(id: String, pos: Vector3, npc_name: String, model_id: String, shop_id: String, greeting := "¡Bienvenidos! Mirad lo que tengo.", yaw_deg := 0.0) -> Npc:
	var n := add_npc(id, pos, npc_name, model_id, [], yaw_deg)
	n.on_interact = func(_f):
		await dialogue.show_lines([{"speaker": npc_name, "text": greeting}])
		await open_shop(shop_id)
	return n

func add_inn_npc(id: String, pos: Vector3, npc_name: String, model_id: String, price: int, yaw_deg := 0.0) -> Npc:
	var n := add_npc(id, pos, npc_name, model_id, [], yaw_deg)
	n.on_interact = func(_f): await inn(price, npc_name)
	return n

func _process(delta: float) -> void:
	_skit_check -= delta
	if _skit_check <= 0:
		_skit_check = 0.5
		var list: Array = Skits.available(map_id)
		_available_skit = list[0] if list.size() > 0 else ""
		if _available_skit != "" and not event_running:
			_skit_prompt.text = "Skit: %s   [U]" % Skits.title(_available_skit)
			_skit_prompt.visible = true
		else:
			_skit_prompt.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if player == null or not player.can_move or event_running:
		return
	if event.is_action_pressed("skit") and _available_skit != "":
		get_viewport().set_input_as_handled()
		var id := _available_skit
		_available_skit = ""
		_skit_prompt.visible = false
		run_event(func(_c): await play_skit(id))
	elif event.is_action_pressed("menu"):
		get_viewport().set_input_as_handled()
		run_event(func(_c): await _pause.open())

func play_skit(skit_id: String) -> void:
	await _skit_box.play(skit_id)

func _on_interact(target: Node) -> void:
	if not player.can_move or event_running:
		return
	event_running = true
	player.can_move = false
	player.face(target.global_position)
	# Run handlers from here (not as coroutines of the target) so a target that frees itself
	# mid-interaction cannot swallow the resume and leave the player locked.
	if "handler" in target and (target.get("handler") as Callable).is_valid():
		await (target.get("handler") as Callable).call(self)
	elif target is Npc and (target as Npc).on_interact.is_valid():
		(target as Npc).face_pos(player.global_position)
		await (target as Npc).on_interact.call(self)
	else:
		await target.interact(self)
	if is_inside_tree() and is_instance_valid(player):
		player.can_move = true
	event_running = false

func _spawn_monsters() -> void:
	var defeated: Array = Game.flags.get("defeated_" + map_id, [])
	print("[FIELD] %s monsters=%d defeated=%s" % [map_id, _monster_defs.size(), str(defeated)])
	for i in _monster_defs.size():
		if i in defeated:
			continue
		var d: Dictionary = _monster_defs[i]
		var m := FieldMonster.new()
		m.setup(self, d["enemies"], i)
		m.position = d["pos"]
		add_child(m)
		_monsters.append(m)

func begin_battle(monster: FieldMonster, advantage: String) -> void:
	player.can_move = false
	Game.last_field_position = player.global_position
	Game.current_map = map_id
	var defeated: Array = Game.flags.get("defeated_" + map_id, [])
	defeated.append(monster.monster_index)
	Game.flags["defeated_" + map_id] = defeated
	Router.start_battle({"enemies": monster.group, "advantage": advantage, "map": map_id})

## Pick a random group from the encounter table.
func random_group() -> Array:
	var table: Dictionary = DB.encounters.get(encounter_table, {})
	var groups: Array = table.get("groups", [])
	if groups.is_empty():
		return ["wolf"]
	var total := 0
	for g in groups:
		total += int(g.get("weight", 1))
	var r := randi() % total
	for g in groups:
		r -= int(g.get("weight", 1))
		if r < 0:
			return g["enemies"].duplicate()
	return groups[0]["enemies"].duplicate()

func npc(id: String) -> Npc:
	return get_node_or_null(id) as Npc

# ---------- geometry helpers for procedural maps ----------
func add_ground(size: Vector2, color: Color, pos := Vector3.ZERO) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = size
	pm.subdivide_depth = 8
	pm.subdivide_width = 8
	mi.mesh = pm
	mi.set_surface_override_material(0, ToonMaterial.make(color, false))
	body.add_child(mi)
	var cs_ := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size.x, 0.2, size.y)
	cs_.shape = box
	cs_.position.y = -0.1
	body.add_child(cs_)
	body.position = pos
	_world_root.add_child(body)
	return body

## Flat colored patch without collision (paths, carpets, water, sand).
func add_patch(pos: Vector3, size: Vector2, color: Color, y := 0.02, shaded := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = size
	mi.mesh = pm
	mi.set_surface_override_material(0, ToonMaterial.make(color, shaded))
	mi.position = pos + Vector3(0, y, 0)
	_world_root.add_child(mi)
	return mi

func add_tree(pos: Vector3, scale_f := 1.0, color := Color(0.18, 0.5, 0.22)) -> void:
	var trunk := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.18 * scale_f
	cm.bottom_radius = 0.28 * scale_f
	cm.height = 2.2 * scale_f
	trunk.mesh = cm
	trunk.set_surface_override_material(0, ToonMaterial.make(Color(0.36, 0.24, 0.14), true, 0.02))
	trunk.position = pos + Vector3(0, 1.1 * scale_f, 0)
	_world_root.add_child(trunk)
	for i in 3:
		var leaves := MeshInstance3D.new()
		var sm := SphereMesh.new()
		var r := (1.6 - i * 0.35) * scale_f
		sm.radius = r
		sm.height = r * 1.6
		sm.radial_segments = 10
		sm.rings = 6
		leaves.mesh = sm
		leaves.set_surface_override_material(0, ToonMaterial.make(color.lightened(i * 0.08), true, 0.03))
		leaves.position = pos + Vector3(0, (2.4 + i * 0.9) * scale_f, 0)
		_world_root.add_child(leaves)
	_add_cylinder_collider(pos, 0.35 * scale_f, 3.0)

func add_palm(pos: Vector3, scale_f := 1.0) -> void:
	var trunk := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.12 * scale_f
	cm.bottom_radius = 0.22 * scale_f
	cm.height = 4.0 * scale_f
	trunk.mesh = cm
	trunk.set_surface_override_material(0, ToonMaterial.make(Color(0.5, 0.36, 0.2), true, 0.02))
	trunk.position = pos + Vector3(0, 2.0 * scale_f, 0)
	trunk.rotation_degrees.z = 6
	_world_root.add_child(trunk)
	for i in 6:
		var leaf := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.5 * scale_f, 0.06, 2.4 * scale_f)
		leaf.mesh = bm
		leaf.set_surface_override_material(0, ToonMaterial.make(Color(0.25, 0.55, 0.25), true, 0.02))
		leaf.position = pos + Vector3(0, 4.0 * scale_f, 0)
		leaf.rotation_degrees = Vector3(-25, i * 60.0, 0)
		var pivot := Node3D.new()
		pivot.position = leaf.position
		pivot.rotation_degrees = Vector3(0, i * 60.0, 0)
		var l2 := MeshInstance3D.new()
		l2.mesh = bm
		l2.set_surface_override_material(0, ToonMaterial.make(Color(0.25, 0.55, 0.25), true, 0.02))
		l2.position = Vector3(0, 0, 1.1 * scale_f)
		l2.rotation_degrees.x = 25
		pivot.add_child(l2)
		_world_root.add_child(pivot)
	_add_cylinder_collider(pos, 0.3 * scale_f, 4.0)

func add_cactus(pos: Vector3, scale_f := 1.0) -> void:
	var m := ToonMaterial.make(Color(0.25, 0.5, 0.3), true, 0.02)
	var body := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.25 * scale_f
	cm.bottom_radius = 0.3 * scale_f
	cm.height = 2.0 * scale_f
	body.mesh = cm
	body.set_surface_override_material(0, m)
	body.position = pos + Vector3(0, 1.0 * scale_f, 0)
	_world_root.add_child(body)
	for s in [-1, 1]:
		var arm := MeshInstance3D.new()
		var am := CylinderMesh.new()
		am.top_radius = 0.15 * scale_f
		am.bottom_radius = 0.15 * scale_f
		am.height = 0.9 * scale_f
		arm.mesh = am
		arm.set_surface_override_material(0, m)
		arm.position = pos + Vector3(s * 0.45 * scale_f, 1.3 * scale_f, 0)
		_world_root.add_child(arm)
	_add_cylinder_collider(pos, 0.35 * scale_f, 2.0)

func _add_cylinder_collider(pos: Vector3, radius: float, height: float) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var cs_ := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = height
	cs_.shape = cyl
	cs_.position = pos + Vector3(0, height / 2, 0)
	body.add_child(cs_)
	_world_root.add_child(body)

func add_rock(pos: Vector3, size := 1.0, color := Color(0.45, 0.45, 0.5)) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = size * 0.6
	sm.height = size * 0.8
	sm.radial_segments = 8
	sm.rings = 4
	mi.mesh = sm
	mi.set_surface_override_material(0, ToonMaterial.make(color, true, 0.02))
	mi.position = pos + Vector3(0, size * 0.25, 0)
	mi.rotation.y = randf() * TAU
	_world_root.add_child(mi)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var cs_ := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = size * 0.55
	cs_.shape = sh
	cs_.position = pos + Vector3(0, size * 0.25, 0)
	body.add_child(cs_)
	_world_root.add_child(body)

func add_path(points: Array, width := 2.5, color := Color(0.62, 0.52, 0.36)) -> void:
	for i in points.size() - 1:
		var a: Vector3 = points[i]
		var b: Vector3 = points[i + 1]
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(width, 0.04, a.distance_to(b) + width * 0.5)
		mi.mesh = bm
		mi.set_surface_override_material(0, ToonMaterial.make(color, false))
		mi.position = (a + b) / 2 + Vector3(0, 0.02, 0)
		mi.look_at_from_position(mi.position, b + Vector3(0, 0.02, 0), Vector3.UP)
		_world_root.add_child(mi)

func add_wall(from: Vector3, to: Vector3, height := 3.0, visible_wall := false, color := Color(0.5, 0.45, 0.4), thickness := 0.5) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var cs_ := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(thickness, height, from.distance_to(to))
	cs_.shape = box
	body.add_child(cs_)
	body.position = (from + to) / 2 + Vector3(0, height / 2, 0)
	body.look_at_from_position(body.position, to + Vector3(0, height / 2, 0), Vector3.UP)
	_world_root.add_child(body)
	if visible_wall:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = box.size
		mi.mesh = bm
		mi.set_surface_override_material(0, ToonMaterial.make(color, true, 0.02))
		body.add_child(mi)

## Solid box with collision (crates, counters, pillars, altars).
func add_box(pos: Vector3, size: Vector3, color: Color, shaded := true) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.set_surface_override_material(0, ToonMaterial.make(color, shaded, 0.02))
	body.add_child(mi)
	var cs_ := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	cs_.shape = box
	body.add_child(cs_)
	body.position = pos + Vector3(0, size.y / 2, 0)
	_world_root.add_child(body)
	return body

## Simple house: walls box + prism roof + door patch. `door_side` 0 = door faces +Z (south).
func add_building(pos: Vector3, size: Vector3, wall_color: Color, roof_color: Color, yaw_deg := 0.0) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	root.rotation_degrees.y = yaw_deg
	_world_root.add_child(root)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.set_surface_override_material(0, ToonMaterial.make(wall_color, true, 0.02))
	body.add_child(mi)
	var cs_ := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	cs_.shape = box
	body.add_child(cs_)
	body.position = Vector3(0, size.y / 2, 0)
	root.add_child(body)
	var roof := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = Vector3(size.x + 0.8, size.y * 0.45, size.z + 0.8)
	roof.mesh = pm
	roof.set_surface_override_material(0, ToonMaterial.make(roof_color, true, 0.02))
	roof.position = Vector3(0, size.y + pm.size.y / 2, 0)
	root.add_child(roof)
	var door := MeshInstance3D.new()
	var dm := BoxMesh.new()
	dm.size = Vector3(1.1, 1.9, 0.1)
	door.mesh = dm
	door.set_surface_override_material(0, ToonMaterial.make(Color(0.35, 0.22, 0.12), true, 0.02))
	door.position = Vector3(0, 0.95, size.z / 2 + 0.03)
	root.add_child(door)
	for sx in [-1, 1]:
		var win := MeshInstance3D.new()
		var wm := BoxMesh.new()
		wm.size = Vector3(0.8, 0.8, 0.08)
		win.mesh = wm
		win.set_surface_override_material(0, ToonMaterial.make(Color(0.6, 0.8, 0.95), false))
		win.position = Vector3(sx * size.x * 0.3, size.y * 0.6, size.z / 2 + 0.03)
		root.add_child(win)
	return root

func add_npc(id: String, pos: Vector3, npc_name: String, model_id: String, lines: Array, yaw_deg := 0.0) -> Npc:
	var n := Npc.new()
	n.name = id
	n.npc_name = npc_name
	n.model_id = model_id
	n.lines = lines
	n.position = pos
	n.rotation_degrees.y = yaw_deg
	add_child(n)
	return n

## NPC whose interaction runs a custom coroutine `fn(cs)`.
func add_npc_event(id: String, pos: Vector3, npc_name: String, model_id: String, fn: Callable, yaw_deg := 0.0) -> Npc:
	var n := add_npc(id, pos, npc_name, model_id, [], yaw_deg)
	n.on_interact = func(_f): await fn.call(cs)
	return n

func add_monster(pos: Vector3, enemies: Array) -> void:
	_monster_defs.append({"pos": pos, "enemies": enemies})

## Map exit. `condition` (optional Callable -> bool) blocks the exit and `blocked` lines are shown.
func add_exit(pos: Vector3, size: Vector3, target_map: String, spawn: String, condition := Callable(), blocked: Array = []) -> Area3D:
	var area := _area(pos, size)
	area.body_entered.connect(func(body):
		if body != player or not player.can_move or event_running:
			return
		if condition.is_valid() and not condition.call():
			if not blocked.is_empty():
				run_event(func(c):
					await c.say(blocked)
					# nudge back so the area can re-trigger
					player.global_position += Vector3(sin(player.rotation.y), 0, cos(player.rotation.y)) * -1.2
				)
			return
		player.can_move = false
		Game.last_field_position = Vector3.ZERO
		Router.goto_map(target_map, spawn)
	)
	return area

## Invisible trigger running `fn(cs)` once per flag (or every time if flag == "").
func add_trigger(pos: Vector3, size: Vector3, fn: Callable, once_flag := "") -> Area3D:
	var area := _area(pos, size)
	area.body_entered.connect(func(body):
		if body != player or not player.can_move or event_running:
			return
		if once_flag != "" and Game.get_flag(once_flag, false):
			return
		if once_flag != "":
			Game.set_flag(once_flag, true)
		run_event(fn)
	)
	return area

func _area(pos: Vector3, size: Vector3) -> Area3D:
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 1
	var cs_ := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	cs_.shape = box
	area.add_child(cs_)
	area.position = pos
	add_child(area)
	return area

func add_sign(pos: Vector3, text: String) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1 | 4
	body.set_script(preload("res://src/field/Sign.gd"))
	body.set("lines", [{"speaker": "", "text": text}])
	var cs_ := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.8, 1.2, 0.2)
	cs_.shape = box
	cs_.position.y = 0.6
	body.add_child(cs_)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.8, 0.5, 0.08)
	mi.mesh = bm
	mi.position.y = 0.95
	mi.set_surface_override_material(0, ToonMaterial.make(Color(0.5, 0.35, 0.2)))
	body.add_child(mi)
	var post := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.05
	cm.bottom_radius = 0.05
	cm.height = 1.0
	post.mesh = cm
	post.position.y = 0.5
	post.set_surface_override_material(0, ToonMaterial.make(Color(0.4, 0.28, 0.16)))
	body.add_child(post)
	body.position = pos
	add_child(body)

## Interactable object (chest, altar, pedestal) running fn(cs) on confirm.
func add_interactable(id: String, pos: Vector3, size: Vector3, color: Color, fn: Callable) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = id
	body.collision_layer = 1 | 4
	body.set_script(preload("res://src/field/Interactable.gd"))
	body.set("handler", func(_f): await fn.call(cs))
	var cs_ := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	cs_.shape = box
	cs_.position.y = size.y / 2
	body.add_child(cs_)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position.y = size.y / 2
	mi.set_surface_override_material(0, ToonMaterial.make(color, true, 0.02))
	body.add_child(mi)
	body.position = pos
	add_child(body)
	return body

## Treasure chest: gives item once (flag chest_<map>_<id>).
func add_chest(id: String, pos: Vector3, item_id: String, count := 1) -> void:
	var flag := "chest_%s_%s" % [map_id, id]
	var body := add_interactable("chest_" + id, pos, Vector3(0.9, 0.6, 0.6), Color(0.55, 0.35, 0.15), func(c):
		if Game.get_flag(flag, false):
			await c.line("", "El cofre está vacío.")
			return
		Game.set_flag(flag, true)
		await c.give_item(item_id, count)
	)
	if Game.get_flag(flag, false):
		body.modulate_opened = true

func add_light(pos: Vector3, color := Color(1, 0.85, 0.6), energy := 2.0, range_m := 8.0) -> void:
	var l := OmniLight3D.new()
	l.light_color = color
	l.light_energy = energy
	l.omni_range = range_m
	l.position = pos
	_world_root.add_child(l)
