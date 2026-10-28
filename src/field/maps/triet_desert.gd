extends Field
## Triet Desert: arrival. Triet town, the fortune teller, the capture and the Renegade base follow (ROADMAP C2).

func sky_top() -> Color: return Color(0.35, 0.55, 0.9)
func sky_horizon() -> Color: return Color(0.95, 0.85, 0.65)
func sun_energy() -> float: return 1.7
func sun_color() -> Color: return Color(1.0, 0.92, 0.75)

func build() -> void:
	map_id = "triet_desert"
	map_title = "Desierto de Triet"
	encounter_table = "triet_desert"
	spawns["default"] = Vector3(52, 0.1, 0)
	spawn_yaw["default"] = -PI / 2
	add_ground(Vector2(130, 90), Color(0.88, 0.78, 0.52))
	add_path([Vector3(56, 0, 0), Vector3(20, 0, -6), Vector3(-20, 0, 4), Vector3(-54, 0, 0)], 3.0, Color(0.8, 0.68, 0.45))
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	for i in 30:
		var p := Vector3(rng.randf_range(-60, 60), 0, rng.randf_range(-40, 40))
		if abs(p.z) < 7:
			continue
		add_rock(p, rng.randf_range(2.0, 5.0), Color(0.85, 0.72, 0.48))
	for i in 24:
		var p := Vector3(rng.randf_range(-60, 60), 0, rng.randf_range(-40, 40))
		if abs(p.z) < 6:
			continue
		add_cactus(p, rng.randf_range(0.8, 1.5))
	add_patch(Vector3(-40, 0, 14), Vector2(14, 10), Color(0.25, 0.55, 0.85), 0.03)
	for i in 5:
		add_palm(Vector3(-48 + i * 4, 0, 8 + (i % 2) * 12), 1.1)
	add_box(Vector3(-60, 0, -8), Vector3(3, 7, 3), Color(0.8, 0.7, 0.5))
	add_box(Vector3(-60, 0, 8), Vector3(3, 7, 3), Color(0.8, 0.7, 0.5))
	add_box(Vector3(-60, 6.5, 0), Vector3(3, 1.2, 19), Color(0.75, 0.65, 0.45))
	add_box(Vector3(-58.4, 1.0, -6.2), Vector3(0.1, 1.0, 0.8), Color(0.95, 0.9, 0.75))   # wanted poster
	add_wall(Vector3(-65, 0, -45), Vector3(-65, 0, 45))
	add_wall(Vector3(65, 0, -45), Vector3(65, 0, -5))
	add_wall(Vector3(65, 0, 5), Vector3(65, 0, 45))
	add_wall(Vector3(-65, 0, -45), Vector3(65, 0, -45))
	add_wall(Vector3(-65, 0, 45), Vector3(65, 0, 45))
	add_exit(Vector3(66, 1, 0), Vector3(1.5, 3, 10), "world_sylvarant", "triet")
	add_sign(Vector3(-56, 0, 4), "Ciudad de Triet, puerta este.")
	add_chest("desert1", Vector3(10, 0, 20), "orange_gel")
	add_monster(Vector3(30, 0, -10), ["sand_wolf"])
	add_monster(Vector3(0, 0, 12), ["sand_wolf", "desert_hornet"])
	add_monster(Vector3(-24, 0, -12), ["desert_hornet", "desert_hornet", "hare"])
	add_shop_npc("caravan", Vector3(-52, 0, 6), "Mercader de la caravana", "botta", "triet", "¡Agua, geles, especias y acero! Lo mejor del bazar de Triet, aquí mismo.", 270.0)
	add_inn_npc("tent_inn", Vector3(-52, 0, -6), "Posadera nómada", "marble", 100, 270.0)
	add_interactable("poster", Vector3(-57.8, 0, -6.2), Vector3(0.6, 2.0, 1.0), Color(0.95, 0.9, 0.75), _poster)
	add_interactable("triet_gate", Vector3(-62, 0, 0), Vector3(2, 6, 12), Color(0.5, 0.4, 0.3), _gate)
	if Game.get_flag("triet_arrived", false):
		add_npc("noishe", Vector3(46, 0, 4), "Noishe", "wolf", [{"speaker": "Noishe", "text": "¡Guau...! (Noishe no quiere adentrarse en el desierto.)"}])

func _poster(c: Cutscene) -> void:
	if c.has("poster_seen"):
		await c.line("", "«SE BUSCA: Lloyd Irving». El dibujo no se parece en nada.")
		return
	c.flag("poster_seen")
	c.spawn("genis", "genis", player.global_position + Vector3(0, 0, 1.5), 0.0, "Genis")
	await c.script("triet_desert.poster.01", [
		{"speaker": "", "text": "«SE BUSCA: Lloyd Irving. Recompensa.» Hay un retrato."},
		{"speaker": "Lloyd", "text": "¡¿Soy yo?! ¡Ya tienen carteles con mi cara!"},
		{"speaker": "Genis", "text": "Está bien. Con este dibujo no te van a encontrar nunca... creo."},
		{"speaker": "Lloyd", "text": "¡Oye! ¿Tan mal está?"},
	])
	c.despawn("genis")

func _gate(c: Cutscene) -> void:
	await c.script("triet_desert.gate.01", [
		{"speaker": "Genis", "text": "La ciudad de Triet. Colette tiene que estar ahí dentro."},
		{"speaker": "Lloyd", "text": "Pues vamos. ¡Colette, espéranos!"},
		{"speaker": "", "text": "[color=#a0c0ff](Fin del contenido actual. Triet, la adivina, la captura de Lloyd y la base de los Renegados llegan en la siguiente sesión: C2.)[/color]"},
	])

func on_enter(c: Cutscene) -> void:
	if c.has("triet_arrived"):
		return
	c.spawn("genis", "genis", Vector3(54, 0, 2), -90.0, "Genis")
	c.spawn("noishe", "wolf", Vector3(57, 0, -2), -90.0, "Noishe")
	await c.walk("player", Vector3(44, 0, 0), 3.5, false, false)
	await c.walk("genis", Vector3(46, 0, 2), 3.5)
	await c.script("triet_desert.arrival.01", [
		{"speaker": "Lloyd", "text": "Uf... Qué calor. ¿Esto es el desierto de Triet?"},
		{"speaker": "Genis", "text": "Sí. La ciudad está al oeste, junto al oasis. Noishe, ¡venga, vamos!"},
		{"speaker": "Noishe", "text": "¡Guau... guau...!"},
		{"speaker": "Lloyd", "text": "No quiere. Está bien, Noishe, espera aquí. Genis, vamos."},
	])
	c.flag("triet_arrived")
	c.despawn("genis")
	await c.caption("Desierto de Triet. Ciudad de Triet: al oeste.", 2.4)
