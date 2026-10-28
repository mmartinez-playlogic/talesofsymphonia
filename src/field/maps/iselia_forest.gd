extends Field
## Iselia Forest: the path to the Martel Temple (north) and the branch to the Desian ranch (east).

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
	add_monster(Vector3(-4, 0, -2), ["wolf"])
	add_monster(Vector3(5, 0, -12), ["ghost", "zombie"])
	add_monster(Vector3(-3, 0, -24), ["rabbit", "rabbit", "bee"])
	add_monster(Vector3(4, 0, -36), ["wolf", "rabbit", "bee"])
	add_monster(Vector3(22, 0, -10), ["wolf", "bee"])
	add_exit(Vector3(0, 1, 26), Vector3(10, 3, 1.5), "iselia_village", "from_forest")
	add_exit(Vector3(0, 1, -56), Vector3(10, 3, 1.5), "martel_temple_ext", "default")
	add_exit(Vector3(36, 1, -12), Vector3(1.5, 3, 8), "iselia_ranch", "default",
		func(): return Game.get_flag("noishe_ran_off", false) and not Game.get_flag("ranch_visited", false),
		[{"speaker": "Lloyd", "text": "Por ahí se va al rancho de los desianos. Ni se nos ocurra acercarnos."}] if not Game.get_flag("ranch_visited", false) else
		[{"speaker": "Lloyd", "text": "No deberíamos volver al rancho. Ya nos han visto una vez."}])

func on_enter(c: Cutscene) -> void:
	if c.has("colette_house_done") and not c.has("noishe_ran_off") and Game.spawn_point == "from_village":
		await _noishe(c)

## Tutorial talk after the first fight on the temple path (Exsphere, magic vs spirits).
func on_return(c: Cutscene) -> void:
	if not c.has("temple_arrived"):
		if not c.has("forest_fight_1"):
			c.flag("forest_fight_1")
			await c.script("iselia_forest.first_fight.01", [
				{"speaker": "Colette", "text": "¡Lloyd, has estado increíble!"},
				{"speaker": "Lloyd", "text": "Es gracias a mi Exsfera. Está hecha para el combate: saca toda mi fuerza."},
				{"speaker": "Genis", "text": "Al menos con la espada se defiende..."},
				{"speaker": "Colette", "text": "Aquí al norte es terreno sagrado y aun así hay monstruos. Debe de ser parte de la prueba de Martel."},
			])
		elif not c.has("forest_fight_2"):
			c.flag("forest_fight_2")
			await c.script("iselia_forest.second_fight.01", [
				{"speaker": "Colette", "text": "Raine dice que la magia funciona mejor contra los monstruos espirituales, como los fantasmas."},
				{"speaker": "Genis", "text": "Entonces yo me encargo de los fantasmas y Lloyd de los zombis. Lloyd, cambia de objetivo con el botón de selección."},
				{"speaker": "Lloyd", "text": "¡Entendido!"},
			])

func _noishe(c: Cutscene) -> void:
	c.flag("noishe_ran_off")
	c.spawn("genis", "genis", Vector3(1.5, 0, 20), 180.0, "Genis")
	c.spawn("noishe", "wolf", Vector3(-2, 0, 21), 180.0, "Noishe")
	await c.walk("player", Vector3(0, 0, 10), 3.5, false, false)
	await c.walk("genis", Vector3(1.5, 0, 12), 3.5, false, false)
	await c.walk("noishe", Vector3(-2, 0, 14), 3.5)
	await c.script("iselia_forest.noishe.01", [
		{"speaker": "Noishe", "text": "¡Guau... guau...!"},
		{"speaker": "Lloyd", "text": "¿Qué pasa, Noishe? Ah, ya. No quieres entrar en el bosque. Siempre huyes de los sitios con monstruos."},
	])
	await c.run_to("noishe", Vector3(-3, 0, 24))
	c.despawn("noishe")
	await c.script("iselia_forest.noishe.02", [
		{"speaker": "Lloyd", "text": "Genis... tu amiga. ¿Dónde está exactamente?"},
		{"speaker": "Genis", "text": "...En el rancho humano de los desianos."},
		{"speaker": "Lloyd", "text": "¡¿En el rancho?! ¡Eso viola el tratado!"},
		{"speaker": "Genis", "text": "¡Los desianos ya lo han violado atacando el templo! Lloyd, solo voy a verla un momento. Puedes volver si quieres."},
		{"speaker": "Lloyd", "text": "...Voy contigo. No pienso dejarte ir solo."},
	])
	c.despawn("genis")
	await c.caption("El rancho está al este, por el desvío del bosque.", 2.2)
