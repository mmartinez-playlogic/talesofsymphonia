extends Field
## Martel Temple exterior: the dying pastor, Botta's men, Vidarr, Kratos' arrival, Phaidra hires Kratos.

func build() -> void:
	map_id = "martel_temple_ext"
	map_title = "Templo de Martel"
	spawns["default"] = Vector3(0, 0.1, 26)
	spawns["from_inside"] = Vector3(0, 0.1, -20)
	spawn_yaw["from_inside"] = 0.0
	add_ground(Vector2(60, 70), Color(0.33, 0.52, 0.3))
	add_path([Vector3(0, 0, 30), Vector3(0, 0, -14)], 5.0, Color(0.7, 0.68, 0.6))
	for i in 5:
		add_patch(Vector3(0, 0, -16 - i * 1.2), Vector2(14 - i * 1.5, 1.1), Color(0.78, 0.76, 0.7).darkened(i * 0.05), 0.03 + i * 0.005)
	add_box(Vector3(0, 0, -30), Vector3(22, 9, 6), Color(0.85, 0.83, 0.78))
	for sx in [-6, -3, 3, 6]:
		var col := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.5
		cm.bottom_radius = 0.6
		cm.height = 8
		col.mesh = cm
		col.set_surface_override_material(0, ToonMaterial.make(Color(0.9, 0.88, 0.82), true, 0.02))
		col.position = Vector3(sx, 4.0, -26.5)
		_world_root.add_child(col)
	add_box(Vector3(0, 0, -26.9), Vector3(3.2, 4.5, 0.3), Color(0.25, 0.2, 0.3))
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for i in 36:
		var x := rng.randf_range(-28, 28)
		var z := rng.randf_range(-20, 32)
		if abs(x) < 9:
			continue
		add_tree(Vector3(x, 0, z), rng.randf_range(0.9, 1.5))
	add_wall(Vector3(-30, 0, -35), Vector3(-30, 0, 35))
	add_wall(Vector3(30, 0, -35), Vector3(30, 0, 35))
	add_wall(Vector3(-30, 0, 35), Vector3(-5, 0, 35))
	add_wall(Vector3(5, 0, 35), Vector3(30, 0, 35))
	add_exit(Vector3(0, 1, 34), Vector3(10, 3, 1.5), "iselia_forest", "from_temple")
	add_exit(Vector3(0, 1.5, -26.5), Vector3(3.5, 4, 1.4), "martel_temple", "default",
		func(): return Game.get_flag("vidarr_defeated", false), [{"speaker": "Lloyd", "text": "La puerta está cerrada."}])
	if Game.get_flag("vidarr_defeated", false) and not Game.get_flag("temple_done", false):
		add_npc("phaidra", Vector3(4, 0, -12), "Phaidra", "phaidra",
			[{"speaker": "Phaidra", "text": "La Elegida debe recibir el juicio del cielo en el altar. Que la diosa Martel os proteja."}])
	elif Game.get_flag("temple_done", false):
		add_npc("priest", Vector3(4, 0, -12), "Sacerdote", "mayor",
			[{"speaker": "Sacerdote", "text": "La Torre de la Salvación ha aparecido en el cielo. ¡La regeneración del mundo ha comenzado!"}])

func on_enter(c: Cutscene) -> void:
	if not c.has("vidarr_defeated") and not c.has("temple_ambush_started"):
		await _pastor(c)

func on_resume(c: Cutscene, event: String) -> void:
	match event:
		"after_temple_desians":
			await _vidarr(c)
		"after_vidarr":
			await _kratos_intro(c)

func _pastor(c: Cutscene) -> void:
	c.flag("temple_arrived")
	c.flag("temple_ambush_started")
	c.spawn("genis", "genis", Vector3(-1.5, 0, 28), 180.0, "Genis")
	c.spawn("colette", "colette", Vector3(1.5, 0, 28), 180.0, "Colette")
	c.spawn("pastor", "mayor", Vector3(1, 0, -6), 0.0, "Pastor")
	await c.walk("player", Vector3(0, 0, 10), 4.5, true, false)
	await c.walk("genis", Vector3(-1.5, 0, 12), 4.5, true, false)
	await c.walk("colette", Vector3(1.5, 0, 12), 4.5, true)
	await c.script("martel_temple_ext.pastor.01", [
		{"speaker": "Genis", "text": "Ya casi estamos. El oráculo se va a transmitir ahí arriba."},
		{"speaker": "Lloyd", "text": "Colette, deberías comportarte un poco más como una Elegida, ¿no?"},
		{"speaker": "Colette", "text": "¿Más... Elegida? ¡Lo intentaré!", "mood": "happy"},
	])
	await c.walk("pastor", Vector3(0.5, 0, 6), 2.0)
	c.anim("pastor", "Death01")
	await c.script("martel_temple_ext.pastor.02", [
		{"speaker": "Pastor", "text": "Elegida... Corre... al oráculo... Lamento... no haber podido... protegerte..."},
		{"speaker": "Colette", "text": "¡Pastor! ¡Pastor, no!"},
		{"speaker": "Genis", "text": "Está... muerto. ¡Lloyd, los desianos siguen ahí arriba!"},
		{"speaker": "Colette", "text": "Tengo que ir. Aunque sea sola."},
		{"speaker": "Genis", "text": "Lloyd, ¿vas a dejar que vaya sola?"},
		{"speaker": "Lloyd", "text": "¡Claro que no! Juramento Enano número uno: «Trabajemos todos juntos por un mundo en paz»."},
		{"speaker": "Genis", "text": "Entonces yo también voy. Raine está ahí arriba."},
	])
	c.despawn("pastor")
	c.spawn("botta", "botta", Vector3(0, 0, -12), 0.0, "Botta")
	c.spawn("desian1", "desian", Vector3(-2.5, 0, -8), 0.0, "Desiano")
	c.spawn("desian2", "desian", Vector3(2.5, 0, -8), 0.0, "Desiano")
	await c.walk("player", Vector3(0, 0, -2), 4.5, true, false)
	await c.walk("genis", Vector3(-1.5, 0, 0), 4.5, true, false)
	await c.walk("colette", Vector3(1.5, 0, 0), 4.5, true)
	await c.script("martel_temple_ext.botta.01", [
		{"speaker": "Desiano", "text": "¡Lord Botta! ¡Ahí está!"},
		{"speaker": "Botta", "text": "Elegida... ¡Tu vida es mía!"},
		{"speaker": "Lloyd", "text": "¡Desianos! ¡No os acerquéis a Colette!"},
		{"speaker": "Desiano", "text": "¿Desianos? ...Ja, ja, ja. Muy bien: morid a manos de los desianos que tanto odiáis."},
	])
	c.despawn("genis")
	c.despawn("colette")
	c.despawn("desian1")
	c.despawn("desian2")
	c.hide_actor("botta")
	await c.battle(["desian_soldier", "desian_soldier"], "after_temple_desians")
	return

func _vidarr(c: Cutscene) -> void:
	c.teleport("player", Vector3(0, 0.1, 2), 180.0)
	c.spawn("genis", "genis", Vector3(-1.5, 0, 4), 180.0, "Genis")
	c.spawn("colette", "colette", Vector3(1.5, 0, 4), 180.0, "Colette")
	c.spawn("botta", "botta", Vector3(-5, 0, -14), 0.0, "Botta")
	c.spawn("vidarr", "vidarr", Vector3(0, 0, -7), 0.0, "Vidarr")
	await c.shake_camera(0.3, 0.5)
	await c.script("martel_temple_ext.vidarr.01", [
		{"speaker": "Botta", "text": "Inútiles. Vidarr, encárgate tú."},
		{"speaker": "Vidarr", "text": "¡Grrr! ¡Os voy a aplastar!"},
		{"speaker": "Genis", "text": "¡Es enorme! ¡Lloyd, esa bola de hierro nos partirá en dos!"},
		{"speaker": "Lloyd", "text": "¡No pienso rendirme!"},
		{"speaker": "", "text": "(Vidarr golpea. Lloyd y Genis ruedan por el suelo. Colette grita.)"},
	])
	c.anim("player", "Hit_Knockback")
	c.anim("genis", "Hit_Knockback")
	c.spawn("kratos", "kratos", Vector3(-3, 0, 30), 180.0, "Kratos")
	await c.run_to("kratos", Vector3(-2.5, 0, 0))
	await c.script("martel_temple_ext.vidarr.02", [
		{"speaker": "Kratos", "text": "Apartaos."},
		{"speaker": "Lloyd", "text": "¡¿Quién...?!"},
		{"speaker": "Kratos", "text": "Si vais a luchar, cubridme. Y no os pongáis delante de esa bola."},
	])
	c.despawn("genis")
	c.despawn("colette")
	c.despawn("kratos")
	c.despawn("vidarr")
	c.hide_actor("botta")
	await c.battle(["vidarr"], "after_vidarr", "normal", ["kratos"])
	return

func _kratos_intro(c: Cutscene) -> void:
	c.flag("vidarr_defeated")
	c.teleport("player", Vector3(0, 0.1, 4), 180.0)
	c.spawn("genis", "genis", Vector3(-2, 0, 7), 180.0, "Genis")
	c.spawn("colette", "colette", Vector3(2, 0, 7), 180.0, "Colette")
	c.spawn("kratos", "kratos", Vector3(-3, 0, 2), 90.0, "Kratos")
	c.spawn("botta", "botta", Vector3(-5, 0, -14), 0.0, "Botta")
	c.spawn("phaidra", "phaidra", Vector3(2, 0, -10), 0.0, "Phaidra")
	await c.wait(0.3)
	await c.look_at_actor("botta", 0.6)
	await c.script("martel_temple_ext.botta.02", [
		{"speaker": "Botta", "text": "...Tsk. Nos retiramos. Elegida, esto no ha terminado."},
	])
	await c.walk("botta", Vector3(-22, 0, -8), 5.5, true)
	c.despawn("botta")
	await c.camera_reset(0.4)
	await c.script("martel_temple_ext.kratos_intro.01", [
		{"speaker": "Phaidra", "text": "¡Increíble...!"},
		{"speaker": "Genis", "text": "Este tipo es fortísimo..."},
		{"speaker": "Kratos", "text": "¿Alguien herido?"},
		{"speaker": "Lloyd", "text": "No... Oye, ¿eso de tu mano es una Exsfera? ¿La llevas a la vista?"},
		{"speaker": "Kratos", "text": "Sí. ...Esta chica es la próxima Elegida, ¿me equivoco?"},
		{"speaker": "Colette", "text": "Sí. Debo superar la prueba del templo."},
		{"speaker": "Kratos", "text": "Hay una presencia maligna dentro. Monstruos."},
		{"speaker": "Phaidra", "text": "La Elegida debe recibir el juicio del cielo, pero los sacerdotes que debían escoltarla han muerto a manos de los desianos."},
		{"speaker": "Lloyd", "text": "¡Yo protegeré a Colette!"},
		{"speaker": "Phaidra", "text": "Lloyd... No me quedo tranquila solo contigo."},
		{"speaker": "Kratos", "text": "¿Cómo te llamas, chico?"},
		{"speaker": "Lloyd", "text": "¿Y tú quién eres para preguntarme el nombre?"},
		{"speaker": "Kratos", "text": "Kratos. Mercenario. Protegeré a la Elegida mientras se me pague."},
		{"speaker": "Phaidra", "text": "Contratado. Por favor, Kratos, cuida de Colette."},
		{"speaker": "Kratos", "text": "Y tú, chico: solo estorbarías. Sé bueno y espera aquí."},
	])
	var i := await c.choice("¿Qué responde Lloyd?", ["¡¿Qué has dicho?!", "...Vale."])
	if i == 0:
		c.affection("genis", 1)
		await c.script("martel_temple_ext.kratos_intro.02", [
			{"speaker": "Lloyd", "text": "¡¿Qué has dicho?!"},
			{"speaker": "Kratos", "text": "Que eres una carga. Vete a casa."},
		])
	else:
		c.affection("kratos", 1)
		await c.script("martel_temple_ext.kratos_intro.03", [
			{"speaker": "Lloyd", "text": "...Vale. Vale, lo pillo."},
			{"speaker": "Kratos", "text": "Bien."},
		])
	await c.script("martel_temple_ext.kratos_intro.04", [
		{"speaker": "Colette", "text": "Señor Kratos, por favor... Deje que Lloyd venga. Me pongo nerviosa cuando Lloyd no está."},
		{"speaker": "Kratos", "text": "...Haz lo que quieras."},
		{"speaker": "Lloyd", "text": "¡Vamos, Genis! ¡Tú también vienes!"},
		{"speaker": "Genis", "text": "¡Eh! ¡No me arrastres!"},
		{"speaker": "Kratos", "text": "Esto no es una excursión escolar."},
	])
	await c.join("kratos")
	Game.set_party(["lloyd", "colette", "genis", "kratos"])
	Game.heal_all()
	c.despawn("genis")
	c.despawn("colette")
	c.despawn("kratos")
	await c.caption("Kratos se une al grupo. Entrad en el Templo de Martel.", 2.4)
