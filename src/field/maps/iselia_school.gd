extends Field
## Iselia schoolhouse. The game opens here: Raine's lesson, the oracle's light, and the decision to go to the temple.

func sky_top() -> Color: return Color(0.2, 0.2, 0.25)
func sun_energy() -> float: return 0.9
func ambient_energy() -> float: return 1.1

func build() -> void:
	map_id = "iselia_school"
	map_title = "Iselia · Escuela"
	spawns["default"] = Vector3(3, 0.1, 2)
	spawns["from_village"] = Vector3(0, 0.1, 6)
	add_ground(Vector2(18, 16), Color(0.55, 0.42, 0.28))
	# walls: north/east/west visible, south only collision so the camera can see in
	add_wall(Vector3(-9, 0, -8), Vector3(9, 0, -8), 4.0, true, Color(0.85, 0.8, 0.7))
	add_wall(Vector3(-9, 0, -8), Vector3(-9, 0, 8), 4.0, true, Color(0.8, 0.75, 0.65))
	add_wall(Vector3(9, 0, -8), Vector3(9, 0, 8), 4.0, true, Color(0.8, 0.75, 0.65))
	add_wall(Vector3(-9, 0, 8), Vector3(9, 0, 8), 4.0, false)
	# blackboard + teacher's desk
	add_box(Vector3(0, 0.8, -7.7), Vector3(6, 2.0, 0.1), Color(0.12, 0.25, 0.2))
	add_box(Vector3(0, 0, -5.5), Vector3(2.4, 0.9, 0.9), Color(0.5, 0.33, 0.18))
	# student desks (3 x 2)
	for r in 2:
		for c in 3:
			add_box(Vector3(-3 + c * 3, 0, -1.5 + r * 3), Vector3(1.4, 0.8, 0.8), Color(0.55, 0.38, 0.2))
	add_light(Vector3(0, 3.5, 0), Color(1, 0.95, 0.85), 3.0, 14)
	add_npc("raine", Vector3(0, 0, -4.5), "Raine", "raine",
		[{"speaker": "Raine", "text": "Lloyd, si ya has terminado de dormir, podrías repasar la lección. El examen es la semana que viene."}], 0.0)
	add_npc("colette", Vector3(0, 0, 2), "Colette", "colette",
		[{"speaker": "Colette", "text": "¡Lloyd! ¿Vamos ya al templo? Mi abuela estará esperándome."}], 180.0)
	add_npc("genis", Vector3(-3, 0, 2), "Genis", "genis",
		[{"speaker": "Genis", "text": "Raine se ha ido al templo sin nosotros. Si vamos ahora, nos pillará seguro... ¿Vamos?"}], 180.0)
	add_exit(Vector3(0, 1, 7.0), Vector3(4, 3, 1.5), "iselia_village", "from_school",
		func(): return Game.get_flag("oracle_seen", false), [{"speaker": "Lloyd", "text": "La clase aún no ha terminado..."}])

func on_enter(c: Cutscene) -> void:
	if c.has("oracle_seen"):
		return
	await c.wait(0.3)
	c.anim("player", "Idle")
	await c.say([
		{"speaker": "Raine", "text": "...y así, el héroe Mithos puso fin a la Guerra de Kharlan, que había durado mil años. Para detener la guerra, Mithos firmó un pacto con la diosa Martel."},
		{"speaker": "Raine", "text": "Pero el Gran Árbol de Kharlan, fuente de todo el maná, se marchitó por culpa de la guerra. Con su último aliento, la diosa Martel se transformó en la semilla del árbol."},
		{"speaker": "Raine", "text": "Y entonces... Lloyd Irving. ¿Estás despierto?"},
		{"speaker": "Lloyd", "text": "¡Zzz...! ¿Eh? ¡Sí! ¡Mithos! ¡El Gran Árbol! ¡Lo sabía!"},
		{"speaker": "Genis", "text": "Lloyd, deja de hacer el ridículo..."},
		{"speaker": "Raine", "text": "Colette, por favor, ¿puedes resumirle lo que acabamos de ver a tu compañero?"},
		{"speaker": "Colette", "text": "¡Sí! La diosa Martel dijo: «Despertad y traed prosperidad al mundo en el momento en que el maná se agote».", "mood": "happy"},
		{"speaker": "Colette", "text": "Por eso existen los Elegidos. Cuando el maná escasea, el Elegido viaja por el mundo, despierta a los Espíritus Invocadores y regenera el mundo."},
		{"speaker": "Raine", "text": "Exacto. Y hoy, precisamente, es el día del oráculo. Colette, hoy es tu..."},
	])
	await c.flash(Color(1, 1, 0.9), 0.9)
	await c.shake_camera(0.25, 0.6)
	await c.say([
		{"speaker": "Genis", "text": "¡¿Qué ha sido eso?!"},
		{"speaker": "Lloyd", "text": "¡Una luz enorme! ¡Venía del Templo de Martel!"},
		{"speaker": "Raine", "text": "Es el oráculo. Ha llegado el momento de la Elegida."},
		{"speaker": "Raine", "text": "Voy al templo. Los demás, quedaos aquí y repasad las páginas 20 a 24. ¡Nadie salga del aula!"},
	])
	await c.walk("raine", Vector3(0, 0, 7.5), 4.5, true)
	c.despawn("raine")
	await c.wait(0.4)
	await c.say([
		{"speaker": "Lloyd", "text": "Colette, es tu día. ¿No deberías estar tú en el templo?"},
		{"speaker": "Colette", "text": "Sí... Supongo que debería ir. Mi abuela Phaidra me estará esperando."},
		{"speaker": "Genis", "text": "¡Raine ha dicho que no salgamos!"},
		{"speaker": "Lloyd", "text": "Y también que es el día del oráculo. Alguien tiene que acompañar a la Elegida, ¿no? Vamos, Genis."},
		{"speaker": "Genis", "text": "Ay... Cuando mi hermana se entere nos va a castigar a los dos."},
		{"speaker": "Colette", "text": "Gracias, Lloyd. Gracias, Genis. ¡Vamos al Templo de Martel!", "mood": "happy"},
	])
	c.flag("oracle_seen")
	c.despawn("colette")
	c.despawn("genis")
	await c.caption("Colette y Genis se unen a Lloyd. Objetivo: el Templo de Martel, al norte del bosque.", 2.5)
