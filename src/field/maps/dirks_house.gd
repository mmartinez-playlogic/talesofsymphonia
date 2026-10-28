extends Field
## Dirk's house in the woods south of Iselia: Lloyd's home, Anna's grave, Kratos at night, Colette's farewell,
## and (after the exile) the Key Crest for Marble's Exsphere.

var _night := false

func _init() -> void:
	_night = Game.get_flag("ranch_visited", false) and not Game.get_flag("night_dirk", false)

func sky_top() -> Color: return Color(0.05, 0.06, 0.18) if _night else Color(0.25, 0.45, 0.85)
func sky_horizon() -> Color: return Color(0.2, 0.2, 0.35) if _night else Color(0.75, 0.85, 0.95)
func sun_energy() -> float: return 0.35 if _night else 1.3
func sun_color() -> Color: return Color(0.6, 0.7, 1.0) if _night else Color(1.0, 0.96, 0.88)
func ambient_energy() -> float: return 0.5 if _night else 0.7

func build() -> void:
	map_id = "dirks_house"
	map_title = "Casa de Dirk"
	spawns["default"] = Vector3(0, 0.1, 20)
	add_ground(Vector2(60, 56), Color(0.3, 0.52, 0.27))
	add_path([Vector3(0, 0, 26), Vector3(0, 0, 4)], 3.0)
	add_building(Vector3(0, 0, -4), Vector3(10, 4.5, 8), Color(0.75, 0.6, 0.4), Color(0.45, 0.3, 0.2))
	add_box(Vector3(8, 0, -2), Vector3(3, 1.0, 2), Color(0.45, 0.45, 0.5))        # anvil / forge
	add_light(Vector3(8, 1.5, -2), Color(1.0, 0.5, 0.2), 2.5, 7)
	# Anna's grave on a small hill to the west
	add_patch(Vector3(-14, 0, -8), Vector2(10, 10), Color(0.34, 0.5, 0.3), 0.03)
	add_box(Vector3(-14, 0, -10), Vector3(1.2, 1.4, 0.3), Color(0.7, 0.7, 0.75))
	add_interactable("grave", Vector3(-14, 0, -8.6), Vector3(1.6, 0.2, 0.8), Color(0.6, 0.6, 0.65), _grave)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 40:
		var x := rng.randf_range(-28, 28)
		var z := rng.randf_range(-26, 26)
		if abs(x) < 7 and z > -10 or (abs(x + 14) < 7 and abs(z + 8) < 7) or (x > 5 and x < 12 and abs(z) < 5):
			continue
		add_tree(Vector3(x, 0, z), rng.randf_range(0.9, 1.6))
	add_wall(Vector3(-30, 0, -28), Vector3(-30, 0, 28))
	add_wall(Vector3(30, 0, -28), Vector3(30, 0, 28))
	add_wall(Vector3(-30, 0, -28), Vector3(30, 0, -28))
	add_wall(Vector3(-30, 0, 28), Vector3(-4, 0, 28))
	add_wall(Vector3(4, 0, 28), Vector3(30, 0, 28))
	if _night:
		add_light(Vector3(0, 3, 1), Color(1.0, 0.8, 0.5), 2.0, 10)
	add_exit(Vector3(0, 1, 29), Vector3(8, 3, 1.5), "world_sylvarant", "dirk")
	add_chest("home", Vector3(-6, 0, 2), "melange_gel")
	var left := Game.get_flag("left_for_journey", false)
	var exiled := Game.get_flag("exiled", false)
	if left:
		add_npc("dirk", Vector3(5, 0, 0), "Dirk", "dirk",
			[{"speaker": "Dirk", "text": "¿Todavía aquí? El desierto de Triet está al suroeste. Y no te olvides de comer, muchacho."}], 90.0)
	elif not exiled and not _night:
		add_npc("dirk", Vector3(5, 0, 0), "Dirk", "dirk",
			[{"speaker": "Dirk", "text": "¿Vas a la aldea? Vuelve antes de que anochezca. Y recuerda: ni una palabra de tu Exsfera a nadie."}], 90.0)
		add_npc("noishe", Vector3(-5, 0, 6), "Noishe", "wolf", [{"speaker": "Noishe", "text": "¡Guau!"}])

func on_enter(c: Cutscene) -> void:
	if _night:
		await _evening(c)
	elif c.has("exiled") and not c.has("left_for_journey"):
		await _departure(c)

func _grave(c: Cutscene) -> void:
	await c.say([
		{"speaker": "", "text": "«Anna Irving. Esposa y madre amada.»"},
		{"speaker": "Lloyd", "text": "Mamá... Hoy ha sido un día muy largo. Pero creo que he hecho lo correcto."},
	])

func _evening(c: Cutscene) -> void:
	c.spawn("dirk", "dirk", Vector3(2, 0, 2), 180.0, "Dirk")
	npc("dirk").lines = [{"speaker": "Dirk", "text": "Ve a ver a tu madre, Lloyd. Y luego a dormir."}]
	c.spawn("genis", "genis", Vector3(-2, 0, 22), 180.0, "Genis")
	c.teleport("player", Vector3(0, 0.1, 20), 180.0)
	await c.walk("genis", Vector3(-2, 0, 7), 3.5, false, false)
	await c.walk("player", Vector3(0, 0, 5), 3.5)
	await c.say([
		{"speaker": "Dirk", "text": "Llegas tarde, Lloyd. ¿Y esa cara? ¿Qué habéis hecho esta vez?"},
		{"speaker": "Lloyd", "text": "Papá... Necesito que hagas una Cresta Clave. Hay una mujer en el rancho con una Exsfera sin cresta. Se está muriendo."},
		{"speaker": "Dirk", "text": "¿En el rancho? ¡¿HAS ESTADO EN EL RANCHO?!", "mood": "angry"},
		{"speaker": "Genis", "text": "Fue culpa mía, señor Dirk. Lloyd solo vino a buscarme."},
		{"speaker": "Dirk", "text": "¡Me da igual de quién fue la culpa! ¡Si los desianos ven tu Exsfera, Lloyd, irán a por ti! ¡Como fueron a por tu madre!"},
		{"speaker": "Lloyd", "text": "¡Por eso mismo! ¡No puedo quedarme mirando mientras le pasa lo mismo a otra persona!"},
		{"speaker": "Dirk", "text": "...No tengo mineral inhibidor. Sin él no hay Cresta Clave. Es la verdad, muchacho. Lo siento."},
		{"speaker": "Lloyd", "text": "¡Pues buscaré mineral! ¡Lo que haga falta!"},
		{"speaker": "Dirk", "text": "Lloyd... Ve a ver a tu madre. Y piensa un poco antes de hablar. Genis, quédate a cenar."},
	])
	c.despawn("genis")
	await c.caption("Visita la tumba de Anna, al oeste de la casa.", 2.0)
	# the player walks to the grave; the scene continues from there
	add_trigger(Vector3(-14, 1, -4), Vector3(8, 3, 6), _kratos_at_grave, "kratos_grave_scene")

func _kratos_at_grave(c: Cutscene) -> void:
	c.face("player", Vector3(-14, 0, -10))
	await c.say([
		{"speaker": "Lloyd", "text": "Mamá... Hoy he visto a una mujer que lleva una Exsfera como la tuya. Y no he podido hacer nada."},
	])
	c.spawn("kratos", "kratos", Vector3(-6, 0, 2), 270.0, "Kratos")
	await c.walk("kratos", Vector3(-11, 0, -6), 3.0)
	await c.say([
		{"speaker": "Kratos", "text": "...Esa tumba."},
		{"speaker": "Lloyd", "text": "¡Kratos! ¿Qué haces aquí?"},
		{"speaker": "Kratos", "text": "Colette quería verte. Está en la casa con tu padre. ¿Es tu madre?"},
		{"speaker": "Lloyd", "text": "Sí. Anna. Los desianos la mataron cuando yo tenía tres años. Un enano, Dirk, me encontró junto a su cuerpo y me crió. Noishe también estaba allí."},
		{"speaker": "Kratos", "text": "...Ya veo. Esa Exsfera que llevas en la mano, ¿era de ella?"},
		{"speaker": "Lloyd", "text": "Sí. Dirk le hizo una Cresta Clave. Dice que es lo único que me dejó mi madre."},
		{"speaker": "Kratos", "text": "Cuídala. Y cuídate tú. Mañana la Elegida parte al alba. Si de verdad quieres protegerla... hazte más fuerte."},
	])
	await c.walk("kratos", Vector3(-6, 0, 2), 3.0)
	c.despawn("kratos")
	c.spawn("colette", "colette", Vector3(-8, 0, 0), 270.0, "Colette")
	await c.walk("colette", Vector3(-12, 0, -5), 3.2)
	await c.say([
		{"speaker": "Colette", "text": "¡Lloyd! Siento venir tan tarde. Mañana salimos muy temprano y... quería verte."},
		{"speaker": "Lloyd", "text": "Colette... Yo también tengo algo para ti. Espera."},
	])
	await c.give_item("colette_necklace")
	await c.say([
		{"speaker": "Lloyd", "text": "Lo hice yo. Es un collar. Me ha salido un poco torcido, pero..."},
		{"speaker": "Colette", "text": "¡Es precioso! ¡Gracias, Lloyd! Lo llevaré siempre.", "mood": "happy"},
		{"speaker": "Colette", "text": "Lloyd... ¿Sabes? Un Elegido no puede permitirse ser feliz. Pero hoy, contigo, lo soy un poquito."},
		{"speaker": "Lloyd", "text": "Mañana estaré en la aldea antes del alba. Despídete de mí como es debido, ¿vale?"},
		{"speaker": "Colette", "text": "...Sí. Hasta mañana, Lloyd."},
	])
	Game.add_item("colette_necklace", -1)
	await c.walk("colette", Vector3(-4, 0, 4), 3.2)
	c.despawn("colette")
	await c.fade_out(0.8)
	c.flag("night_dirk")
	await c.caption("A la mañana siguiente...", 2.2)
	Game.heal_all()
	Game.last_field_position = Vector3.ZERO
	Router.goto_map("dirks_house", "default")

func _departure(c: Cutscene) -> void:
	c.spawn("dirk", "dirk", Vector3(2, 0, 2), 180.0, "Dirk")
	npc("dirk").lines = [{"speaker": "Dirk", "text": "El desierto de Triet está al suroeste. Y no te olvides de comer, muchacho."}]
	c.spawn("genis", "genis", Vector3(-2, 0, 22), 180.0, "Genis")
	c.spawn("noishe", "wolf", Vector3(-6, 0, 4), 90.0, "Noishe")
	c.teleport("player", Vector3(0, 0.1, 20), 180.0)
	await c.walk("genis", Vector3(-2, 0, 7), 3.5, false, false)
	await c.walk("player", Vector3(0, 0, 5), 3.5)
	await c.say([
		{"speaker": "Dirk", "text": "Ya me lo han contado. Desterrados... Ese alcalde es un cobarde. Pero vosotros dos sois unos insensatos."},
		{"speaker": "Lloyd", "text": "Papá, Marble murió. Me dio su Exsfera. Quiero que Genis la lleve, con una Cresta Clave. ¿Puedes...?"},
		{"speaker": "Dirk", "text": "...Anoche, después de lo que me dijiste, rebusqué entre mis cosas. Encontré un último trozo de mineral inhibidor. Toma."},
	])
	await c.give_item("key_crest")
	await c.say([
		{"speaker": "Genis", "text": "Señor Dirk... Gracias. Marble... la llevaré conmigo."},
		{"speaker": "Dirk", "text": "Y tú, Lloyd. Coge esto. Son tus espadas de verdad. Ya es hora."},
	])
	await c.give_item("iron_sword")
	Game.members["lloyd"]["equipment"]["weapon"] = "iron_sword"
	Game.add_item("iron_sword", -1)
	Game.add_item("key_crest", -1)
	Game.add_item("marble_exsphere", -1)
	await c.give_item("apple_gel", 3)
	await c.give_gald(600)
	await c.say([
		{"speaker": "Dirk", "text": "Vais a seguir a la Elegida, ¿no? El desierto de Triet está al suroeste. Llevaos a Noishe. Y Lloyd... no mueras."},
		{"speaker": "Noishe", "text": "¡Guau! ¡Guau!"},
		{"speaker": "Lloyd", "text": "Papá... Gracias. Por todo. Volveré. Te lo prometo."},
		{"speaker": "Genis", "text": "Vamos, Lloyd. Colette nos lleva un día de ventaja."},
	])
	c.flag("left_for_journey")
	Game.heal_all()
	c.despawn("genis")
	c.despawn("noishe")
	await c.caption("Objetivo: el desierto de Triet, al suroeste de Sylvarant.", 2.6)
	Game.flags["dirk_said_bye"] = true
	var d := npc("dirk")
	if d:
		d.lines = [{"speaker": "Dirk", "text": "El desierto de Triet está al suroeste. Y no te olvides de comer, muchacho."}]
