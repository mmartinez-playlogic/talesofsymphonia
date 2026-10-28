extends Field
## Iselia Forest: the woods between the village, the Martel Temple (north) and the Desian ranch (east).

func build() -> void:
	map_id = "iselia_forest"
	map_title = "Bosque de Iselia"
	encounter_table = "iselia_forest"
	spawns["default"] = Vector3(0, 0.1, 18)
	spawns["from_village"] = Vector3(0, 0.1, 18)
	spawns["from_temple"] = Vector3(0, 0.1, -46)
	spawns["from_ranch"] = Vector3(30, 0.1, -12)
	spawn_yaw["from_temple"] = 0.0
	spawn_yaw["from_ranch"] = -PI / 2
	add_ground(Vector2(70, 110), Color(0.30, 0.55, 0.26))
	add_path([Vector3(0, 0, 22), Vector3(0, 0, 8), Vector3(-6, 0, -4), Vector3(2, 0, -18), Vector3(0, 0, -34), Vector3(0, 0, -50)])
	add_path([Vector3(2, 0, -14), Vector3(16, 0, -12), Vector3(34, 0, -12)], 2.2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	for i in 90:
		var x := rng.randf_range(-33, 33)
		var z := rng.randf_range(-52, 24)
		if abs(x) < 7 and z > -40:
			continue
		if abs(z + 12) < 4 and x > 0:
			continue
		add_tree(Vector3(x, 0, z), rng.randf_range(0.8, 1.5), Color(0.15, 0.45 + rng.randf() * 0.15, 0.2))
	for i in 14:
		var p := Vector3(rng.randf_range(-20, 20), 0, rng.randf_range(-45, 20))
		if abs(p.x) < 4 or (abs(p.z + 12) < 4 and p.x > 0):
			continue
		add_rock(p, rng.randf_range(0.6, 1.6))
	add_wall(Vector3(-35, 0, -55), Vector3(-35, 0, 25))
	add_wall(Vector3(35, 0, -55), Vector3(35, 0, -16))
	add_wall(Vector3(35, 0, -8), Vector3(35, 0, 25))
	add_wall(Vector3(-35, 0, 25), Vector3(-5, 0, 25))
	add_wall(Vector3(5, 0, 25), Vector3(35, 0, 25))
	add_wall(Vector3(-35, 0, -55), Vector3(-5, 0, -55))
	add_wall(Vector3(5, 0, -55), Vector3(35, 0, -55))
	add_sign(Vector3(2.5, 0, 14), "Norte: Templo de Martel.\nSur: Aldea de Iselia.\nEste: Rancho humano de Iselia. PROHIBIDO EL PASO.")
	add_chest("forest1", Vector3(-10, 0, -20), "orange_gel")
	add_npc("villager1", Vector3(-3, 0, 12), "Aldeano", "frank",
		[{"speaker": "Aldeano", "text": "Ten cuidado en el bosque, Lloyd. Últimamente los lobos se acercan mucho al camino."},
		 {"speaker": "Lloyd", "text": "Tranquilo, unos lobos no son nada para mí."}])
	add_monster(Vector3(-4, 0, -2), ["wolf"])
	add_monster(Vector3(5, 0, -12), ["wolf", "wolf"])
	add_monster(Vector3(-3, 0, -24), ["rabbit", "rabbit", "bee"])
	add_monster(Vector3(4, 0, -36), ["wolf", "rabbit", "bee"])
	add_monster(Vector3(22, 0, -10), ["wolf", "bee"])
	add_exit(Vector3(0, 1, 26), Vector3(10, 3, 1.5), "iselia_village", "from_forest")
	add_exit(Vector3(0, 1, -56), Vector3(10, 3, 1.5), "martel_temple_ext", "default")
	add_exit(Vector3(36, 1, -12), Vector3(1.5, 3, 8), "iselia_ranch", "default",
		func(): return Game.get_flag("temple_done", false) and not Game.get_flag("ranch_visited", false),
		[{"speaker": "Lloyd", "text": "Por ahí se va al rancho de los desianos. El alcalde nos mataría si nos acercáramos..."}] if not Game.get_flag("ranch_visited", false) else
		[{"speaker": "Lloyd", "text": "No deberíamos volver al rancho. Ya nos han visto una vez."}])

func on_enter(c: Cutscene) -> void:
	if c.has("temple_done") and not c.has("ranch_visited") and not c.has("genis_ran_off") and Game.spawn_point == "from_temple":
		await _genis_runs_off(c)

func _genis_runs_off(c: Cutscene) -> void:
	c.flag("genis_ran_off")
	c.spawn("genis", "genis", Vector3(1.5, 0, -44), 0.0, "Genis")
	await c.walk("player", Vector3(0, 0, -24), 4.0, true, false)
	await c.walk("genis", Vector3(1.5, 0, -22), 4.0, true)
	await c.script("iselia_forest.genis_runs_off.01", [
		{"speaker": "Genis", "text": "Lloyd... ¿puedo pedirte un favor? Tengo que ir a un sitio antes de volver a la aldea. Tú sigue sin mí."},
		{"speaker": "Lloyd", "text": "¿Ir adónde? Por aquí solo está... Genis, ¿no estarás pensando en el rancho?"},
		{"speaker": "Genis", "text": "¡No! Bueno... Es que hay alguien allí. Una anciana. Marble. Hablo con ella a través de la valla. No le hago daño a nadie."},
		{"speaker": "Lloyd", "text": "¡Genis! ¡Si los desianos te ven, te meterán dentro con ella!"},
		{"speaker": "Genis", "text": "¡Lo sé! Pero hoy está muy débil y quiero llevarle algo de comer. Solo será un momento. ¡Lo siento!"},
	])
	await c.run_to("genis", Vector3(30, 0, -12))
	c.despawn("genis")
	await c.script("iselia_forest.genis_runs_off.02", [
		{"speaker": "Lloyd", "text": "¡Genis, espera! ...Maldita sea. No puedo dejarlo ir solo."},
	])
	await c.caption("Sigue a Genis hacia el este, al Rancho humano de Iselia.", 2.2)
