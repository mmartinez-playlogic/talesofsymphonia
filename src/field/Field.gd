class_name Field
extends Node3D
## Base class for field maps. Subclasses override build() to construct geometry, NPCs, spawns and monsters.

var player: FieldPlayer
var camera: FieldCamera
var dialogue: DialogueBox
var map_id := "field"
var spawns: Dictionary = {}          # name -> Vector3
var _monsters: Array[FieldMonster] = []
var _monster_defs: Array = []        # [{pos, enemies}]
var _world_root: Node3D
var encounter_table := ""            # key into DB.encounters
var bgm := ""

func _ready() -> void:
	_world_root = Node3D.new()
	_world_root.name = "World"
	add_child(_world_root)
	_setup_environment()
	dialogue = DialogueBox.new()
	add_child(dialogue)
	build()
	_spawn_player()
	_spawn_monsters()
	if Game.return_to_field:
		Game.return_to_field = false

func build() -> void:
	pass

func _setup_environment() -> void:
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
	e.fog_enabled = true
	e.fog_light_color = Color(0.75, 0.85, 0.95)
	e.fog_density = 0.004
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.light_energy = 1.4
	sun.light_color = Color(1.0, 0.96, 0.88)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 80
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.shadow_blur = 2.0
	sun.shadow_normal_bias = 2.0
	add_child(sun)

func _spawn_player() -> void:
	player = FieldPlayer.new()
	player.name = "Player"
	add_child(player)
	var pos: Vector3 = spawns.get(Game.spawn_point, spawns.get("default", Vector3.ZERO))
	if Game.return_to_field and Game.last_field_position != Vector3.ZERO:
		pos = Game.last_field_position
	player.global_position = pos
	player.interact_requested.connect(_on_interact)
	camera = FieldCamera.new()
	camera.target = player
	add_child(camera)
	camera.current = true
	camera._snap()
	player.set_camera_yaw(deg_to_rad(camera.yaw_deg))

func _on_interact(target: Node) -> void:
	if not player.can_move:
		return
	player.can_move = false
	player.face(target.global_position)
	await target.interact(self)
	player.can_move = true

func _spawn_monsters() -> void:
	var defeated: Array = Game.flags.get("defeated_" + map_id, [])
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
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size.x, 0.2, size.y)
	cs.shape = box
	cs.position.y = -0.1
	body.add_child(cs)
	body.position = pos
	_world_root.add_child(body)
	return body

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
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.35 * scale_f
	cyl.height = 3.0
	cs.shape = cyl
	cs.position = pos + Vector3(0, 1.5, 0)
	body.add_child(cs)
	_world_root.add_child(body)

func add_rock(pos: Vector3, size := 1.0) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = size * 0.6
	sm.height = size * 0.8
	sm.radial_segments = 8
	sm.rings = 4
	mi.mesh = sm
	mi.set_surface_override_material(0, ToonMaterial.make(Color(0.45, 0.45, 0.5), true, 0.02))
	mi.position = pos + Vector3(0, size * 0.25, 0)
	mi.rotation.y = randf() * TAU
	_world_root.add_child(mi)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = size * 0.55
	cs.shape = sh
	cs.position = pos + Vector3(0, size * 0.25, 0)
	body.add_child(cs)
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

func add_wall(from: Vector3, to: Vector3, height := 3.0, visible_wall := false) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.5, height, from.distance_to(to))
	cs.shape = box
	body.add_child(cs)
	body.position = (from + to) / 2 + Vector3(0, height / 2, 0)
	body.look_at_from_position(body.position, to + Vector3(0, height / 2, 0), Vector3.UP)
	_world_root.add_child(body)
	if visible_wall:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = box.size
		mi.mesh = bm
		mi.set_surface_override_material(0, ToonMaterial.make(Color(0.5, 0.45, 0.4)))
		body.add_child(mi)

func add_npc(id: String, pos: Vector3, npc_name: String, model_id: String, lines: Array, yaw_deg := 180.0) -> Npc:
	var n := Npc.new()
	n.name = id
	n.npc_name = npc_name
	n.model_id = model_id
	n.lines = lines
	n.position = pos
	n.rotation_degrees.y = yaw_deg
	add_child(n)
	return n

func add_monster(pos: Vector3, enemies: Array) -> void:
	_monster_defs.append({"pos": pos, "enemies": enemies})

func add_exit(pos: Vector3, size: Vector3, target_map: String, spawn: String) -> void:
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 1
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	cs.shape = box
	area.add_child(cs)
	area.position = pos
	add_child(area)
	area.body_entered.connect(func(body):
		if body == player and player.can_move:
			player.can_move = false
			Game.last_field_position = Vector3.ZERO
			Router.goto_map(target_map, spawn)
	)

func add_sign(pos: Vector3, text: String) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1 | 4
	body.set_script(preload("res://src/field/Sign.gd"))
	body.set("lines", [{"speaker": "", "text": text}])
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.8, 1.2, 0.2)
	cs.shape = box
	cs.position.y = 0.6
	body.add_child(cs)
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
