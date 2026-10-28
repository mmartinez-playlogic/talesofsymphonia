extends Field
## Outside the Iselia Human Ranch: Marble at the fence, the guards, the cliff plan, Lloyd's decoy fight, Forcystus.

func sky_top() -> Color: return Color(0.3, 0.35, 0.5)
func sun_color() -> Color: return Color(0.95, 0.85, 0.8)

func build() -> void:
	map_id = "iselia_ranch"
	bgm = "tension"
	map_title = "Rancho humano de Iselia"
	encounter_table = "iselia_ranch"
	spawns["default"] = Vector3(-26, 0.1, 0)
	spawn_yaw["default"] = PI / 2
	add_ground(Vector2(70, 50), Color(0.38, 0.4, 0.3))
	add_path([Vector3(-32, 0, 0), Vector3(0, 0, 0)], 2.5, Color(0.5, 0.45, 0.35))
	add_box(Vector3(20, 0, 0), Vector3(26, 10, 40), Color(0.3, 0.32, 0.4))
	add_box(Vector3(20, 10, 0), Vector3(10, 4, 10), Color(0.35, 0.36, 0.45))
	for z in range(-22, 23, 2):
		add_box(Vector3(6, 0, z), Vector3(0.2, 2.2, 0.2), Color(0.3, 0.3, 0.35))
	add_box(Vector3(6, 1.0, 0), Vector3(0.1, 0.15, 46), Color(0.4, 0.4, 0.45), false)
	add_box(Vector3(6, 1.8, 0), Vector3(0.1, 0.15, 46), Color(0.4, 0.4, 0.45), false)
	add_wall(Vector3(6, 0, -24), Vector3(6, 0, 24), 3.0, false)
	# cliff (north-west) overlooking the ranch
	add_box(Vector3(-14, 0, -16), Vector3(14, 3.0, 10), Color(0.4, 0.38, 0.34))
	add_light(Vector3(8, 6, -12), Color(0.9, 0.3, 0.2), 3.0, 14)
	add_light(Vector3(8, 6, 12), Color(0.9, 0.3, 0.2), 3.0, 14)
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	for i in 24:
		var x := rng.randf_range(-34, 2)
		var z := rng.randf_range(-24, 24)
		if (abs(z) < 4 and x < 0) or (x < -7 and x > -21 and z < -11):
			continue
		add_tree(Vector3(x, 0, z), rng.randf_range(0.8, 1.3), Color(0.2, 0.35, 0.2))
	add_wall(Vector3(-35, 0, -25), Vector3(-35, 0, -4))
	add_wall(Vector3(-35, 0, 4), Vector3(-35, 0, 25))
	add_wall(Vector3(-35, 0, -25), Vector3(6, 0, -25))
	add_wall(Vector3(-35, 0, 25), Vector3(6, 0, 25))
	add_exit(Vector3(-36, 1, 0), Vector3(1.5, 3, 8), "iselia_forest", "from_ranch")

func on_enter(c: Cutscene) -> void:
	if not c.has("ranch_visited") and not c.has("ranch_event_started"):
		await _marble(c)

func on_resume(c: Cutscene, event: String) -> void:
	if event == "after_ranch_fight":
		await _after_fight(c)

func _marble(c: Cutscene) -> void:
	c.flag("ranch_event_started")
	c.spawn("genis", "genis", Vector3(3.5, 0, 0), 90.0, "Genis")
	c.spawn("marble", "marble", Vector3(8, 0, 0), 270.0, "Marble")
	c.anim("marble", "Idle_Talking")
	await c.walk("player", Vector3(1.5, 0, 1.5), 5.0, true)
	await c.script("iselia_ranch.marble.01", [
		{"speaker": "Genis", "text": "Marble, este es Lloyd, mi mejor amigo."},
		{"speaker": "Marble", "text": "Encantada, Lloyd. He visto la Torre de la Salvación desde aquí. Ojalá esta vez el viaje salga bien."},
		{"speaker": "Lloyd", "text": "¿Esta vez? El último Elegido..."},
		{"speaker": "Marble", "text": "Dicen que los desianos lo mataron durante el viaje. Recemos a Martel por la nueva Elegida."},
		{"speaker": "Lloyd", "text": "Marble... eso de tu mano es una Exsfera. ¡Y no lleva Cresta Clave!"},
		{"speaker": "Marble", "text": "Nos la ponen a todos al llegar. ¿Qué es una Cresta Clave?"},
		{"speaker": "Lloyd", "text": "Una Exsfera sobre la piel desnuda te pone enferma; pero solo funciona sobre la piel. La Cresta Clave es un amuleto tallado en un mineral especial que sirve de montura."},
		{"speaker": "Lloyd", "text": "Yo podría tallar el amuleto, pero no tengo mineral inhibidor. Es tecnología enana."},
		{"speaker": "Genis", "text": "¡Lloyd! ¡Tu padre es un enano!"},
	])
	var i := await c.choice("¿Le pides a Dirk una Cresta Clave?", ["¡Claro! Se lo pediré a Dirk.", "No sé si querrá..."])
	c.affection("genis", 1 if i == 0 else 0)
	await c.script("iselia_ranch.marble.02", [
		{"speaker": "Lloyd", "text": "Se lo pediré a Dirk. Marble, aguanta un poco más."},
		{"speaker": "Marble", "text": "Gracias, muchachos... Pero no corráis riesgos por una vieja."},
	])
	c.spawn("desian1", "desian", Vector3(10, 0, -8), 180.0, "Desiano")
	await c.run_to("desian1", Vector3(9, 0, -2))
	await c.script("iselia_ranch.marble.03", [
		{"speaker": "Desiano", "text": "¡Eh, vieja! ¡¿Qué haces ahí parada?! ¡A trabajar!"},
		{"speaker": "Marble", "text": "(¡Corred! ¡Escondeos!)"},
	])
	await c.run_to("player", Vector3(-6, 0, 3), false)
	await c.run_to("genis", Vector3(-5, 0, 0))
	await c.script("iselia_ranch.marble.04", [
		{"speaker": "Desiano", "text": "¿Holgazaneando? ¿Y esa actitud? ¡Vamos atrás! ¡Te voy a dar una lección!"},
		{"speaker": "Marble", "text": "¡No! ¡Por favor!"},
	])
	await c.walk("desian1", Vector3(14, 0, -6), 3.0, false, false)
	await c.walk("marble", Vector3(14, 0, -5), 3.0)
	c.despawn("desian1")
	c.despawn("marble")
	await c.script("iselia_ranch.marble.05", [
		{"speaker": "Genis", "text": "¡Se la llevan! ¡Lloyd, vamos al acantilado, desde ahí se ve el patio!"},
	])
	await c.run_to("player", Vector3(-10, 3.1, -14), false)
	await c.run_to("genis", Vector3(-8, 3.1, -13))
	c.face("player", Vector3(10, 0, -10))
	c.face("genis", Vector3(10, 0, -10))
	await c.script("iselia_ranch.cliff.01", [
		{"speaker": "Genis", "text": "¡La están golpeando! ¡Lloyd, tenemos que hacer algo!"},
		{"speaker": "Lloyd", "text": "Escucha el plan. Tú atacas a los guardias con magia desde aquí y luego vuelves a la aldea por los arbustos."},
		{"speaker": "Lloyd", "text": "Yo haré de señuelo: bajaré por el acantilado para que no me vean la cara y huiré en dirección contraria a la aldea."},
		{"speaker": "Genis", "text": "¡¿Vas a saltar?! ...Toma, las galletas que me sobraron. Por si acaso."},
		{"speaker": "", "text": "(Lloyd intenta hacer un sándwich con las galletas. No sale bien.)"},
		{"speaker": "Genis", "text": "¡Allá voy! ¡Bola de fuego!"},
	])
	c.anim("genis", "Spell_Simple_Shoot")
	c.sfx("fire")
	await c.flash(Color(1, 0.5, 0.2), 0.5)
	c.despawn("genis")
	c.anim("player", "NinjaJump_Start")
	var pl := c.actor("player")
	if pl:
		pl.set("scripted", true)
		var tw := create_tween()
		tw.tween_property(pl, "global_position", Vector3(-6, 4.0, -10), 0.35).set_ease(Tween.EASE_OUT)
		tw.tween_property(pl, "global_position", Vector3(-2, 0.1, -4), 0.45).set_ease(Tween.EASE_IN)
		await tw.finished
		pl.set("scripted", false)
	c.anim("player", "NinjaJump_Land")
	c.sfx("hit", -4.0)
	await c.caption("Lloyd salta desde el acantilado.", 1.6)
	c.teleport("player", Vector3(-2, 0.1, -4), 90.0)
	c.spawn("desian1", "desian", Vector3(8, 0, -4), 270.0, "Desiano")
	c.spawn("desian2", "desian", Vector3(8, 0, 0), 270.0, "Desiano")
	await c.script("iselia_ranch.cliff.02", [
		{"speaker": "Desiano", "text": "¡Ahí está! ¡Detenedlo! ¡Abrid la puerta principal!"},
	])
	c.despawn("desian1")
	c.despawn("desian2")
	await c.battle(["desian_soldier", "desian_soldier"], "after_ranch_fight", "normal", [], ["lloyd"])
	return

func _after_fight(c: Cutscene) -> void:
	c.restore_party()
	c.teleport("player", Vector3(-2, 0.1, -4), 90.0)
	c.spawn("marble", "marble", Vector3(10, 0, -6), 270.0, "Marble")
	c.spawn("prisoner", "frank", Vector3(11.5, 0, -7), 270.0, "Prisionero")
	await c.script("iselia_ranch.after.01", [
		{"speaker": "Marble", "text": "Gracias... Genis, Lloyd... Gracias."},
		{"speaker": "Prisionero", "text": "Vamos, Marble, dentro. Antes de que vuelvan."},
	])
	await c.walk("marble", Vector3(16, 0, -8), 2.5, false, false)
	await c.walk("prisoner", Vector3(16, 0, -9), 2.5)
	c.despawn("marble")
	c.despawn("prisoner")
	c.spawn("genis", "genis", Vector3(-8, 0, 2), 90.0, "Genis")
	await c.run_to("player", Vector3(-10, 0, 0))
	await c.script("iselia_ranch.after.02", [
		{"speaker": "Lloyd", "text": "He acabado con los que me vieron la cara. Los demás estaban en el acantilado. No sabrán que fuimos nosotros."},
		{"speaker": "Genis", "text": "Eso espero..."},
		{"speaker": "Lloyd", "text": "Por cierto, hazme los deberes."},
		{"speaker": "Genis", "text": "¡Lloyd!", "mood": "angry"},
		{"speaker": "Lloyd", "text": "Yo me voy a casa. Tú vuelve a la aldea. ¡Hasta mañana!"},
	])
	c.flag("ranch_visited")
	Game.heal_all()
	c.despawn("genis")
	await c.fade_out()
	# cut to the Desians
	c.spawn("forcystus", "forcystus", Vector3(-2, 0.1, -4), 180.0, "Forcystus")
	c.spawn("desian1", "desian", Vector3(1, 0, -1), 180.0, "Desiano")
	c.teleport("player", Vector3(-30, 0.1, 0), 270.0)
	c.hide_actor("player")
	await c.look_at_actor("forcystus", 0.1)
	await c.fade_in()
	await c.script("iselia_ranch.forcystus.01", [
		{"speaker": "Desiano", "text": "Lord Forcystus. Un humano ha atacado a los guardias y ha huido. Pero... ¿cómo ha podido saltar desde esa altura un simple humano?"},
		{"speaker": "Forcystus", "text": "Interesante. ¿El sistema de vigilancia ha captado su rostro?"},
		{"speaker": "Desiano", "text": "Sí, señor. Tenemos su imagen."},
		{"speaker": "Forcystus", "text": "Bien. Averiguad quién es."},
	])
	await c.fade_out()
	c.despawn("forcystus")
	c.despawn("desian1")
	c.show_actor("player")
	await c.camera_reset(0.1)
	Game.last_field_position = Vector3.ZERO
	Router.goto_map("iselia_forest", "from_ranch")
