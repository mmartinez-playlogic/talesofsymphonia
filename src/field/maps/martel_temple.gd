extends Field
## Inside the Martel Temple: the Sorcerer's Ring, the sealed door, Raine's "ruin mode", and Remiel's oracle at the altar.

func sky_top() -> Color: return Color(0.08, 0.08, 0.14)
func sky_horizon() -> Color: return Color(0.2, 0.2, 0.3)
func sun_energy() -> float: return 0.6
func ambient_energy() -> float: return 1.2

func build() -> void:
	map_id = "martel_temple"
	map_title = "Templo de Martel · Interior"
	encounter_table = "martel_temple"
	spawns["default"] = Vector3(0, 0.1, 30)
	add_ground(Vector2(40, 90), Color(0.5, 0.48, 0.52))
	add_path([Vector3(0, 0, 34), Vector3(0, 0, -40)], 4.0, Color(0.6, 0.55, 0.65))
	# side walls and pillars
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
	# sealed door across the hall at z = -8
	add_wall(Vector3(-18, 0, -8), Vector3(-3, 0, -8), 8.0, true, Color(0.45, 0.42, 0.55))
	add_wall(Vector3(3, 0, -8), Vector3(18, 0, -8), 8.0, true, Color(0.45, 0.42, 0.55))
	if not Game.get_flag("seal_open", false):
		add_interactable("seal", Vector3(0, 0, -8), Vector3(6, 6, 0.6), Color(0.3, 0.5, 0.9), _on_seal)
	# ring pedestal
	if not Game.get_flag("got_ring", false):
		add_interactable("pedestal", Vector3(-7, 0, 6), Vector3(1.0, 1.1, 1.0), Color(0.75, 0.65, 0.35), _on_pedestal)
	else:
		add_box(Vector3(-7, 0, 6), Vector3(1.0, 1.1, 1.0), Color(0.75, 0.65, 0.35))
	# altar at the far end
	add_box(Vector3(0, 0, -36), Vector3(10, 0.6, 6), Color(0.85, 0.82, 0.9))
	add_box(Vector3(0, 0.6, -38), Vector3(2.5, 1.2, 1.2), Color(0.95, 0.9, 0.7))
	add_light(Vector3(0, 5, -36), Color(1.0, 0.95, 0.8), 3.0, 16)
	add_chest("temple1", Vector3(8, 0, 20), "life_bottle")
	add_chest("temple2", Vector3(-8, 0, -20), "apple_gel", 2)
	add_monster(Vector3(5, 0, 18), ["zombie"])
	add_monster(Vector3(-4, 0, 2), ["zombie", "bee"])
	add_monster(Vector3(6, 0, -18), ["zombie", "zombie"])
	add_exit(Vector3(0, 1, 36), Vector3(8, 3, 1.5), "martel_temple_ext", "from_inside")
	if Game.get_flag("seal_open", false) and not Game.get_flag("temple_done", false):
		add_npc("raine", Vector3(6, 0, -30), "Raine", "raine", [], 270.0)
		npc("raine").on_interact = func(_f): await _raine_ruins(cs)
		add_interactable("altar_trigger", Vector3(0, 0, -33), Vector3(6, 0.2, 1.0), Color(0.9, 0.9, 0.8), _oracle)
	if Game.get_flag("temple_done", false):
		add_npc("raine", Vector3(6, 0, -30), "Raine", "raine",
			[{"speaker": "Raine", "text": "¡Fascinante! Estas inscripciones datan de la era de Kharlan. Necesitaré días para catalogarlo todo... Marchaos sin mí, Colette y yo partiremos mañana."}], 270.0)

func _on_pedestal(c: Cutscene) -> void:
	await c.script("martel_temple.on_pedestal.01", [
		{"speaker": "", "text": "Un pedestal de oro. Sobre él descansa un anillo con una gema roja."},
		{"speaker": "Genis", "text": "¡Es el Anillo del Hechicero! Raine me habló de él. Dicen que canaliza maná en forma de fuego."},
		{"speaker": "Kratos", "text": "Lo necesitaremos para romper el sello de la puerta. Cógelo, Lloyd."},
	])
	await c.give_item("sorcerers_ring")
	c.flag("got_ring")
	var p := get_node_or_null("pedestal")
	if p:
		p.queue_free()
	add_box(Vector3(-7, 0, 6), Vector3(1.0, 1.1, 1.0), Color(0.75, 0.65, 0.35))

func _on_seal(c: Cutscene) -> void:
	if not c.has("got_ring"):
		await c.script("martel_temple.on_seal.01", [
			{"speaker": "", "text": "Una barrera de luz azul bloquea el paso. En el suelo hay una inscripción: «Solo el fuego del hechicero abrirá el camino»."},
			{"speaker": "Colette", "text": "¿El fuego del hechicero? Lloyd, ¿tú entiendes algo?"},
			{"speaker": "Lloyd", "text": "Ni idea. Pero por aquí tiene que haber algo que lance fuego."},
		])
		return
	await c.script("martel_temple.on_seal.02", [
		{"speaker": "Lloyd", "text": "Vale, anillo... ¡Fuego!"},
	])
	await c.flash(Color(1, 0.6, 0.2), 0.6)
	await c.shake_camera(0.3, 0.6)
	await c.script("martel_temple.on_seal.03", [
		{"speaker": "Genis", "text": "¡La barrera se ha deshecho! ¡Lloyd, lo has conseguido!"},
		{"speaker": "Kratos", "text": "Bien. El altar está más adelante. No bajéis la guardia."},
	])
	c.flag("seal_open")
	var s := get_node_or_null("seal")
	if s:
		s.queue_free()
	add_npc("raine", Vector3(6, 0, -30), "Raine", "raine", [], 270.0)
	npc("raine").on_interact = func(_f): await _raine_ruins(cs)
	add_interactable("altar_trigger", Vector3(0, 0, -33), Vector3(6, 0.2, 1.0), Color(0.9, 0.9, 0.8), _oracle)

func _raine_ruins(c: Cutscene) -> void:
	await c.script("martel_temple.raine_ruins.01", [
		{"speaker": "Raine", "text": "¡¿Lloyd?! ¡¿Genis?! ¡Os dije que os quedarais en clase! ...Bueno, luego hablaremos de eso."},
		{"speaker": "Raine", "text": "¡Mirad estas paredes! ¡Escritura de la era de Kharlan! ¡Una ruina intacta de hace cuatro mil años! ¡Es maravilloso!", "mood": "happy"},
		{"speaker": "Genis", "text": "Ya está otra vez en modo ruinas... Ignoradla."},
		{"speaker": "Raine", "text": "Colette, el altar está preparado. Cuando estés lista, sube y reza."},
	])

func _oracle(c: Cutscene) -> void:
	if c.has("temple_done"):
		return
	c.teleport("player", Vector3(-2, 0.1, -31), 180.0)
	c.spawn("colette", "colette", Vector3(0, 0.6, -35), 0.0, "Colette")
	c.spawn("genis", "genis", Vector3(2, 0, -31), 180.0, "Genis")
	c.spawn("kratos", "kratos", Vector3(4, 0, -29), 180.0, "Kratos")
	c.face("colette", Vector3(0, 0, -40))
	await c.script("martel_temple.oracle.01", [
		{"speaker": "Colette", "text": "Diosa Martel... Soy Colette Brunel, la Elegida de Sylvarant. Acudo a recibir el oráculo."},
	])
	await c.flash(Color(1, 1, 0.85), 1.4)
	c.spawn("remiel", "remiel", Vector3(0, 2.0, -40), 0.0, "Remiel")
	await c.look_at_pos(Vector3(0, 0, -38), 0.8)
	await c.script("martel_temple.oracle.02", [
		{"speaker": "Remiel", "text": "Colette, Elegida de la regeneración. Soy Remiel, ángel de Cruxis, enviado de la diosa Martel."},
		{"speaker": "Lloyd", "text": "¡Un ángel! ¡Un ángel de verdad!"},
		{"speaker": "Remiel", "text": "Colette, recibe el Cristal de Cruxis. Con él, viajarás por el mundo, liberarás los sellos de los Espíritus Invocadores y, al final, en la Torre de la Salvación, te convertirás en ángel."},
		{"speaker": "Colette", "text": "Lo acepto. Regeneraré el mundo y salvaré a todos."},
		{"speaker": "Remiel", "text": "La Torre de la Salvación ha aparecido en el cielo. Tu primer destino es el sello del fuego, en las ruinas de Triet, al sur. Allí te esperaré."},
		{"speaker": "Colette", "text": "Padre... ¿de verdad es usted mi padre?"},
		{"speaker": "Remiel", "text": "Cuando completes tu viaje, lo seré. Hasta entonces, ve con cuidado, hija mía. Los desianos no son tus únicos enemigos."},
	])
	await c.flash(Color(1, 1, 0.85), 1.0)
	c.despawn("remiel")
	await c.camera_reset(0.5)
	await c.script("martel_temple.oracle.03", [
		{"speaker": "Lloyd", "text": "¡Colette, ha sido increíble! ¡Vamos a regenerar el mundo! ¡Cuenta conmigo!"},
		{"speaker": "Kratos", "text": "Tú no vienes. Raine y yo escoltaremos a la Elegida. Un crío que apenas sabe sostener dos espadas no me sirve."},
		{"speaker": "Lloyd", "text": "¡¿Qué?!"},
		{"speaker": "Raine", "text": "Kratos tiene razón, Lloyd. Y tú y Genis tenéis que volver a casa. Vuestras familias os esperan. Partiremos mañana por la mañana desde la aldea."},
		{"speaker": "Colette", "text": "Lloyd... Lo siento. Mañana nos despedimos, ¿vale? Te lo prometo."},
		{"speaker": "Genis", "text": "Vamos, Lloyd. Si mi hermana se pone seria, no hay nada que hacer."},
		{"speaker": "Lloyd", "text": "...Está bien. Pero mañana estaré en la aldea antes de que salgáis. Ni se os ocurra iros sin mí."},
	])
	c.flag("temple_done")
	Game.set_party(["lloyd", "genis"])
	Game.heal_all()
	c.despawn("colette")
	c.despawn("genis")
	c.despawn("kratos")
	var t := get_node_or_null("altar_trigger")
	if t:
		t.queue_free()
	var r := npc("raine")
	if r:
		r.on_interact = Callable()
		r.lines = [{"speaker": "Raine", "text": "¡Fascinante! Necesitaré días para catalogarlo todo... Marchaos sin mí, Colette y yo partiremos mañana."}]
	await c.caption("Colette y Kratos abandonan el grupo. Volved a la aldea de Iselia.", 2.6)
