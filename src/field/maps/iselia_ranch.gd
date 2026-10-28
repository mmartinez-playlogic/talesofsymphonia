extends Field
## Outside the Iselia Human Ranch: Marble at the fence, the Desian guards, Forcystus, and the escape.

func sky_top() -> Color: return Color(0.3, 0.35, 0.5)
func sun_color() -> Color: return Color(0.95, 0.85, 0.8)

func build() -> void:
	map_id = "iselia_ranch"
	map_title = "Rancho humano de Iselia"
	encounter_table = "iselia_ranch"
	spawns["default"] = Vector3(-26, 0.1, 0)
	spawn_yaw["default"] = PI / 2
	add_ground(Vector2(70, 50), Color(0.38, 0.4, 0.3))
	add_path([Vector3(-32, 0, 0), Vector3(0, 0, 0)], 2.5, Color(0.5, 0.45, 0.35))
	# ranch: big dark block with fence line at x = 6
	add_box(Vector3(20, 0, 0), Vector3(26, 10, 40), Color(0.3, 0.32, 0.4))
	add_box(Vector3(20, 10, 0), Vector3(10, 4, 10), Color(0.35, 0.36, 0.45))
	for z in range(-22, 23, 2):
		add_box(Vector3(6, 0, z), Vector3(0.2, 2.2, 0.2), Color(0.3, 0.3, 0.35))
	add_box(Vector3(6, 1.0, 0), Vector3(0.1, 0.15, 46), Color(0.4, 0.4, 0.45), false)
	add_box(Vector3(6, 1.8, 0), Vector3(0.1, 0.15, 46), Color(0.4, 0.4, 0.45), false)
	add_wall(Vector3(6, 0, -24), Vector3(6, 0, 24), 3.0, false)
	add_light(Vector3(8, 6, -12), Color(0.9, 0.3, 0.2), 3.0, 14)
	add_light(Vector3(8, 6, 12), Color(0.9, 0.3, 0.2), 3.0, 14)
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	for i in 24:
		var x := rng.randf_range(-34, 2)
		var z := rng.randf_range(-24, 24)
		if abs(z) < 4 and x < 0:
			continue
		add_tree(Vector3(x, 0, z), rng.randf_range(0.8, 1.3), Color(0.2, 0.35, 0.2))
	add_wall(Vector3(-35, 0, -25), Vector3(-35, 0, -4))
	add_wall(Vector3(-35, 0, 4), Vector3(-35, 0, 25))
	add_wall(Vector3(-35, 0, -25), Vector3(6, 0, -25))
	add_wall(Vector3(-35, 0, 25), Vector3(6, 0, 25))
	add_exit(Vector3(-36, 1, 0), Vector3(1.5, 3, 8), "iselia_forest", "from_ranch")
	add_monster(Vector3(-14, 0, -12), ["desian_soldier"])
	add_monster(Vector3(-10, 0, 14), ["desian_soldier", "desian_soldier"])

func on_enter(c: Cutscene) -> void:
	if not c.has("ranch_visited") and not c.has("ranch_event_started"):
		await _marble(c)

func on_resume(c: Cutscene, event: String) -> void:
	if event == "after_ranch_fight":
		await _escape(c)

func _marble(c: Cutscene) -> void:
	c.flag("ranch_event_started")
	c.spawn("genis", "genis", Vector3(3.5, 0, 0), 90.0, "Genis")
	c.spawn("marble", "marble", Vector3(8, 0, 0), 270.0, "Marble")
	c.anim("marble", "Idle_Talking")
	await c.walk("player", Vector3(0, 0, 0), 5.0, true)
	await c.look_at_actor("genis", 0.6)
	await c.script("iselia_ranch.marble.01", [
		{"speaker": "Marble", "text": "...y así, con los gritos del capataz, cargamos piedras hasta que anochece. Pero contigo me olvido de todo, Genis. Gracias por venir."},
		{"speaker": "Genis", "text": "Te he traído galletas, Marble. Las hice yo. Come, que estás muy pálida..."},
		{"speaker": "Lloyd", "text": "¡Genis!"},
		{"speaker": "Genis", "text": "¡Lloyd! Te dije que no me siguieras..."},
		{"speaker": "Marble", "text": "¿Un amigo tuyo? Acércate, muchacho. Mis ojos ya no ven bien."},
		{"speaker": "Lloyd", "text": "Soy Lloyd. Señora... esa piedra en su mano, ¿es una Exsfera? ¿Sin Cresta Clave?"},
		{"speaker": "Marble", "text": "Nos la ponen a todos al llegar. Dicen que nos hace más fuertes para trabajar. Pero duele... cada día más."},
		{"speaker": "Lloyd", "text": "Sin una Cresta Clave, la Exsfera devora a quien la lleva. Mi padre, Dirk, es enano. Él sabe fabricarlas. ¡Le pediré una!"},
		{"speaker": "Marble", "text": "Eres muy amable... Pero no corráis riesgos por una vieja como yo."},
		{"speaker": "Lloyd", "text": "Juramento Enano número dos: «Nunca abandones a quien necesite ayuda». Dirk me lo grabó a fuego."},
	])
	c.spawn("desian1", "desian", Vector3(3, 0, -22), 0.0, "Desiano")
	c.spawn("desian2", "desian", Vector3(1, 0, 22), 180.0, "Desiano")
	await c.camera_reset(0.3)
	await c.run_to("desian1", Vector3(2, 0, -6), false)
	await c.run_to("desian2", Vector3(0, 0, 6))
	await c.script("iselia_ranch.marble.02", [
		{"speaker": "Desiano", "text": "¡Eh! ¡Vosotros! ¡Esta zona está prohibida! ¡Y tú, vieja, deja de hablar con los de fuera!"},
		{"speaker": "Marble", "text": "¡No! ¡Ellos no han hecho nada!"},
		{"speaker": "Desiano", "text": "¡Cállate! ¡Para el castigo de la vieja, llevadla al patio! ¡Y a estos dos, capturadlos!"},
		{"speaker": "Genis", "text": "¡Marble!"},
		{"speaker": "Lloyd", "text": "¡Genis, no hay más remedio! ¡Pelea!"},
	])
	c.despawn("genis")
	c.despawn("desian1")
	c.despawn("desian2")
	await c.battle(["desian_soldier", "desian_whip"], "after_ranch_fight")
	return

func _escape(c: Cutscene) -> void:
	c.teleport("player", Vector3(0, 0.1, 0), 90.0)
	c.spawn("genis", "genis", Vector3(2, 0, 2), 90.0, "Genis")
	c.spawn("marble", "marble", Vector3(10, 0, -4), 270.0, "Marble")
	c.spawn("forcystus", "forcystus", Vector3(12, 2.0, -10), 270.0, "Forcystus")
	await c.wait(0.3)
	await c.look_at_actor("forcystus", 0.8)
	await c.script("iselia_ranch.escape.01", [
		{"speaker": "Forcystus", "text": "Vaya, vaya. Un chico con una Exsfera... y un semielfo. Interesante. Muy interesante."},
		{"speaker": "Lloyd", "text": "¿Quién es ese?"},
		{"speaker": "Genis", "text": "¡Es Forcystus, el líder del rancho! ¡Lloyd, tenemos que irnos ya!"},
		{"speaker": "Forcystus", "text": "Marchaos. Hoy. Pero recordad vuestras caras, porque yo las recordaré. Y en cuanto a la vieja... su castigo acaba de empezar."},
		{"speaker": "Marble", "text": "¡Corred! ¡Genis, Lloyd, no miréis atrás!"},
		{"speaker": "Genis", "text": "¡Marble...! ¡Volveré a por ti! ¡Te lo prometo!"},
	])
	await c.camera_reset(0.4)
	c.despawn("forcystus")
	c.despawn("marble")
	c.flag("ranch_visited")
	Game.heal_all()
	await c.run_to("genis", Vector3(-30, 0, 0), false)
	await c.run_to("player", Vector3(-28, 0, 0))
	c.despawn("genis")
	await c.script("iselia_ranch.escape.02", [
		{"speaker": "Genis", "text": "Lloyd... si los desianos se lo cuentan al alcalde, estamos perdidos."},
		{"speaker": "Lloyd", "text": "Lo que me preocupa es Marble. Vamos a casa de Dirk. Él sabrá cómo hacer una Cresta Clave. Está al sur de la aldea."},
	])
	await c.caption("Id a casa de Dirk, al sur de Iselia, por el camino de la aldea.", 2.4)
	await c.fade_out()
	Game.last_field_position = Vector3.ZERO
	Router.goto_map("iselia_forest", "from_ranch")
