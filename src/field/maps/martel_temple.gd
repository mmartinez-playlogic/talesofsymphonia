extends Field
## Inside the Martel Temple: Kratos' Training Manual, the golem puzzle for the Sorcerer's Ring, the sealed door,
## Remiel's oracle at the altar, and Raine in "ruin mode".

func sky_top() -> Color: return Color(0.08, 0.08, 0.14)
func sky_horizon() -> Color: return Color(0.2, 0.2, 0.3)
func sun_energy() -> float: return 0.6
func ambient_energy() -> float: return 1.2

func build() -> void:
	map_id = "martel_temple"
	bgm = "temple"
	map_title = "Templo de Martel · Interior"
	encounter_table = "martel_temple"
	spawns["default"] = Vector3(0, 0.1, 30)
	add_ground(Vector2(40, 90), Color(0.5, 0.48, 0.52))
	add_path([Vector3(0, 0, 34), Vector3(0, 0, -40)], 4.0, Color(0.6, 0.55, 0.65))
	add_wall(Vector3(-18, 0, -44), Vector3(-18, 0, 36), 8.0, true, Color(0.55, 0.52, 0.6))
	add_wall(Vector3(18, 0, -44), Vector3(18, 0, 36), 8.0, true, Color(0.55, 0.52, 0.6))
	add_wall(Vector3(-18, 0, -44), Vector3(18, 0, -44), 8.0, true, Color(0.5, 0.48, 0.58))
	add_wall(Vector3(-18, 0, 36), Vector3(-4, 0, 36), 8.0, false)
	add_wall(Vector3(4, 0, 36), Vector3(18, 0, 36), 8.0, false)
	for z in [24, 12, 0, -12, -24]:
		for sx in [-10, 10]:
			var col := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.6
			cm.bottom_radius = 0.7
			cm.height = 8
			col.mesh = cm
			col.set_surface_override_material(0, ToonMaterial.make(Color(0.7, 0.68, 0.75), true, 0.02))
			col.position = Vector3(sx, 4.0, z)
			_world_root.add_child(col)
			_add_cylinder_collider(Vector3(sx, 0, z), 0.7, 8)
			add_light(Vector3(sx, 3.0, z), Color(0.5, 0.7, 1.0), 1.6, 9)
	add_wall(Vector3(-18, 0, -8), Vector3(-3, 0, -8), 8.0, true, Color(0.45, 0.42, 0.55))
	add_wall(Vector3(3, 0, -8), Vector3(18, 0, -8), 8.0, true, Color(0.45, 0.42, 0.55))
	if not Game.get_flag("seal_open", false):
		add_interactable("seal", Vector3(0, 0, -8), Vector3(6, 6, 0.6), Color(0.3, 0.5, 0.9), _on_seal)
	# ring room (west alcove): pedestal, three floor holes, golems
	add_patch(Vector3(-12, 0, 8), Vector2(10, 12), Color(0.42, 0.4, 0.46), 0.025)
	for i in 3:
		var filled: bool = defeated_count() > i
		add_patch(Vector3(-15 + i * 3, 0, 12), Vector2(1.6, 1.6), Color(0.1, 0.1, 0.12) if not filled else Color(0.6, 0.58, 0.62), 0.03)
	add_interactable("pedestal", Vector3(-12, 0, 4), Vector3(1.0, 1.1, 1.0), Color(0.75, 0.65, 0.35), _on_pedestal)
	add_box(Vector3(0, 0, -36), Vector3(10, 0.6, 6), Color(0.85, 0.82, 0.9))
	add_box(Vector3(0, 0.6, -38), Vector3(2.5, 1.2, 1.2), Color(0.95, 0.9, 0.7))
	add_light(Vector3(0, 5, -36), Color(1.0, 0.95, 0.8), 3.0, 16)
	add_chest("temple1", Vector3(8, 0, 20), "life_bottle")
	add_chest("temple2", Vector3(-8, 0, -20), "apple_gel", 2)
	# monsters: the first three are the golems of the ring room
	add_monster(Vector3(-13, 0, 10), ["golem"])
	add_monster(Vector3(-9, 0, 6), ["golem"])
	add_monster(Vector3(-14, 0, 3), ["golem"])
	add_monster(Vector3(5, 0, 18), ["zombie"])
	add_monster(Vector3(6, 0, -18), ["ghost", "zombie"])
	add_exit(Vector3(0, 1, 36), Vector3(8, 3, 1.5), "martel_temple_ext", "from_inside")
	add_memory_circle(Vector3(6, 0, 30))
	if Game.get_flag("seal_open", false) and not Game.get_flag("temple_done", false):
		add_interactable("altar_trigger", Vector3(0, 0, -33), Vector3(6, 0.2, 1.0), Color(0.9, 0.9, 0.8), _oracle)
	if Game.get_flag("temple_done", false):
		add_npc("raine", Vector3(6, 0, -30), "Raine", "raine",
			[{"speaker": "Raine", "text": "¡Maravilloso! ¡Escritura de la era de Kharlan! Marchaos ya a casa. Yo me quedo a estudiar las ruinas, con permiso de Phaidra."}], 270.0)

func on_enter(c: Cutscene) -> void:
	if c.has("temple_entered"):
		return
	c.flag("temple_entered")
	await c.script("martel_temple.enter.01", [
		{"speaker": "Colette", "text": "Qué raro... El templo no se siente como siempre."},
		{"speaker": "Kratos", "text": "Monstruos. Lloyd, tu técnica con la espada... ¿es autodidacta?"},
		{"speaker": "Lloyd", "text": "Sí. ¿Por qué?"},
		{"speaker": "Kratos", "text": "Toma. Al menos aprende lo básico."},
	])
	await c.give_item("training_manual")
	await c.script("martel_temple.enter.02", [
		{"speaker": "Colette", "text": "El camino al centro está sellado. Dicen que el Anillo del Hechicero que se guarda en el templo puede abrirlo... pero no sé dónde está."},
		{"speaker": "Kratos", "text": "Entonces busquémoslo."},
	])

func on_return(c: Cutscene) -> void:
	var n := defeated_count()
	var golems: int = 0
	for i in Game.flags.get("defeated_" + map_id, []):
		if int(i) < 3:
			golems += 1
	if golems >= 1 and not c.has("golem_1"):
		c.flag("golem_1")
		await c.script("martel_temple.golem.01", [
			{"speaker": "Lloyd", "text": "¡El gólem se ha convertido en un bloque de piedra!"},
			{"speaker": "Lloyd", "text": "Bueno, ya era una roca desde el principio."},
			{"speaker": "Genis", "text": "Mira: hay agujeros en el suelo. Si empujamos el bloque dentro, caerá al nivel de abajo y rellenará un hueco. Seguro que aparece otro gólem."},
		])
		await c.caption("El bloque cae por el agujero y rellena un hueco del nivel inferior.", 2.2)
	elif golems == 2 and not c.has("golem_2"):
		c.flag("golem_2")
		await c.caption("Otro bloque cae. Queda un hueco por rellenar.", 2.0)
	elif golems >= 3 and not c.has("golem_3"):
		c.flag("golem_3")
		await c.caption("El último bloque rellena el camino. El pedestal del anillo queda accesible.", 2.4)
	if n > 0 and not c.has("temple_bored") and golems >= 3:
		c.flag("temple_bored")
		await c.script("martel_temple.bored.01", [
			{"speaker": "Lloyd", "text": "Uf, qué aburrimiento de puzle..."},
			{"speaker": "Genis", "text": "Te aburres enseguida, Lloyd."},
		])

func _on_pedestal(c: Cutscene) -> void:
	if c.has("got_ring"):
		await c.line("", "El pedestal está vacío.")
		return
	var golems: int = 0
	for i in Game.flags.get("defeated_" + map_id, []):
		if int(i) < 3:
			golems += 1
	if golems < 3:
		await c.script("martel_temple.pedestal_locked.01", [
			{"speaker": "", "text": "El pedestal está tras un hueco en el suelo. Hay gólems de piedra vigilando la sala."},
			{"speaker": "Genis", "text": "Derrotemos a los gólems: sus bloques rellenarán los huecos."},
		])
		return
	await c.script("martel_temple.pedestal.01", [
		{"speaker": "", "text": "Un pedestal de oro. Sobre él descansa un anillo con una gema roja."},
		{"speaker": "Kratos", "text": "El Anillo del Hechicero. Debería bastar para la mayoría de trampas y obstáculos del templo."},
		{"speaker": "Lloyd", "text": "¡Déjame probarlo!"},
		{"speaker": "Genis", "text": "Eres como un niño pequeño."},
	])
	await c.give_item("sorcerers_ring")
	c.flag("got_ring")
	await c.caption("Anillo del Hechicero: pulsa Arte (K) en el campo para lanzar fuego. Aturde a los monstruos y da ventaja.", 2.8)

func _on_seal(c: Cutscene) -> void:
	if not c.has("got_ring"):
		await c.script("martel_temple.seal_locked.01", [
			{"speaker": "", "text": "Una barrera de luz bloquea el paso al altar."},
			{"speaker": "Colette", "text": "Necesitamos el Anillo del Hechicero. Tiene que estar en alguna sala del templo."},
		])
		return
	await c.flash(Color(1, 0.6, 0.2), 0.6)
	await c.shake_camera(0.3, 0.6)
	await c.script("martel_temple.seal.01", [
		{"speaker": "Genis", "text": "¡La barrera ha desaparecido!"},
		{"speaker": "Kratos", "text": "El altar está más adelante. No bajéis la guardia."},
	])
	c.flag("seal_open")
	var s := get_node_or_null("seal")
	if s:
		s.queue_free()
	add_interactable("altar_trigger", Vector3(0, 0, -33), Vector3(6, 0.2, 1.0), Color(0.9, 0.9, 0.8), _oracle)

func _oracle(c: Cutscene) -> void:
	if c.has("temple_done"):
		return
	c.teleport("player", Vector3(-2, 0.1, -31), 180.0)
	c.spawn("colette", "colette", Vector3(0, 0.6, -35), 0.0, "Colette")
	c.spawn("genis", "genis", Vector3(2, 0, -31), 180.0, "Genis")
	c.spawn("kratos", "kratos", Vector3(4, 0, -29), 180.0, "Kratos")
	c.face("colette", Vector3(0, 0, -40))
	c.anim("colette", "Crouch_Idle")
	await c.script("martel_temple.oracle.01", [
		{"speaker": "Colette", "text": "Es el altar. Y ese cristal... Es el Cristal de Cruxis. Nací sosteniéndolo en la mano."},
	])
	await c.flash(Color(1, 1, 0.85), 1.4)
	c.spawn("remiel", "remiel", Vector3(0, 7.0, -40), 0.0, "Remiel")
	c.anim("remiel", "Spell_Simple_Idle")
	var rm := c.actor("remiel")
	if rm:
		create_tween().tween_property(rm, "position:y", 2.0, 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await c.look_at_pos(Vector3(0, 0, -38), 0.8)
	await c.wait(1.6)
	c.anim("colette", "Idle")
	await c.script("martel_temple.oracle.02", [
		{"speaker": "Genis", "text": "¿Qué... qué es eso?"},
		{"speaker": "Kratos", "text": "Un ángel, supongo."},
		{"speaker": "Remiel", "text": "Soy Remiel, ángel del juicio. He venido a guiar a Colette, hija del linaje del maná, en su viaje al cielo como séptima Elegida."},
		{"speaker": "Remiel", "text": "Ha llegado la hora de despertar a la diosa Martel, que duerme en el centro del mundo."},
		{"speaker": "", "text": "(El Cristal de Cruxis flota y se incrusta en el pecho de Colette.)"},
		{"speaker": "Remiel", "text": "Desde este momento, Colette es la Elegida de la Regeneración. Nosotros, los de Cruxis, bendecimos este día y concedemos a Sylvarant la Torre de la Salvación."},
		{"speaker": "Lloyd", "text": "¡Mirad! ¡Esa es la Torre de la Salvación!"},
		{"speaker": "Colette", "text": "Ahora el mundo se salvará."},
		{"speaker": "Remiel", "text": "Colette: libera los sellos que custodian la Torre de la Salvación y sube sus escaleras hacia el cielo, en tierras lejanas. Con cada sello liberado, Cruxis te concederá el poder de los ángeles."},
		{"speaker": "Remiel", "text": "Cuando renazcas como ángel, el mundo erosionado será regenerado. Primero, ve al sur, al Sello del Fuego, y ofrece allí tus plegarias."},
		{"speaker": "Colette", "text": "Juro por mi vida que regeneraré el mundo."},
		{"speaker": "Colette", "text": "Remiel... ¿de verdad es usted mi pa...?"},
		{"speaker": "Remiel", "text": "Ve al Sello del Fuego. Allí volveremos a vernos... mi querida hija, Colette."},
	])
	await c.flash(Color(1, 1, 0.85), 1.0)
	c.despawn("remiel")
	await c.camera_reset(0.5)
	await c.script("martel_temple.oracle.03", [
		{"speaker": "Colette", "text": "Remiel... es mi verdadero padre..."},
		{"speaker": "Genis", "text": "Ojalá Raine hubiera visto esto."},
		{"speaker": "Kratos", "text": "Colette, te espera un largo viaje por los sellos. Nos vamos ya. Iremos por delante."},
		{"speaker": "Colette", "text": "Lloyd, Genis... pasaos por mi casa luego, ¿vale?"},
	])
	await c.walk("kratos", Vector3(0, 0, -20), 4.0, false, false)
	await c.walk("colette", Vector3(1, 0, -20), 4.0)
	c.despawn("kratos")
	c.despawn("colette")
	await c.script("martel_temple.oracle.04", [
		{"speaker": "Genis", "text": "En la aldea siempre se ha dicho que Colette es hija de un ángel y que no tiene parentesco con Frank."},
		{"speaker": "Lloyd", "text": "La familia es la familia, con sangre o sin ella."},
	])
	c.spawn("raine", "raine", Vector3(6, 0, -30), 270.0, "Raine")
	c.anim("raine", "Idle_Talking")
	await c.script("martel_temple.raine.01a", [
		{"speaker": "Raine", "text": "¡MARAVILLOSO! ¡Estas inscripciones! ¡Escritura de la era de Kharlan en perfecto estado! ¡Una ruina intacta de hace cuatro mil años y nadie me lo había dicho!"},
		{"speaker": "Genis", "text": "Ya está en modo ruinas... Haz como que no la ves."},
		{"speaker": "Raine", "text": "¿Genis? ¿LLOYD? ¡Os dije claramente que os quedarais en clase!"},
	])
	await c.walk("raine", Vector3(1.0, 0, -31), 4.0, true)
	c.face_each_other("raine", "genis")
	await c.anim_wait("raine", "Punch_Jab")
	c.anim("genis", "Hit_Head")
	c.sfx("hit")
	await c.wait(0.3)
	c.face_each_other("raine", "player")
	await c.anim_wait("raine", "Melee_Hook")
	c.anim("player", "Hit_Knockback")
	c.sfx("hit_heavy")
	await c.wait(0.8)
	await c.script("martel_temple.raine.01b", [
		{"speaker": "Raine", "text": "A casa, los dos. Hoy no hay más clase. Yo me quedo a estudiar el templo, con permiso de Phaidra. ¡Ja, ja, ja! ¡Cuatro mil años!"},
	])
	c.flag("temple_done")
	Game.set_party(["lloyd", "genis"])
	Game.heal_all()
	c.despawn("genis")
	var t := get_node_or_null("altar_trigger")
	if t:
		t.queue_free()
	npc("raine").lines = [{"speaker": "Raine", "text": "¡Maravilloso! Marchaos ya a casa. Yo me quedo a estudiar las ruinas."}]
	await c.caption("Colette y Kratos abandonan el grupo. Volved a la aldea de Iselia.", 2.6)
