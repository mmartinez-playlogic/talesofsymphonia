class_name Cutscene
extends RefCounted
## Scripted event helper used by field maps. Every method is awaitable:
##   await cs.say([{"speaker": "Lloyd", "text": "..."}])
##   await cs.walk("genis", Vector3(2, 0, 4))
## Actors are the player ("player") or Npc nodes by node name.

var field: Field

func _init(f: Field) -> void:
	field = f

# ---------- actors ----------
func actor(id: String) -> Node3D:
	if id == "player":
		return field.player
	return field.get_node_or_null(id)

func model_of(id: String) -> CharacterModel:
	var a := actor(id)
	if a == null:
		return null
	return a.get("model")

## Spawn a temporary NPC for this scene (no dialogue unless lines given).
func spawn(id: String, model_id: String, pos: Vector3, yaw_deg := 0.0, npc_name := "") -> Npc:
	var existing := field.get_node_or_null(id)
	if existing:
		existing.position = pos
		existing.rotation_degrees.y = yaw_deg
		existing.visible = true
		return existing
	return field.add_npc(id, pos, npc_name if npc_name != "" else id.capitalize(), model_id, [], yaw_deg)

func despawn(id: String) -> void:
	var a := actor(id)
	if a and id != "player":
		a.name = id + "_gone"   # free the name so spawn(id) can reuse it this frame
		a.queue_free()

func hide_actor(id: String) -> void:
	var a := actor(id)
	if a:
		a.visible = false
		if a is CollisionObject3D:
			(a as CollisionObject3D).collision_layer = 0

func show_actor(id: String) -> void:
	var a := actor(id)
	if a:
		a.visible = true
		if a is CollisionObject3D:
			(a as CollisionObject3D).collision_layer = 1 | 4

func teleport(id: String, pos: Vector3, yaw_deg := -1000.0) -> void:
	var a := actor(id)
	if a == null:
		return
	a.global_position = pos
	if yaw_deg > -999.0:
		a.rotation_degrees.y = yaw_deg

# ---------- dialogue ----------
func say(lines: Array) -> void:
	await field.dialogue.show_lines(lines)

## Dialogue by scene id. Lines come from src/data/script/*.json when present (1:1 game text),
## otherwise the inline fallback is used. Format: {"<id>": [{"speaker": "...", "text": "..."}, ...]}
func script(id: String, fallback: Array) -> void:
	var lines: Array = DB.script_lines(id)
	await field.dialogue.show_lines(lines if not lines.is_empty() else fallback)

func line(speaker: String, text: String) -> void:
	await field.dialogue.show_lines([{"speaker": speaker, "text": text}])

func choice(prompt: String, options: Array) -> int:
	var r: int = await field.dialogue.show_choice(prompt, options)
	return r

func caption(text: String, seconds := 2.0) -> void:
	await field.dialogue.show_caption(text, seconds)

# ---------- motion ----------
func face(id: String, target_pos: Vector3) -> void:
	var a := actor(id)
	if a == null:
		return
	var d := target_pos - a.global_position
	d.y = 0
	if d.length() > 0.01:
		a.rotation.y = atan2(d.x, d.z)

func face_each_other(a_id: String, b_id: String) -> void:
	var a := actor(a_id)
	var b := actor(b_id)
	if a and b:
		face(a_id, b.global_position)
		face(b_id, a.global_position)

func face_dir(id: String, yaw_deg: float) -> void:
	var a := actor(id)
	if a:
		a.rotation_degrees.y = yaw_deg

## Walk an actor to a position. Non-blocking variant returns immediately when wait=false.
func walk(id: String, pos: Vector3, speed := 3.2, run := false, wait := true) -> void:
	var a := actor(id)
	if a == null:
		return
	if wait:
		await _walk_impl(a, pos, speed, run)
	else:
		_walk_impl(a, pos, speed, run)

func run_to(id: String, pos: Vector3, wait := true) -> void:
	await walk(id, pos, 6.0, true, wait)

func _walk_impl(a: Node3D, pos: Vector3, speed: float, run: bool) -> void:
	var m: CharacterModel = a.get("model")
	var anim_run := "Jog_Fwd"
	var anim_walk := "Walk"
	if m and not m.humanoid:
		anim_run = "Run"
		anim_walk = "Run"
	if m:
		m.play(anim_run if run else anim_walk)
	if "scripted" in a:
		a.set("scripted", true)
	var tree := field.get_tree()
	var guard := 0
	while guard < 1200:
		guard += 1
		var d := pos - a.global_position
		d.y = 0
		var dist := d.length()
		if dist < 0.08:
			break
		var step: float = speed * tree.root.get_process_delta_time()
		a.rotation.y = lerp_angle(a.rotation.y, atan2(d.x, d.z), 0.35)
		if step >= dist:
			a.global_position = Vector3(pos.x, a.global_position.y, pos.z)
			break
		a.global_position += d.normalized() * step
		await tree.process_frame
	if "scripted" in a:
		a.set("scripted", false)
	if m:
		m.play("Idle")

func anim(id: String, anim_name: String, force := true) -> void:
	var m := model_of(id)
	if m:
		m.play(anim_name, 0.12, 1.0, force)

func anim_wait(id: String, anim_name: String) -> void:
	var m := model_of(id)
	if m == null:
		return
	m.play(anim_name, 0.12, 1.0, true)
	await field.get_tree().create_timer(m.anim_length(anim_name)).timeout
	m.play("Idle")

func hop(id: String, times := 1) -> void:
	var a := actor(id)
	if a == null:
		return
	for i in times:
		var t := field.create_tween()
		t.tween_property(a, "position:y", a.position.y + 0.5, 0.14).set_ease(Tween.EASE_OUT)
		t.tween_property(a, "position:y", a.position.y, 0.14).set_ease(Tween.EASE_IN)
		await t.finished

func shake(id: String, times := 2) -> void:
	var a := actor(id)
	if a == null:
		return
	var base := a.position
	for i in times:
		var t := field.create_tween()
		t.tween_property(a, "position:x", base.x + 0.15, 0.05)
		t.tween_property(a, "position:x", base.x - 0.15, 0.05)
		t.tween_property(a, "position:x", base.x, 0.05)
		await t.finished

# ---------- timing / screen ----------
func wait(seconds: float) -> void:
	await field.get_tree().create_timer(seconds).timeout

func fade_out(d := 0.4) -> void:
	await Router.fade_out(d)

func fade_in(d := 0.4) -> void:
	await Router.fade_in(d)

func flash(color := Color(1, 1, 1), d := 0.5) -> void:
	await Router.flash(color, d)

func shake_camera(strength := 0.3, d := 0.5) -> void:
	await field.camera.shake(strength, d)

## Point the camera at a world position (or back to the player with null).
func look_at_pos(pos, time := 0.6) -> void:
	await field.camera.focus(pos, time)

func look_at_actor(id: String, time := 0.6) -> void:
	var a := actor(id)
	if a:
		await field.camera.focus(a.global_position, time)

func camera_reset(time := 0.6) -> void:
	await field.camera.focus(null, time)

# ---------- game state ----------
func flag(name: String, value = true) -> void:
	Game.set_flag(name, value)

func has(name: String) -> bool:
	return bool(Game.get_flag(name, false))

func give_item(item_id: String, count := 1) -> void:
	Game.add_item(item_id, count)
	var n: String = DB.items.get(item_id, {}).get("name", item_id)
	await caption("Has obtenido: %s%s" % [n, (" x%d" % count) if count > 1 else ""], 1.6)

func give_gald(amount: int) -> void:
	Game.gald += amount
	await caption("Has obtenido %d Gald" % amount, 1.4)

func join(char_id: String) -> void:
	Game.add_member(char_id)
	var n: String = DB.characters.get(char_id, {}).get("name", char_id)
	await caption("%s se une al grupo" % n, 1.8)

func leave(char_id: String) -> void:
	Game.remove_from_party(char_id)

func set_party(ids: Array) -> void:
	Game.set_party(ids)

func heal_party() -> void:
	Game.heal_all()

func skit(skit_id: String) -> void:
	await field.play_skit(skit_id)

func goto(map_id: String, spawn := "default") -> void:
	Game.last_field_position = Vector3.ZERO
	Router.goto_map(map_id, spawn)

## Start a story battle. The field scene is replaced; when the party wins, the map reloads and
## Field will run the event named `resume_event` (see Field.on_resume). Callers must `return`
## right after awaiting this.
func battle(enemies: Array, resume_event: String, advantage := "normal", guests: Array = []) -> void:
	for g in guests:
		if not Game.members.has(g):
			Game.add_member(g)
		if not Game.party.has(g) and Game.party.size() < 4:
			Game.party.append(g)
	Game.flags["resume_event"] = resume_event
	Game.flags["resume_map"] = field.map_id
	Game.last_field_position = field.player.global_position
	Game.current_map = field.map_id
	await Router.start_battle({"enemies": enemies, "advantage": advantage, "map": field.map_id, "story": true})
