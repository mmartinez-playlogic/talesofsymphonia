extends Field
## Dirk's house: the Key Crest argument, Lloyd's mother, the visitors, Colette's lie on the terrace, the night, the morning.

var _evening := false

func _init() -> void:
	_evening = Game.get_flag("ranch_visited", false) and not Game.get_flag("night_dirk", false)

func sky_top() -> Color: return Color(0.35, 0.3, 0.5) if _evening else Color(0.25, 0.45, 0.85)
func sky_horizon() -> Color: return Color(0.95, 0.6, 0.4) if _evening else Color(0.75, 0.85, 0.95)
func sun_energy() -> float: return 0.9 if _evening else 1.3
func sun_color() -> Color: return Color(1.0, 0.75, 0.55) if _evening else Color(1.0, 0.96, 0.88)

func build() -> void:
	map_id = "dirks_house"
	map_title = "Casa de Dirk"
	spawns["default"] = Vector3(0, 0.1, 20)
	add_ground(Vector2(60, 56), Color(0.3, 0.52, 0.27))
	add_path([Vector3(0, 0, 26), Vector3(0, 0, 4)], 3.0)
	add_building(Vector3(0, 0, -4), Vector3(10, 4.5, 8), Color(0.75, 0.6, 0.4), Color(0.45, 0.3, 0.2))
	add_box(Vector3(8, 0, -2), Vector3(3, 1.0, 2), Color(0.45, 0.45, 0.5))
	add_light(Vector3(8, 1.5, -2), Color(1.0, 0.5, 0.2), 2.5, 7)
	add_patch(Vector3(6, 0, 3), Vector2(5, 4), Color(0.55, 0.42, 0.3), 0.03)      # terrace
	add_box(Vector3(7, 0, 4), Vector3(1.6, 0.5, 0.5), Color(0.5, 0.35, 0.2))       # bench
	add_patch(Vector3(-14, 0, -8), Vector2(10, 10), Color(0.34, 0.5, 0.3), 0.03)
	add_box(Vector3(-14, 0, -10), Vector3(1.2, 1.4, 0.3), Color(0.7, 0.7, 0.75))
	add_interactable("grave", Vector3(-14, 0, -8.6), Vector3(1.6, 0.2, 0.8), Color(0.6, 0.6, 0.65), _grave)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 40:
		var x := rng.randf_range(-28, 28)
		var z := rng.randf_range(-26, 26)
		if (abs(x) < 7 and z > -10) or (abs(x + 14) < 7 and abs(z + 8) < 7) or (x > 4 and x < 12 and abs(z) < 7):
			continue
		add_tree(Vector3(x, 0, z), rng.randf_range(0.9, 1.6))
	add_wall(Vector3(-30, 0, -28), Vector3(-30, 0, 28))
	add_wall(Vector3(30, 0, -28), Vector3(30, 0, 28))
	add_wall(Vector3(-30, 0, -28), Vector3(30, 0, -28))
	add_wall(Vector3(-30, 0, 28), Vector3(-4, 0, 28))
	add_wall(Vector3(4, 0, 28), Vector3(30, 0, 28))
	add_exit(Vector3(0, 1, 29), Vector3(8, 3, 1.5), "world_sylvarant", "dirk",
		func(): return not _evening or Game.get_flag("night_dirk", false),
		[{"speaker": "Lloyd", "text": "Ya es tarde. Mañana iré a la aldea a despedirme de Colette."}])
	add_chest("home", Vector3(-6, 0, 2), "melange_gel")
	add_memory_circle(Vector3(-5, 0, 14))
	add_interactable("forge_pot", Vector3(9.5, 0, 0.5), Vector3(0.7, 0.7, 0.7), Color(0.35, 0.3, 0.3), _wonder_chef)
	if not _evening:
		add_npc("dirk", Vector3(5, 0, 0), "Dirk", "dirk",
			[{"speaker": "Dirk", "text": "¡A la aldea, Lloyd! ¡Ya! Colette y los demás se fueron hace mucho."}] if Game.get_flag("night_dirk", false) and not Game.get_flag("exiled", false) else
			[{"speaker": "Dirk", "text": "¿Vas a la aldea? Vuelve antes de que anochezca. Y ni una palabra de tu Exsfera a nadie."}], 90.0)
		add_npc("noishe", Vector3(-5, 0, 6), "Noishe", "wolf", [{"speaker": "Noishe", "text": "¡Guau!"}])

func on_enter(c: Cutscene) -> void:
	if _evening and not c.has("dirk_argument"):
		await _argument(c)
	elif c.has("night_dirk") and not c.has("dirk_morning") and not c.has("exiled"):
		await _morning(c)

func _wonder_chef(c: Cutscene) -> void:
	if c.has("wonder_chef_dirk"):
		await c.line("", "Una olla vieja junto a la forja. Huele a arroz.")
		return
	c.flag("wonder_chef_dirk")
	await c.script("dirks_house.wonder_chef.01", [
		{"speaker": "", "text": "(¡La olla se mueve! De dentro sale un hombrecillo con gorro de cocinero.)"},
		{"speaker": "Maestro Cocinero", "text": "¡Ja! ¡Disfrazado de olla, el escondite perfecto! Ya que me has encontrado: la bola de arroz. Arroz y nada más. ¡Adiós!"},
	])
	Game.learn_recipe("rice_ball")
	Game.add_item("rice", 2)
	await c.caption("Receta aprendida: Bola de arroz.", 1.8)

func _grave(c: Cutscene) -> void:
	await c.script("dirks_house.grave.01", [
		{"speaker": "", "text": "«Anna Irving. Esposa y madre amada.»"},
	])

# ---------- evening: the Key Crest argument ----------
func _argument(c: Cutscene) -> void:
	c.flag("dirk_argument")
	await c.fade_out(0.1)
	c.teleport("player", Vector3(-2, 0.1, 0), 90.0)
	c.spawn("dirk", "dirk", Vector3(2, 0, 0), 270.0, "Dirk")
	await c.fade_in()
	await c.script("dirks_house.argument.01", [
		{"speaker": "Lloyd", "text": "Papá, necesito que hagas una Cresta Clave."},
		{"speaker": "Dirk", "text": "¿Una Cresta Clave? Si una Exsfera no la tiene aún no es tarde, pero quitarla sin cresta es peligroso. Habría que hacer un accesorio de mineral inhibidor, tallar el amuleto y usarlo de cresta."},
		{"speaker": "Lloyd", "text": "¡Un brazalete, entonces! Hazle un brazalete."},
		{"speaker": "Dirk", "text": "¿Y quién lleva esa Exsfera?"},
		{"speaker": "Lloyd", "text": "Eh... Un mercenario de paso."},
		{"speaker": "Dirk", "text": "Tonterías. Solo los desianos usan Exsferas, y las suyas llevan cresta. Juramento Enano número once: «Mentir es el primer paso en el camino del ladrón»."},
		{"speaker": "Lloyd", "text": "...Vale. He estado en el rancho. Hay una anciana con una Exsfera sin cresta. Se está muriendo."},
		{"speaker": "Dirk", "text": "¡¿En el rancho?! ¿Te han visto la Exsfera?"},
		{"speaker": "Lloyd", "text": "No. ¿Pero por qué tengo que esconderla? El mercenario, Kratos, lleva la suya a la vista."},
		{"speaker": "Dirk", "text": "Porque la tuya es especial, Lloyd. Es el recuerdo de tu madre. Los desianos la mataron para quitársela."},
		{"speaker": "Lloyd", "text": "¿Qué...?"},
		{"speaker": "Dirk", "text": "Te encontré en el acantilado junto al rancho. Tu madre aún estaba consciente y me lo contó todo. No te lo dije para que no buscaras venganza."},
		{"speaker": "Dirk", "text": "Ahora que ha aparecido la Torre, déjaselo a Colette. No te metas con los desianos. Tu madre te protegió a ti y a esa Exsfera con su vida."},
		{"speaker": "Lloyd", "text": "¡Pues con más razón! ¡Hazme la Cresta Clave!"},
		{"speaker": "Dirk", "text": "¡He dicho que no!"},
		{"speaker": "", "text": "(Dirk golpea a Lloyd. Lloyd cae al suelo y sale de la casa hecho una furia.)"},
	])
	await c.fade_out()
	c.teleport("player", Vector3(0, 0.1, 6), 0.0)
	c.spawn("raine", "raine", Vector3(-3, 0, 10), 0.0, "Raine")
	c.spawn("genis", "genis", Vector3(-6, 0, 2), 90.0, "Genis")
	c.spawn("kratos", "kratos", Vector3(-11, 0, -5), 270.0, "Kratos")
	c.spawn("colette", "colette", Vector3(6, 0, 3), 180.0, "Colette")
	c.anim("colette", "Sitting_Idle")
	await c.fade_in()
	await c.script("dirks_house.visitors.01", [
		{"speaker": "Raine", "text": "Lloyd. Lo hemos oído todo. ...Ve a hablar con Colette. Te espera en el banco de la terraza."},
	])
	npc("genis").on_interact = func(_f): await _genis_talk(cs)
	npc("kratos").on_interact = func(_f): await _kratos_talk(cs)
	npc("raine").on_interact = func(_f): await _raine_talk(cs)
	npc("colette").on_interact = func(_f): await _terrace(cs)
	await c.caption("Habla con Genis, Kratos y Raine si quieres. Luego ve con Colette, en la terraza.", 2.6)

func _genis_talk(c: Cutscene) -> void:
	await c.script("dirks_house.genis.01", [
		{"speaker": "Genis", "text": "Lloyd... ¿A tu madre la mataron los semielfos? Los desianos lo son."},
		{"speaker": "Lloyd", "text": "No todos los semielfos son desianos. Eso me da igual, Genis."},
	])

func _kratos_talk(c: Cutscene) -> void:
	await c.script("dirks_house.kratos.01", [
		{"speaker": "Kratos", "text": "¿De quién es esta tumba?"},
		{"speaker": "Lloyd", "text": "De mi madre."},
		{"speaker": "Kratos", "text": "«Anna»... Hmm. ¿Tu padre vive?"},
		{"speaker": "Lloyd", "text": "No lo sé. Pero Dirk es mi padre."},
		{"speaker": "Kratos", "text": "...Disculpa. Ha sido una pregunta imprudente."},
	])

func _raine_talk(c: Cutscene) -> void:
	await c.script("dirks_house.raine.01", [
		{"speaker": "Raine", "text": "¿Y el regalo de Colette? Al menos la artesanía se te da bien."},
		{"speaker": "Lloyd", "text": "Casi está. Esta noche lo termino."},
	])

func _terrace(c: Cutscene) -> void:
	if c.has("terrace_done"):
		return
	c.flag("terrace_done")
	await c.script("dirks_house.terrace.01", [
		{"speaker": "Lloyd", "text": "Colette... Siento que el regalo no esté terminado."},
		{"speaker": "Colette", "text": "No pasa nada. Solo deséame feliz cumpleaños. Me alegro de haber vivido hasta hoy."},
		{"speaker": "Lloyd", "text": "¿Puedo ir con vosotros?"},
		{"speaker": "Colette", "text": "Los desianos irán tras nosotros. Es peligroso."},
		{"speaker": "Lloyd", "text": "No puedo quedarme en una aldea que tiene un tratado con los desianos que mataron a mi madre."},
		{"speaker": "Colette", "text": "...Salimos mañana al mediodía. Ven a la aldea entonces, ¿vale?"},
		{"speaker": "Lloyd", "text": "Allí estaré. Quiero verte convertida en ángel."},
		{"speaker": "Colette", "text": "Remiel es mi padre de verdad, Lloyd."},
		{"speaker": "Lloyd", "text": "Pues tienes dos padres. Qué suerte."},
		{"speaker": "Colette", "text": "Liberar los sellos, convertirme en ángel y, al final..."},
		{"speaker": "Lloyd", "text": "¿Al final qué?"},
		{"speaker": "Colette", "text": "Eh... Nada. En el Sello del Fuego volveré a ver a mi padre. ...Adiós, Lloyd."},
		{"speaker": "Lloyd", "text": "¿Adiós? Hasta mañana, querrás decir."},
	])
	await c.fade_out(0.8)
	for id in ["raine", "genis", "kratos", "colette"]:
		c.despawn(id)
	await c.caption("Esa noche, Lloyd termina el collar.", 2.2)
	await c.give_item("colette_necklace")
	c.teleport("player", Vector3(-2, 0.1, 0), 90.0)
	c.spawn("dirk", "dirk", Vector3(2, 0, 0), 270.0, "Dirk")
	c.spawn("noishe", "wolf", Vector3(-1, 0, 4), 0.0, "Noishe")
	await c.fade_in()
	await c.script("dirks_house.night.01", [
		{"speaker": "Dirk", "text": "...Toma. La Cresta Clave. Juramento Enano número dos: «Nunca abandones a quien necesite ayuda»."},
	])
	await c.give_item("key_crest")
	await c.script("dirks_house.night.02", [
		{"speaker": "Lloyd", "text": "Papá... Me voy de viaje. Para ayudar a Colette. Y para vengar a mi madre."},
		{"speaker": "Dirk", "text": "Lo sé. Llévate esto: provisiones para el camino. Esta sigue siendo tu casa, Lloyd. Eres mi hijo, lleves la sangre que lleves."},
	])
	await c.give_item("travelers_guide")
	await c.give_item("apple_gel", 3)
	await c.give_gald(400)
	await c.script("dirks_house.night.03", [
		{"speaker": "Dirk", "text": "¡Y no olvides nunca el Juramento Enano número siete!"},
		{"speaker": "Lloyd", "text": "«La bondad y el amor siempre vencen». Qué cursi, papá."},
		{"speaker": "Lloyd", "text": "¡Vamos, Noishe!"},
		{"speaker": "Noishe", "text": "¡Guau!"},
	])
	c.flag("night_dirk")
	Game.heal_all()
	await c.fade_out(0.8)
	await c.caption("A la mañana siguiente...", 2.0)
	Game.last_field_position = Vector3.ZERO
	Router.goto_map("dirks_house", "default")

func _morning(c: Cutscene) -> void:
	c.flag("dirk_morning")
	c.teleport("player", Vector3(0, 0.1, 8), 0.0)
	c.spawn("genis", "genis", Vector3(0, 0, 26), 180.0, "Genis")
	await c.run_to("genis", Vector3(0, 0, 10))
	await c.script("dirks_house.morning.01", [
		{"speaker": "Genis", "text": "¡Lloyd! ¡Colette y los demás se fueron hace un montón de tiempo! ¡He venido porque no aparecías!"},
		{"speaker": "Lloyd", "text": "¡¿Qué?! ¡Dijo que al mediodía!"},
		{"speaker": "Dirk", "text": "¡A la aldea, Lloyd! ¡Ya!"},
	])
	c.despawn("genis")
	await c.caption("Corre a Iselia (al sur de la casa, por el mapa del mundo, y luego al noreste).", 2.6)
