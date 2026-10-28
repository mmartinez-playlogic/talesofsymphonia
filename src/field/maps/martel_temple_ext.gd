extends Field
## Martel Temple exterior: the stairs where the Desians ambush the priests, Vidarr, and Kratos' arrival.

func build() -> void:
	map_id = "martel_temple_ext"
	map_title = "Templo de Martel"
	spawns["default"] = Vector3(0, 0.1, 26)
	spawns["from_inside"] = Vector3(0, 0.1, -20)
	spawn_yaw["from_inside"] = 0.0
	add_ground(Vector2(60, 70), Color(0.33, 0.52, 0.3))
	add_path([Vector3(0, 0, 30), Vector3(0, 0, -14)], 5.0, Color(0.7, 0.68, 0.6))
	# stairs drawn flat (no collision) so the player can walk up to the facade
	for i in 5:
		add_patch(Vector3(0, 0, -16 - i * 1.2), Vector2(14 - i * 1.5, 1.1), Color(0.78, 0.76, 0.7).darkened(i * 0.05), 0.03 + i * 0.005)
	# temple facade
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
	add_box(Vector3(0, 0, -26.9), Vector3(3.2, 4.5, 0.3), Color(0.25, 0.2, 0.3))  # door
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
			[{"speaker": "Phaidra", "text": "La Elegida debe recibir el oráculo en el altar, en lo más profundo del templo. Que la diosa Martel os proteja."}])
	elif Game.get_flag("temple_done", false):
		add_npc("priest", Vector3(4, 0, -12), "Sacerdote", "mayor",
			[{"speaker": "Sacerdote", "text": "La Torre de la Salvación ha aparecido en el cielo. ¡La regeneración del mundo ha comenzado!"}])

func on_enter(c: Cutscene) -> void:
	if not c.has("vidarr_defeated") and not c.has("temple_ambush_started"):
		await _ambush(c)

func on_resume(c: Cutscene, event: String) -> void:
	match event:
		"after_temple_desians":
			await _vidarr(c)
		"after_vidarr":
			await _kratos_intro(c)

func _ambush(c: Cutscene) -> void:
	c.flag("temple_arrived")
	c.flag("temple_ambush_started")
	c.spawn("genis", "genis", Vector3(-1.5, 0, 28), 180.0, "Genis")
	c.spawn("colette", "colette", Vector3(1.5, 0, 28), 180.0, "Colette")
	c.spawn("phaidra", "phaidra", Vector3(2, 0, -8), 0.0, "Phaidra")
	c.spawn("priest_dead", "mayor", Vector3(-4, 0, 2), 0.0, "Sacerdote")
	c.anim("priest_dead", "Death01")
	c.spawn("desian1", "desian", Vector3(-2, 0, -4), 0.0, "Desiano")
	c.spawn("desian2", "desian", Vector3(3, 0, -5), 0.0, "Desiano")
	await c.walk("player", Vector3(0, 0, 10), 4.5, true, false)
	await c.walk("genis", Vector3(-1.5, 0, 12), 4.5, true, false)
	await c.walk("colette", Vector3(1.5, 0, 12), 4.5, true)
	await c.say([
		{"speaker": "Lloyd", "text": "¡Hay cuerpos en la escalera! Son los sacerdotes del templo..."},
		{"speaker": "Colette", "text": "¡Abuela! ¡Abuela Phaidra!"},
		{"speaker": "Phaidra", "text": "¡Colette, huye! ¡Son desianos! ¡Vienen a por la Elegida!"},
		{"speaker": "Desiano", "text": "¡Ahí está la Elegida! ¡Lord Vidarr quiere su cabeza! ¡A por ella!"},
		{"speaker": "Lloyd", "text": "¡Ni se os ocurra tocarla! ¡Colette, Genis, atrás de mí!"},
	])
	c.despawn("genis")
	c.despawn("colette")
	c.despawn("desian1")
	c.despawn("desian2")
	await c.battle(["desian_soldier", "desian_soldier"], "after_temple_desians")
	return

func _vidarr(c: Cutscene) -> void:
	c.teleport("player", Vector3(0, 0.1, 8), 180.0)
	c.spawn("genis", "genis", Vector3(-1.5, 0, 11), 180.0, "Genis")
	c.spawn("colette", "colette", Vector3(1.5, 0, 11), 180.0, "Colette")
	c.spawn("phaidra", "phaidra", Vector3(2, 0, -8), 0.0, "Phaidra")
	c.spawn("vidarr", "vidarr", Vector3(0, 0, -6), 0.0, "Vidarr")
	await c.shake_camera(0.3, 0.5)
	await c.say([
		{"speaker": "Vidarr", "text": "Inútiles. Si quieres algo bien hecho, hazlo tú mismo. Elegida... entrégate, y tus amigos morirán rápido."},
		{"speaker": "Genis", "text": "¡Es enorme! ¡Lloyd, ese martillo nos partirá en dos!"},
		{"speaker": "Lloyd", "text": "¡Me da igual lo grande que sea!"},
	])
	c.spawn("kratos", "kratos", Vector3(-3, 0, 30), 180.0, "Kratos")
	await c.run_to("kratos", Vector3(-2.5, 0, 9))
	await c.say([
		{"speaker": "Kratos", "text": "Apartaos. Dejad que me encargue."},
		{"speaker": "Lloyd", "text": "¡¿Y tú quién eres?!"},
		{"speaker": "Kratos", "text": "Alguien que sabe luchar. Si quieres ayudar, cúbreme el flanco y no te pongas delante de ese martillo."},
		{"speaker": "Vidarr", "text": "¡Grr! ¡Uno más para aplastar!"},
	])
	c.despawn("genis")
	c.despawn("colette")
	c.despawn("kratos")
	c.despawn("vidarr")
	await c.battle(["vidarr"], "after_vidarr", "normal", ["kratos"])
	return

func _kratos_intro(c: Cutscene) -> void:
	c.flag("vidarr_defeated")
	c.teleport("player", Vector3(0, 0.1, 6), 180.0)
	c.spawn("genis", "genis", Vector3(-2, 0, 9), 180.0, "Genis")
	c.spawn("colette", "colette", Vector3(2, 0, 9), 180.0, "Colette")
	c.spawn("kratos", "kratos", Vector3(-3, 0, 4), 90.0, "Kratos")
	c.spawn("phaidra", "phaidra", Vector3(2, 0, -8), 0.0, "Phaidra")
	await c.wait(0.4)
	await c.say([
		{"speaker": "Lloyd", "text": "¡Lo hemos conseguido! ...Oye, tú. Eres bueno. ¿Quién eres?"},
		{"speaker": "Kratos", "text": "Kratos Aurion. Mercenario. Estaba de paso cuando vi el humo."},
		{"speaker": "Phaidra", "text": "Kratos... Te lo ruego: protege a la Elegida mientras recibe el oráculo. Los sacerdotes han muerto. No queda nadie más."},
		{"speaker": "Kratos", "text": "...Acepto. Pero cuando acabe el oráculo, hablaremos de mi tarifa."},
		{"speaker": "Lloyd", "text": "¡Un momento! ¡Yo también voy! Colette es mi amiga."},
		{"speaker": "Kratos", "text": "Serías un estorbo. Tu postura es torpe y te lanzas sin pensar. Te lo he visto hacer."},
		{"speaker": "Lloyd", "text": "¡¿Qué has dicho?!", "mood": "angry"},
		{"speaker": "Colette", "text": "Señor Kratos, por favor... Lloyd y Genis son mis amigos. Me sentiría más tranquila con ellos."},
		{"speaker": "Kratos", "text": "...Haz lo que quieras. Pero no me hago responsable de lo que les pase ahí dentro."},
		{"speaker": "Genis", "text": "Qué tipo tan simpático..."},
	])
	await c.join("kratos")
	Game.set_party(["lloyd", "colette", "genis", "kratos"])
	c.despawn("genis")
	c.despawn("colette")
	c.despawn("kratos")
	await c.caption("Kratos acompaña al grupo. Entrad en el Templo de Martel.", 2.4)
