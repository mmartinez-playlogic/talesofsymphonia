extends Field
## Iselia, village of the oracle. Day 1: Frank; after the temple: Colette's house, Genis' house, the gate.
## Day 2: Colette's letter, the Desian raid, Forcystus and the monster, the exile.

func build() -> void:
	map_id = "iselia_village"
	map_title = "Iselia · Aldea del Oráculo"
	spawns["default"] = Vector3(0, 0.1, 20)
	spawns["from_world"] = Vector3(0, 0.1, 24)
	spawns["from_forest"] = Vector3(0, 0.1, -26)
	spawns["from_school"] = Vector3(-14, 0.1, 1)
	spawn_yaw["from_forest"] = 0.0
	spawn_yaw["from_school"] = 0.0
	var raid: bool = Game.get_flag("raid_started", false) and not Game.get_flag("exiled", false)
	add_ground(Vector2(80, 70), Color(0.36, 0.58, 0.3) if not raid else Color(0.3, 0.3, 0.26))
	add_path([Vector3(0, 0, 30), Vector3(0, 0, 0), Vector3(0, 0, -30)], 4.0)
	add_path([Vector3(-16, 0, 0), Vector3(16, 0, 0)], 3.0)
	add_patch(Vector3(0, 0, 0), Vector2(10, 10), Color(0.7, 0.62, 0.45), 0.03)
	add_box(Vector3(0, 0, 0), Vector3(1.2, 1.0, 1.2), Color(0.55, 0.55, 0.6))
	add_building(Vector3(-14, 0, -8), Vector3(9, 4, 7), Color(0.9, 0.85, 0.7), Color(0.6, 0.3, 0.2))    # school
	add_building(Vector3(14, 0, -10), Vector3(8, 4, 7), Color(0.92, 0.9, 0.82), Color(0.4, 0.5, 0.7))   # Colette's house
	if not (raid or Game.get_flag("exiled", false)):
		add_building(Vector3(-16, 0, 8), Vector3(7, 3.5, 6), Color(0.85, 0.8, 0.65), Color(0.5, 0.35, 0.25))  # Genis & Raine
	else:
		add_box(Vector3(-16, 0, 8), Vector3(7, 1.2, 6), Color(0.2, 0.18, 0.15))  # burnt down
	add_building(Vector3(16, 0, 8), Vector3(8, 4.5, 7), Color(0.88, 0.82, 0.7), Color(0.35, 0.3, 0.45))   # mayor
	add_building(Vector3(-8, 0, 18), Vector3(6, 3.5, 5), Color(0.8, 0.75, 0.6), Color(0.55, 0.4, 0.2))    # shop
	add_building(Vector3(9, 0, 18), Vector3(6, 3.5, 5), Color(0.8, 0.75, 0.6), Color(0.55, 0.4, 0.2))     # house
	if raid:
		for p in [Vector3(-6, 0, -14), Vector3(12, 0, 14), Vector3(-10, 0, 24)]:
			add_light(p + Vector3(0, 2, 0), Color(1.0, 0.45, 0.15), 4.0, 12)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 40:
		var x := rng.randf_range(-38, 38)
		var z := rng.randf_range(-33, 33)
		if abs(x) < 22 and abs(z) < 24:
			continue
		add_tree(Vector3(x, 0, z), rng.randf_range(0.9, 1.5))
	add_wall(Vector3(-40, 0, -35), Vector3(-40, 0, 35))
	add_wall(Vector3(40, 0, -35), Vector3(40, 0, 35))
	add_wall(Vector3(-40, 0, -35), Vector3(-5, 0, -35), 3.0, true, Color(0.55, 0.42, 0.3))
	add_wall(Vector3(5, 0, -35), Vector3(40, 0, -35), 3.0, true, Color(0.55, 0.42, 0.3))
	add_wall(Vector3(-40, 0, 35), Vector3(-5, 0, 35), 3.0, true, Color(0.55, 0.42, 0.3))
	add_wall(Vector3(5, 0, 35), Vector3(40, 0, 35), 3.0, true, Color(0.55, 0.42, 0.3))
	add_sign(Vector3(3, 0, 26), "Iselia, aldea del Oráculo.\nNorte: bosque y Templo de Martel.\nSur: camino a la casa de Dirk.")
	add_chest("plaza", Vector3(20, 0, -2), "apple_gel", 2)
	add_exit(Vector3(0, 1, -36), Vector3(10, 3, 1.5), "iselia_forest", "from_village",
		func(): return Game.get_flag("frank_talked", false) and not raid,
		[{"speaker": "Lloyd", "text": "Antes de salir deberíamos ver qué pasa en la aldea. Está todo demasiado silencioso."}])
	add_exit(Vector3(0, 1, 36), Vector3(10, 3, 1.5), "world_sylvarant", "iselia",
		func(): return Game.get_flag("colette_house_done", false) and not raid,
		[{"speaker": "Lloyd", "text": "Primero tengo que acompañar a Colette al templo."}])
	add_exit(Vector3(-14, 1, -3.8), Vector3(2, 3, 1.0), "iselia_school", "from_village",
		func(): return not Game.get_flag("temple_done", false), [{"speaker": "Lloyd", "text": "Hoy ya no hay más clase."}])
	if raid:
		add_monster(Vector3(-4, 0, 6), ["desian_soldier", "desian_soldier"])
		add_monster(Vector3(8, 0, -8), ["desian_soldier", "desian_whip"])
		add_npc("gate_villager", Vector3(-12, 0, -2), "Aldeano", "frank", [], 90.0)
		npc("gate_villager").on_interact = func(_f): await _save_villager(cs)
	add_interactable("colette_door", Vector3(14, 0, -6.3), Vector3(1.4, 2.0, 0.3), Color(0.35, 0.22, 0.12), _colette_door)
	add_interactable("genis_door", Vector3(-16, 0, 11.2), Vector3(1.4, 2.0, 0.3), Color(0.35, 0.22, 0.12), _genis_door)
	_populate(raid)

func _populate(raid: bool) -> void:
	var exiled: bool = Game.get_flag("exiled", false)
	var temple_done: bool = Game.get_flag("temple_done", false)
	var frank_talked: bool = Game.get_flag("frank_talked", false)
	if raid:
		return
	if exiled:
		add_npc("villager_a", Vector3(-6, 0, 4), "Aldeano", "frank",
			[{"speaker": "Aldeano", "text": "...Por favor, marchaos. El alcalde ha dicho que no podéis estar aquí."}])
		add_npc("frank", Vector3(13, 0, -5), "Frank", "frank",
			[{"speaker": "Frank", "text": "Lloyd... Sé que no es justo. Cuida de Colette. Y de Genis."}])
		return
	if not frank_talked:
		return  # everyone is hiding from the Desians
	if not temple_done:
		add_npc("frank", Vector3(13, 0, -5), "Frank", "frank",
			[{"speaker": "Frank", "text": "Os esperaré en casa. Cuidad de Colette, por favor."}])
		return
	add_npc("villager_a", Vector3(-6, 0, 4), "Aldeano", "frank",
		[{"speaker": "Aldeano", "text": "Dicen que la Torre de la Salvación ha aparecido en el cielo. ¡La Elegida va a salvarnos!"}])
	add_npc("villager_b", Vector3(6, 0, 12), "Aldeana", "marble",
		[{"speaker": "Aldeana", "text": "Gracias al tratado con el rancho, los desianos no nos atacan. Pero no me gusta tenerlos tan cerca..."}], 180.0)
	add_npc("merchant", Vector3(-8, 0, 15), "Mercader", "botta",
		[{"speaker": "Mercader", "text": "Geles de manzana, geles de naranja... Hoy no abro, chico. Todo el mundo está celebrando el oráculo."}])
	add_npc("gate_villager", Vector3(-4, 0, -28), "Aldeano", "frank", [], 0.0)
	npc("gate_villager").on_interact = func(_f): await _gate_talk(cs)
	if Game.get_flag("colette_house_done", false) and not Game.get_flag("ranch_visited", false):
		add_npc("noishe", Vector3(-1, 0, -29), "Noishe", "wolf", [{"speaker": "Noishe", "text": "¡Guau! ¡Guau!"}, {"speaker": "Lloyd", "text": "Vale, vale. Ya nos vamos, Noishe."}])

func on_enter(c: Cutscene) -> void:
	if not c.has("frank_talked") and c.has("oracle_seen"):
		await _frank(c)
	elif c.has("night_dirk") and not c.has("raid_started") and Game.spawn_point == "from_world":
		await _letter(c)
	elif c.has("raid_started") and not c.has("exiled") and not c.has("raid_fight_done"):
		await _raid(c)

func on_resume(c: Cutscene, event: String) -> void:
	match event:
		"after_raid_soldiers":
			await _forcystus(c)
		"after_exbelua":
			await _marble_death(c)

func on_return(c: Cutscene) -> void:
	if c.has("raid_started") and not c.has("raid_fight_done") and defeated_count() >= 2:
		c.flag("raid_fight_done")
		await _forcystus_approach(c)

# ---------- Day 1: Frank outside the school ----------
func _frank(c: Cutscene) -> void:
	c.spawn("genis", "genis", Vector3(-15.5, 0, 0), 180.0, "Genis")
	c.spawn("colette", "colette", Vector3(-12.5, 0, 0), 180.0, "Colette")
	c.spawn("frank", "frank", Vector3(-8, 0, 6), 300.0, "Frank")
	await c.walk("frank", Vector3(-12, 0, 3), 3.5)
	c.face_each_other("player", "frank")
	await c.script("iselia_village.frank.01", [
		{"speaker": "Genis", "text": "Qué raro... No hay nadie en la calle."},
		{"speaker": "Frank", "text": "¡Colette! ¡Lloyd, Genis! Todo el mundo está escondido. Los desianos han entrado en la aldea hace un rato."},
		{"speaker": "Lloyd", "text": "¡¿Desianos?! ¿Han hecho daño a alguien?"},
		{"speaker": "Frank", "text": "No. Han pasado de largo, hacia el templo."},
		{"speaker": "Genis", "text": "Pero Iselia tiene un tratado de no agresión con los desianos..."},
		{"speaker": "Lloyd", "text": "Sí: ellos no atacan la aldea mientras nosotros no nos acerquemos al rancho humano."},
		{"speaker": "Colette", "text": "Mi abuela dice que es para protegerme."},
		{"speaker": "Frank", "text": "Phaidra está en el templo preparando el ritual con los sacerdotes. Colette, cumple con tu deber. Lloyd, Genis: vosotros a casa."},
		{"speaker": "Lloyd", "text": "Ni hablar. Yo acompaño a Colette."},
		{"speaker": "Genis", "text": "Y yo. Si Lloyd va, yo también."},
		{"speaker": "Frank", "text": "...Está bien. Os esperaré en casa. Tened cuidado."},
	])
	c.flag("frank_talked")
	await c.walk("frank", Vector3(13, 0, -5), 4.0, true)
	c.despawn("genis")
	c.despawn("colette")
	await c.caption("Al Templo de Martel, al norte de la aldea.", 2.0)

# ---------- After the temple: Colette's house ----------
func _colette_door(c: Cutscene) -> void:
	if not c.has("temple_done") or c.has("colette_house_done"):
		await c.line("", "La casa de Colette. " + ("Colette está dentro con su familia." if not c.has("colette_house_done") else "No hay nadie."))
		return
	await c.fade_out()
	c.teleport("player", Vector3(14, 0.1, -3), 180.0)
	c.spawn("colette", "colette", Vector3(12.5, 0, -5), 160.0, "Colette")
	c.spawn("kratos", "kratos", Vector3(16, 0, -5.5), 200.0, "Kratos")
	c.spawn("phaidra", "phaidra", Vector3(15, 0, -7), 180.0, "Phaidra")
	c.spawn("frank", "frank", Vector3(11, 0, -6.5), 150.0, "Frank")
	c.spawn("mayor", "mayor", Vector3(17.5, 0, -3.5), 250.0, "Alcalde")
	c.spawn("genis", "genis", Vector3(12.5, 0, -2), 180.0, "Genis")
	await c.fade_in()
	await c.script("iselia_village.colette_house.01", [
		{"speaker": "Kratos", "text": "...Entonces, partiremos mañana. No tengo objeciones."},
		{"speaker": "Phaidra", "text": "Gracias, Kratos. Y gracias a vosotros dos. Sin vuestra ayuda, Colette no habría llegado al altar."},
	])
	await c.give_item("orange_gel", 2)
	await c.script("iselia_village.colette_house.02", [
		{"speaker": "Lloyd", "text": "Phaidra, Kratos... Yo también quiero ir en el viaje de regeneración."},
		{"speaker": "Genis", "text": "Y yo, si Raine va."},
		{"speaker": "Kratos", "text": "No. Solo seríais un estorbo. Lo del templo no ha sido nada comparado con lo que nos espera."},
		{"speaker": "Kratos", "text": "Los niños se quedan en casa."},
		{"speaker": "Alcalde", "text": "Kratos tiene toda la razón. Lloyd, Genis: a casa. La Elegida ya tiene quien la proteja."},
	])
	await c.fade_out()
	c.despawn("kratos")
	c.despawn("phaidra")
	c.despawn("frank")
	c.despawn("mayor")
	c.teleport("player", Vector3(12, 0.1, 0), 90.0)
	c.teleport("colette", Vector3(14.5, 0, 0), 270.0)
	c.teleport("genis", Vector3(12, 0, 2), 30.0)
	await c.fade_in()
	await c.script("iselia_village.colette_house.03", [
		{"speaker": "Colette", "text": "Lo siento, Lloyd... Kratos es muy estricto."},
		{"speaker": "Genis", "text": "Bueno, cambiando de tema: ¡feliz cumpleaños, Colette! Te he hecho galletas."},
		{"speaker": "Colette", "text": "¡Gracias, Genis! ¡Qué bien huelen!", "mood": "happy"},
		{"speaker": "Lloyd", "text": "Ah... Colette, el collar que te prometí... todavía no lo he terminado. Te lo daré mañana, antes de que os vayáis."},
		{"speaker": "Colette", "text": "Vale. Mañana vendré a decirte a qué hora salimos."},
		{"speaker": "Genis", "text": "...Mentiroso."},
		{"speaker": "Lloyd", "text": "¡Que lo tengo casi acabado!"},
		{"speaker": "Genis", "text": "Lloyd, ¿me acompañas un rato? Tengo que ir a ver a una amiga fuera de la aldea. Antes paso por casa a coger mis cosas."},
	])
	c.flag("colette_house_done")
	c.despawn("colette")
	c.despawn("genis")
	await c.caption("Pasa por la casa de Genis y Raine (oeste) antes de salir por la puerta norte.", 2.4)

func _genis_door(c: Cutscene) -> void:
	if not c.has("colette_house_done"):
		await c.line("", "La casa de Genis y Raine.")
		return
	if c.has("genis_house_done"):
		await c.line("Genis", "Ya lo tengo todo. Vamos a la puerta norte.")
		return
	c.flag("genis_house_done")
	await c.script("iselia_village.genis_house.01", [
		{"speaker": "Genis", "text": "Espera, que cojo los ingredientes. Ya sabes que no podemos usar artes curativas, así que hay que cocinar bien."},
		{"speaker": "Lloyd", "text": "¿Cocinar? Yo con un Gel de Manzana voy servido."},
		{"speaker": "Genis", "text": "Los Geles de Manzana no son baratos, Lloyd. Listo, vámonos."},
	])
	await c.caption("Receta aprendida: Sándwich. (Cocina: menú de pausa, próximamente.)", 2.0)

func _gate_talk(c: Cutscene) -> void:
	if not c.has("genis_house_done") or c.has("gate_done"):
		await c.line("Aldeano", "Por aquí se va al bosque y al templo. Y al rancho, pero ni se os ocurra.")
		return
	c.flag("gate_done")
	await c.script("iselia_village.gate.01", [
		{"speaker": "Aldeano", "text": "¡Lloyd! Haz algo con tu mascota. Noishe ha entrado en la aldea buscándote y ha asustado a medio pueblo."},
		{"speaker": "Lloyd", "text": "¡Noishe! ¿Qué haces aquí?"},
		{"speaker": "Aldeano", "text": "Y el alcalde pregunta: ¿habéis estado jugando cerca del rancho humano, en el bosque?"},
		{"speaker": "Lloyd", "text": "¿Nosotros? ¡Qué va!"},
		{"speaker": "Genis", "text": "N-no, para nada..."},
		{"speaker": "Aldeano", "text": "Más os vale. Y mantened a ese bicho lejos del rancho también."},
		{"speaker": "Lloyd", "text": "Noishe es un perro, ¿vale? Un perro."},
	])

# ---------- Day 2: the letter and the raid ----------
func _letter(c: Cutscene) -> void:
	c.teleport("player", Vector3(0, 0.1, 24), 180.0)
	c.spawn("genis", "genis", Vector3(-1.5, 0, 26), 180.0, "Genis")
	await c.run_to("player", Vector3(12, 0, -3), false)
	await c.run_to("genis", Vector3(10.5, 0, -2))
	c.spawn("phaidra", "phaidra", Vector3(14, 0, -5), 0.0, "Phaidra")
	c.spawn("frank", "frank", Vector3(16, 0, -5), 0.0, "Frank")
	c.face("player", Vector3(14, 0, -5))
	await c.script("iselia_village.letter.01", [
		{"speaker": "Lloyd", "text": "¡Phaidra! ¡Colette! ¿Dónde está?"},
		{"speaker": "Phaidra", "text": "Lloyd... Colette ya se ha ido. Partieron hace horas."},
		{"speaker": "Frank", "text": "Me pidió que te diera esto."},
	])
	await c.give_item("colette_letter")
	await c.script("iselia_village.letter.02", [
		{"speaker": "Colette", "text": "«Querido Lloyd: cuando leas esto ya me habré ido. Siento haberte mentido. El viaje es peligroso y muchos Elegidos han fracasado. Te aprecio demasiado para meterte en esto.»"},
		{"speaker": "Colette", "text": "«Acabaré con los monstruos y con los desianos para que puedas vivir feliz en el mundo regenerado. Gracias por tu amistad. He tenido mucha suerte de conocerte. Adiós. Colette.»"},
		{"speaker": "Lloyd", "text": "Esto... parece un testamento."},
		{"speaker": "Frank", "text": "Podría decirse así. Lloyd, hay algo que debes saber. Colette... no, la Elegida... ya está..."},
	])
	await c.shake_camera(0.5, 0.8)
	await c.flash(Color(1, 0.5, 0.3), 0.6)
	await c.script("iselia_village.letter.03", [
		{"speaker": "Genis", "text": "¡¿Qué ha sido eso?! ¡Una explosión!"},
		{"speaker": "Phaidra", "text": "¡Humo! ¡La aldea está ardiendo!"},
		{"speaker": "Lloyd", "text": "¡Desianos! ¡Phaidra, Frank, escondeos! ¡Genis, conmigo!"},
	])
	c.flag("raid_started")
	c.despawn("genis")
	Game.last_field_position = Vector3.ZERO
	await c.fade_out()
	Router.goto_map("iselia_village", "default")

func _raid(c: Cutscene) -> void:
	# burning village: monsters are Desian squads; a villager near the school needs help
	c.teleport("player", Vector3(0, 0.1, 20), 180.0)
	c.spawn("genis", "genis", Vector3(-1.5, 0, 22), 180.0, "Genis")
	await c.script("iselia_village.raid.01", [
		{"speaker": "Genis", "text": "¡Están por todas partes! ¡Todavía hay gente en la plaza!"},
		{"speaker": "Lloyd", "text": "¡Acabemos con ellos y saquemos a todo el mundo de aquí!"},
	])
	c.despawn("genis")

func _save_villager(c: Cutscene) -> void:
	if c.has("villager_saved"):
		await c.line("Aldeano", "¡Corred! ¡Están en la plaza!")
		return
	c.flag("villager_saved")
	await c.script("iselia_village.raid.02", [
		{"speaker": "Aldeano", "text": "¡Lloyd! Gracias... pensaba que no salía de esta. Tomad, es lo único que tengo."},
	])
	await c.give_item("apple_gel")
	await c.give_item("orange_gel")

func _forcystus_approach(c: Cutscene) -> void:
	c.spawn("genis", "genis", field_pos_near_player(), 0.0, "Genis")
	await c.script("iselia_village.raid.03", [
		{"speaker": "Genis", "text": "Nuestra casa... La casa de Raine y mía. La han quemado."},
		{"speaker": "Genis", "text": "Y pensar que por fin empezaba a parecer un lugar al que podríamos llamar hogar..."},
		{"speaker": "Lloyd", "text": "¿Qué? ¿Qué quieres decir?"},
		{"speaker": "Genis", "text": "¡N-nada! ¡Vamos a la plaza! ¡La gente sigue allí!"},
	])
	c.despawn("genis")
	await c.caption("Ve a la plaza central.", 1.8)
	add_trigger(Vector3(0, 1, 2), Vector3(12, 3, 10), _plaza, "plaza_trigger")

func field_pos_near_player() -> Vector3:
	return player.global_position + Vector3(-1.5, 0, 1.0)

func _plaza(c: Cutscene) -> void:
	c.teleport("player", Vector3(0, 0.1, 6), 180.0)
	c.spawn("genis", "genis", Vector3(-1.5, 0, 7), 180.0, "Genis")
	c.spawn("forcystus", "forcystus", Vector3(0, 0, -8), 0.0, "Forcystus")
	c.spawn("desian1", "desian", Vector3(-3, 0, -6), 0.0, "Desiano")
	c.spawn("desian2", "desian", Vector3(3, 0, -6), 0.0, "Desiano")
	for i in 3:
		c.spawn("hostage%d" % i, ["frank", "marble", "botta"][i], Vector3(-6 + i * 6, 0, -2), 0.0, "Aldeano")
	await c.look_at_actor("forcystus", 0.8)
	await c.script("iselia_village.plaza.01", [
		{"speaker": "Forcystus", "text": "Soy Forcystus, uno de los Cinco Grandes Cardenales desianos. Un semielfo superior, señor del rancho que domina esta región."},
		{"speaker": "Forcystus", "text": "Tú, humano, Lloyd Irving, eres culpable de violar el tratado de no agresión. Yo traigo el castigo sobre ti y sobre esta aldea."},
		{"speaker": "Genis", "text": "¡Vosotros también lo violasteis! ¡Intentasteis matar a la Elegida en el templo!"},
		{"speaker": "Forcystus", "text": "¿Nosotros? ¿Matar a la Elegida? Ja, ja, ja..."},
		{"speaker": "Desiano", "text": "Así que son ELLOS los que van tras la Elegida..."},
		{"speaker": "Forcystus", "text": "Lloyd Irving: contactaste con el cuerpo huésped F192 y atacaste a mis guardias. Te he preparado un adversario adecuado."},
	])
	c.spawn("exbelua", "zombie", Vector3(3, 0, -5), 0.0, "Exbelua")
	var ex := c.actor("exbelua")
	if ex:
		ex.scale = Vector3.ONE * 2.0
	await c.look_at_actor("exbelua", 0.6)
	await c.script("iselia_village.plaza.02", [
		{"speaker": "Genis", "text": "¡¿Qué es esa cosa?!"},
		{"speaker": "Lloyd", "text": "¡Da igual lo que sea! ¡Genis, prepárate!"},
	])
	await c.camera_reset(0.3)
	c.despawn("genis")
	c.despawn("exbelua")
	await c.battle(["exbelua"], "after_exbelua")
	return

func _forcystus(c: Cutscene) -> void:
	await _plaza(c)

func _marble_death(c: Cutscene) -> void:
	c.teleport("player", Vector3(0, 0.1, 4), 180.0)
	c.spawn("genis", "genis", Vector3(-1.5, 0, 5), 180.0, "Genis")
	c.spawn("forcystus", "forcystus", Vector3(0, 0, -8), 0.0, "Forcystus")
	c.spawn("desian1", "desian", Vector3(-3, 0, -6), 0.0, "Desiano")
	c.spawn("exbelua", "zombie", Vector3(2.5, 0, -3), 0.0, "Exbelua")
	var ex := c.actor("exbelua")
	if ex:
		ex.scale = Vector3.ONE * 2.0
	c.anim("exbelua", "Hit_Chest")
	await c.wait(0.6)
	await c.script("iselia_village.marble.01", [
		{"speaker": "Desiano", "text": "¡Lord Forcystus! ¡El chico lleva una Exsfera!"},
		{"speaker": "Forcystus", "text": "¿Una Exsfera...? Tiene que ser la del Proyecto Angelus. La que llevamos tanto tiempo buscando."},
		{"speaker": "Lloyd", "text": "¡Es el recuerdo de mi madre! ¡La madre que vosotros asesinasteis!"},
		{"speaker": "Forcystus", "text": "¿Tu madre? Tu madre era..."},
		{"speaker": "Marble", "text": "...A... lejaos... Genis... Lloyd... alejaos de mí..."},
		{"speaker": "Genis", "text": "¿Esa voz? ¡¿Marble?! ¡No! ¡¿Qué le habéis hecho?!"},
		{"speaker": "Marble", "text": "Genis... has sido como un nieto para mí. Gracias... Adiós..."},
	])
	await c.flash(Color(1, 1, 1), 1.2)
	await c.shake_camera(0.5, 0.8)
	c.despawn("exbelua")
	c.despawn("desian1")
	c.anim("forcystus", "Hit_Knockback")
	await c.script("iselia_village.marble.02", [
		{"speaker": "Forcystus", "text": "¡Aaargh...! Maldita... vieja..."},
		{"speaker": "Desiano", "text": "¡Lord Forcystus está herido! ¡Retirada!"},
		{"speaker": "Forcystus", "text": "Lloyd Irving... Mientras tengas esa Exsfera, iremos a por ti. ¡Siempre!"},
	])
	await c.walk("forcystus", Vector3(0, 0, -34), 4.0, true)
	c.despawn("forcystus")
	await c.give_item("marble_exsphere")
	await c.script("iselia_village.marble.03", [
		{"speaker": "Genis", "text": "Marble... ¡Marble!"},
		{"speaker": "Lloyd", "text": "Genis... Lo siento. Lo siento mucho."},
	])
	await _exile(c)

func _exile(c: Cutscene) -> void:
	c.spawn("mayor", "mayor", Vector3(6, 0, -3), 270.0, "Alcalde")
	c.spawn("frank", "frank", Vector3(-6, 0, -3), 90.0, "Frank")
	c.spawn("phaidra", "phaidra", Vector3(-8, 0, -1), 90.0, "Phaidra")
	c.spawn("villager_a", "botta", Vector3(8, 0, 3), 270.0, "Aldeano")
	c.spawn("villager_b", "marble", Vector3(-8, 0, 3), 90.0, "Aldeana")
	c.spawn("noishe", "wolf", Vector3(2, 0, 12), 0.0, "Noishe")
	await c.wait(0.5)
	await c.script("iselia_village.exile.01", [
		{"speaker": "Alcalde", "text": "Pedir perdón no arregla esto. Los desianos te han marcado como su enemigo, Lloyd. Mientras estés aquí, la aldea nunca tendrá paz."},
		{"speaker": "Genis", "text": "¿Lo está desterrando?"},
		{"speaker": "Alcalde", "text": "Sí. Cualquier contacto con el rancho está prohibido. Sin excepciones."},
		{"speaker": "Genis", "text": "¿Entonces está bien dejar morir a los prisioneros del rancho mientras la aldea esté a salvo?"},
		{"speaker": "Aldeano", "text": "Los del rancho van a morir igualmente."},
		{"speaker": "Alcalde", "text": "Si Lloyd no hubiera hecho semejante estupidez, solo habrían muerto ellos."},
		{"speaker": "Genis", "text": "Los humanos sois todos iguales..."},
		{"speaker": "Lloyd", "text": "¡Genis, basta! La culpa es mía. Me iré."},
		{"speaker": "Aldeana", "text": "Alcalde, ¿no está siendo demasiado duro? Son unos niños..."},
		{"speaker": "Aldeano", "text": "¿Y cuántos han muerto por su culpa? ¡Mira la aldea!"},
		{"speaker": "Alcalde", "text": "Además, Lloyd ni siquiera es de aquí. Es un forastero criado por un enano."},
		{"speaker": "Genis", "text": "Entonces yo también me voy. Soy tan culpable como él."},
		{"speaker": "Alcalde", "text": "Como queráis. Lloyd Irving, Genis Sage: quedáis desterrados de Iselia."},
	])
	await c.script("iselia_village.exile.02", [
		{"speaker": "Phaidra", "text": "Lloyd, Genis... Si el mundo se salva, todos cambiarán de opinión. Es lo que Colette querría."},
		{"speaker": "Lloyd", "text": "Expiaré lo que he hecho. Protegeré a Colette, por todos los que han muerto por mi culpa."},
		{"speaker": "Genis", "text": "Y yo estaré siempre a tu lado, Lloyd."},
		{"speaker": "Lloyd", "text": "Genis, toma. La Exsfera de Marble. Úsala tú. Luego te explico lo de la Cresta Clave."},
		{"speaker": "Genis", "text": "...Gracias, Lloyd. La llevaré por ella."},
		{"speaker": "Noishe", "text": "¡Guau!"},
		{"speaker": "Phaidra", "text": "No tiréis vuestras vidas por la borda."},
		{"speaker": "Frank", "text": "Que Martel os proteja."},
	])
	Game.add_item("marble_exsphere", -1)
	Game.members["genis"]["equipment"]["acc1"] = "exsphere"
	c.flag("exiled")
	Game.heal_all()
	c.despawn("genis")
	await c.caption("Lloyd y Genis han sido desterrados de Iselia. Destino: el desierto de Triet, al sur.", 2.6)
	await c.fade_out()
	Game.last_field_position = Vector3.ZERO
	Router.goto_map("world_sylvarant", "iselia")
