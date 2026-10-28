extends Field
## Iselia, the village of the oracle. Day 1 (going to the temple) and day 2 (Desian raid, exile).

func build() -> void:
	map_id = "iselia_village"
	map_title = "Iselia · Aldea del Oráculo"
	spawns["default"] = Vector3(0, 0.1, 20)
	spawns["from_world"] = Vector3(0, 0.1, 24)
	spawns["from_forest"] = Vector3(0, 0.1, -26)
	spawns["from_school"] = Vector3(-14, 0.1, -2)
	spawn_yaw["from_forest"] = 0.0
	spawn_yaw["from_school"] = 0.0
	add_ground(Vector2(80, 70), Color(0.36, 0.58, 0.3))
	add_path([Vector3(0, 0, 30), Vector3(0, 0, 0), Vector3(0, 0, -30)], 4.0)
	add_path([Vector3(-16, 0, 0), Vector3(16, 0, 0)], 3.0)
	add_patch(Vector3(0, 0, 0), Vector2(10, 10), Color(0.7, 0.62, 0.45), 0.03)  # plaza
	add_box(Vector3(0, 0, 0), Vector3(1.2, 1.0, 1.2), Color(0.55, 0.55, 0.6))      # well
	# buildings
	add_building(Vector3(-14, 0, -8), Vector3(9, 4, 7), Color(0.9, 0.85, 0.7), Color(0.6, 0.3, 0.2))   # school
	add_building(Vector3(14, 0, -10), Vector3(8, 4, 7), Color(0.92, 0.9, 0.82), Color(0.4, 0.5, 0.7))  # Colette's house
	add_building(Vector3(-16, 0, 8), Vector3(7, 3.5, 6), Color(0.85, 0.8, 0.65), Color(0.5, 0.35, 0.25)) # Genis & Raine
	add_building(Vector3(16, 0, 8), Vector3(8, 4.5, 7), Color(0.88, 0.82, 0.7), Color(0.35, 0.3, 0.45))   # mayor
	add_building(Vector3(-8, 0, 18), Vector3(6, 3.5, 5), Color(0.8, 0.75, 0.6), Color(0.55, 0.4, 0.2))    # shop
	add_building(Vector3(9, 0, 18), Vector3(6, 3.5, 5), Color(0.8, 0.75, 0.6), Color(0.55, 0.4, 0.2))     # house
	# fences & trees
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
	# exits
	add_exit(Vector3(0, 1, -36), Vector3(10, 3, 1.5), "iselia_forest", "from_village")
	add_exit(Vector3(0, 1, 36), Vector3(10, 3, 1.5), "world_sylvarant", "iselia",
		func(): return Game.get_flag("ranch_visited", false),
		[{"speaker": "Lloyd", "text": "Primero tengo que acompañar a Colette al templo. Ya iré a casa después."}])
	add_exit(Vector3(-14, 1, -3.8), Vector3(2, 3, 1.0), "iselia_school", "from_village",
		func(): return not Game.get_flag("exiled", false), [{"speaker": "Lloyd", "text": "La escuela está cerrada."}])
	_populate()

func _populate() -> void:
	var exiled := Game.get_flag("exiled", false)
	var temple_done := Game.get_flag("temple_done", false)
	if exiled:
		add_npc("villager_a", Vector3(-6, 0, 4), "Aldeano", "frank",
			[{"speaker": "Aldeano", "text": "...Por favor, marchaos. El alcalde ha dicho que no podéis estar aquí."}])
		add_npc("frank", Vector3(13, 0, -5), "Frank", "frank",
			[{"speaker": "Frank", "text": "Lloyd... Sé que no es justo. Pero cuida de Colette. Y de Genis. Es lo único que te pido."}])
		return
	add_npc("villager_a", Vector3(-6, 0, 4), "Aldeano", "frank",
		[{"speaker": "Aldeano", "text": "¡Menuda luz la de esta mañana! Ha tenido que ser el oráculo. ¡Hoy es un gran día para Iselia!"}] if not temple_done else
		[{"speaker": "Aldeano", "text": "Dicen que la Torre de la Salvación ha aparecido en el cielo. ¡La Elegida va a salvarnos!"}])
	add_npc("villager_b", Vector3(6, 0, 12), "Aldeana", "sheena",
		[{"speaker": "Aldeana", "text": "Gracias al tratado con el rancho, los desianos no nos atacan. Pero no me gusta tenerlos tan cerca..."}], 180.0)
	add_npc("merchant", Vector3(-8, 0, 15), "Mercader", "botta",
		[{"speaker": "Mercader", "text": "Geles de manzana, geles de naranja... Hoy no abro, chico. Con el oráculo, todo el mundo está en el templo."}])
	add_npc("frank", Vector3(13, 0, -5), "Frank", "frank",
		[{"speaker": "Frank", "text": "Lloyd, ¿has visto la luz? Mi madre, Phaidra, ya ha subido al templo. Por favor, no dejes sola a Colette."}] if not temple_done else
		[{"speaker": "Frank", "text": "Colette está descansando en casa. Mañana parte con ese mercenario y con Raine. Es duro ser el padre de la Elegida..."}])
	add_npc("mayor", Vector3(15, 0, 3.5), "Alcalde", "mayor",
		[{"speaker": "Alcalde", "text": "Lloyd Irving. Recuerda el tratado: nadie de esta aldea se acerca al rancho de los desianos. ¿Está claro?"}])
	add_npc("noishe", Vector3(-4, 0, -28), "Noishe", "wolf",
		[{"speaker": "Noishe", "text": "¡Guau! ¡Guaaau...!"}, {"speaker": "Lloyd", "text": "Tranquilo, Noishe. Sé que odias el bosque. Espérame aquí."}])

func on_enter(c: Cutscene) -> void:
	if c.has("night_dirk") and not c.has("exiled"):
		await _day_two(c)

func on_resume(c: Cutscene, event: String) -> void:
	match event:
		"after_raid_soldiers":
			await _forcystus(c)
		"after_exbelua":
			await _marble_death(c)

# ---------- Day 2: Colette is gone, the Desians raid Iselia ----------
func _day_two(c: Cutscene) -> void:
	c.teleport("player", Vector3(0, 0.1, 24), 180.0)
	c.spawn("genis", "genis", Vector3(-1.5, 0, 26), 180.0, "Genis")
	c.spawn("phaidra", "phaidra", Vector3(2, 0, 10), 0.0, "Phaidra")
	await c.wait(0.3)
	await c.walk("player", Vector3(0, 0, 13), 4.0, true, false)
	await c.walk("genis", Vector3(-1.5, 0, 14), 4.0, true)
	await c.script("iselia_village.day_two.01", [
		{"speaker": "Lloyd", "text": "¡Phaidra! ¿Dónde está Colette? Le prometí que la vería antes de irse."},
		{"speaker": "Phaidra", "text": "Lloyd... Colette partió al amanecer, con Raine y el mercenario Kratos. Me pidió que te diera esto."},
	])
	await c.script("iselia_village.day_two.02", [
		{"speaker": "Phaidra", "text": "«Querido Lloyd: perdona que me marche sin despedirme. Si te veía, no habría sido capaz de irme. Gracias por el collar. Lo llevaré siempre. Por favor, sé feliz. Colette.»"},
		{"speaker": "Lloyd", "text": "...Se ha ido. Sin mí."},
		{"speaker": "Genis", "text": "Lloyd... Colette sabía que la seguirías. No quería ponerte en peligro."},
		{"speaker": "Lloyd", "text": "¡Pues tendría que haberme dejado decidir a mí!"},
	])
	await c.shake_camera(0.4, 0.8)
	await c.flash(Color(1, 0.5, 0.3), 0.6)
	await c.script("iselia_village.day_two.03", [
		{"speaker": "Phaidra", "text": "¡¿Qué...?! ¡Humo! ¡La entrada norte está ardiendo!"},
		{"speaker": "Genis", "text": "¡Desianos! ¡Han entrado en la aldea!"},
		{"speaker": "Lloyd", "text": "¡Phaidra, escóndete! ¡Genis, conmigo!"},
	])
	c.despawn("phaidra")
	for id in ["villager_a", "villager_b", "merchant", "frank", "mayor", "noishe"]:
		c.hide_actor(id)
	c.spawn("desian1", "desian", Vector3(-2, 0, -6), 0.0, "Desiano")
	c.spawn("desian2", "desian", Vector3(2.5, 0, -7), 0.0, "Desiano")
	await c.run_to("player", Vector3(0, 0, 0), false)
	await c.run_to("genis", Vector3(-1.5, 0, 1))
	await c.script("iselia_village.day_two.04", [
		{"speaker": "Desiano", "text": "¡Ahí están! ¡Los que entraron en el rancho! ¡Capturadlos, por orden de Lord Forcystus!"},
		{"speaker": "Lloyd", "text": "¡Fuera de mi aldea!"},
	])
	c.despawn("genis")
	await c.battle(["desian_soldier", "desian_soldier"], "after_raid_soldiers")
	return

func _forcystus(c: Cutscene) -> void:
	for id in ["villager_a", "villager_b", "merchant", "frank", "mayor", "noishe"]:
		c.hide_actor(id)
	c.teleport("player", Vector3(0, 0.1, 1), 180.0)
	c.spawn("genis", "genis", Vector3(-1.5, 0, 2), 180.0, "Genis")
	c.spawn("forcystus", "forcystus", Vector3(0, 0, -10), 0.0, "Forcystus")
	c.spawn("exbelua", "zombie", Vector3(3, 0, -9), 0.0, "Exbelua")
	var ex := c.actor("exbelua")
	if ex:
		ex.scale = Vector3.ONE * 2.0
	await c.look_at_actor("forcystus", 0.8)
	await c.script("iselia_village.forcystus.01", [
		{"speaker": "Forcystus", "text": "Así que tú eres Lloyd Irving. El chico de la Exsfera... Lord Yggdrasill estará muy interesado."},
		{"speaker": "Lloyd", "text": "¡¿Quién eres tú?!"},
		{"speaker": "Forcystus", "text": "Forcystus, uno de los Cinco Grandes Cardenales. Rompisteis el tratado al entrar en mi rancho. Esta aldea pagará por ello."},
		{"speaker": "Genis", "text": "¡La aldea no tiene nada que ver! ¡Fuimos nosotros!"},
		{"speaker": "Forcystus", "text": "Cierto. Y por eso os he traído un regalo. ¿Reconoces a tu amiga, pequeño semielfo?"},
	])
	await c.look_at_actor("exbelua", 0.8)
	await c.script("iselia_village.forcystus.02", [
		{"speaker": "Genis", "text": "¿Mar... Marble? ¡No! ¡¿Qué le habéis hecho?!"},
		{"speaker": "Forcystus", "text": "Una Exsfera sin Cresta Clave, forzada hasta el límite. Esto es lo que ocurre cuando el parásito devora a su huésped. ¡Exbelua, devóralos!"},
		{"speaker": "Lloyd", "text": "¡Genis, atrás! ¡Tenemos que detenerla!"},
	])
	await c.camera_reset(0.4)
	c.despawn("genis")
	c.despawn("exbelua")
	await c.battle(["exbelua"], "after_exbelua")
	return

func _marble_death(c: Cutscene) -> void:
	for id in ["villager_a", "villager_b", "merchant", "frank", "mayor", "noishe"]:
		c.hide_actor(id)
	c.teleport("player", Vector3(0, 0.1, 1), 180.0)
	c.spawn("genis", "genis", Vector3(-1.5, 0, 2), 180.0, "Genis")
	c.spawn("forcystus", "forcystus", Vector3(0, 0, -10), 0.0, "Forcystus")
	c.spawn("exbelua", "zombie", Vector3(2.5, 0, -4), 0.0, "Exbelua")
	var ex := c.actor("exbelua")
	if ex:
		ex.scale = Vector3.ONE * 2.0
		c.anim("exbelua", "Death01")
	await c.wait(0.8)
	await c.script("iselia_village.marble_death.01", [
		{"speaker": "Marble", "text": "...Ge... nis... ¿Eres tú...?"},
		{"speaker": "Genis", "text": "¡Marble! ¡Marble, lo siento! ¡Todo esto es culpa mía!"},
		{"speaker": "Marble", "text": "No... Gracias a ti... he podido recordar... lo que era ser feliz. Vive, Genis. Vive por mí..."},
		{"speaker": "Marble", "text": "Lloyd... toma mi Exsfera. No dejes que... nadie más... acabe así..."},
	])
	await c.flash(Color(1, 1, 1), 1.0)
	c.despawn("exbelua")
	await c.give_item("marble_exsphere")
	await c.script("iselia_village.marble_death.02", [
		{"speaker": "Forcystus", "text": "¡Maldita sea! ¡Esa Exsfera es propiedad de los desianos! ¡Entregádmela!"},
		{"speaker": "Lloyd", "text": "¡Nunca! ¡Es de Marble!"},
		{"speaker": "Forcystus", "text": "...Tsk. Estoy herido. Nos retiramos, pero esto no ha terminado, Lloyd Irving. Te estaré esperando."},
	])
	await c.walk("forcystus", Vector3(0, 0, -34), 5.0, true)
	c.despawn("forcystus")
	c.spawn("mayor", "mayor", Vector3(6, 0, -3), 270.0, "Alcalde")
	c.spawn("frank", "frank", Vector3(-6, 0, -3), 90.0, "Frank")
	c.spawn("villager_a", "frank", Vector3(8, 0, 3), 270.0, "Aldeano")
	c.spawn("villager_b", "marble", Vector3(-8, 0, 3), 90.0, "Aldeana")
	await c.wait(0.6)
	await c.script("iselia_village.marble_death.03", [
		{"speaker": "Alcalde", "text": "¡Mirad lo que habéis hecho! La mitad de la aldea en llamas. Casas destruidas. ¡Todo porque rompisteis el tratado!"},
		{"speaker": "Lloyd", "text": "¡Los desianos secuestran a gente de la aldea para su rancho! ¡¿Eso no os importa?!"},
		{"speaker": "Alcalde", "text": "¡Lo que me importa es Iselia! Lloyd Irving, Genis Sage: quedáis desterrados. Marchaos y no volváis."},
		{"speaker": "Aldeana", "text": "Alcalde, son solo niños..."},
		{"speaker": "Alcalde", "text": "¡Niños que casi nos matan a todos!"},
		{"speaker": "Frank", "text": "Lloyd... Genis... Lo siento. Id a ver a Dirk. Y luego... seguid a Colette. Ella os necesita más que nosotros."},
		{"speaker": "Genis", "text": "...Sí. Vámonos, Lloyd."},
		{"speaker": "Lloyd", "text": "Marble... te lo prometo. Acabaré con los desianos. Con todos."},
	])
	c.flag("exiled")
	Game.heal_all()
	c.despawn("genis")
	await c.caption("Lloyd y Genis han sido desterrados de Iselia.", 2.4)
	await c.fade_out()
	Game.last_field_position = Vector3.ZERO
	Router.goto_map("dirks_house", "default")
