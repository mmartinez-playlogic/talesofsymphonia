extends Field
## Iselia schoolhouse. Opening scene: Raine's lesson, the oracle's light, Lloyd decides to go to the temple.

func sky_top() -> Color: return Color(0.2, 0.2, 0.25)
func sun_energy() -> float: return 0.9
func ambient_energy() -> float: return 1.1

func build() -> void:
	map_id = "iselia_school"
	map_title = "Iselia · Escuela"
	spawns["default"] = Vector3(3, 0.1, 2)
	spawns["from_village"] = Vector3(0, 0.1, 6)
	add_ground(Vector2(18, 16), Color(0.55, 0.42, 0.28))
	add_wall(Vector3(-9, 0, -8), Vector3(9, 0, -8), 4.0, true, Color(0.85, 0.8, 0.7))
	add_wall(Vector3(-9, 0, -8), Vector3(-9, 0, 8), 4.0, true, Color(0.8, 0.75, 0.65))
	add_wall(Vector3(9, 0, -8), Vector3(9, 0, 8), 4.0, true, Color(0.8, 0.75, 0.65))
	add_wall(Vector3(-9, 0, 8), Vector3(9, 0, 8), 4.0, false)
	add_box(Vector3(0, 0.8, -7.7), Vector3(6, 2.0, 0.1), Color(0.12, 0.25, 0.2))
	add_box(Vector3(0, 0, -5.5), Vector3(2.4, 0.9, 0.9), Color(0.5, 0.33, 0.18))
	for r in 2:
		for c in 3:
			add_box(Vector3(-3 + c * 3, 0, -1.5 + r * 3), Vector3(1.4, 0.8, 0.8), Color(0.55, 0.38, 0.2))
	add_light(Vector3(0, 3.5, 0), Color(1, 0.95, 0.85), 3.0, 14)
	if not Game.get_flag("oracle_seen", false):
		add_npc("raine", Vector3(0, 0, -4.5), "Raine", "raine", [], 0.0)
		add_npc("colette", Vector3(0, 0, 2), "Colette", "colette", [], 180.0)
		add_npc("genis", Vector3(-3, 0, 2), "Genis", "genis", [], 180.0)
		add_npc("student_a", Vector3(3, 0, -1), "Alumno", "frank", [{"speaker": "Alumno", "text": "Psst... Lloyd, te va a caer una buena como Raine te pille durmiendo otra vez."}], 180.0)
		add_npc("student_b", Vector3(-3, 0, -1), "Alumna", "marble", [{"speaker": "Alumna", "text": "Hoy es el Día de la Profecía. ¡Qué nervios por Colette!"}], 180.0)
	add_exit(Vector3(0, 1, 7.0), Vector3(4, 3, 1.5), "iselia_village", "from_school",
		func(): return Game.get_flag("oracle_seen", false), [{"speaker": "Lloyd", "text": "La clase aún no ha terminado..."}])

func on_enter(c: Cutscene) -> void:
	if c.has("oracle_seen"):
		return
	await c.wait(0.3)
	await c.script("iselia_school.intro.01", [
		{"speaker": "Raine", "text": "...Lloyd Irving."},
		{"speaker": "", "text": "(Raine le lanza el borrador de la pizarra a Lloyd. Impacto directo.)"},
		{"speaker": "Lloyd", "text": "¡Au! ...¿Eh? ¿Ya se ha acabado la clase?"},
		{"speaker": "Raine", "text": "Qué más quisieras. Genis, ¿puedes responder tú? ¿Cómo terminó la Guerra Antigua?"},
		{"speaker": "Genis", "text": "El héroe Mithos puso fin a la Guerra de Kharlan en la Tierra Sagrada de Kharlan."},
		{"speaker": "Raine", "text": "Correcto. Después, Mithos selló un pacto con la diosa Martel para encerrar a los desianos."},
		{"speaker": "Lloyd", "text": "¡Pero los desianos volvieron!"},
		{"speaker": "Raine", "text": "Eso ya lo vimos, Lloyd. Cuando el sello se debilita, los desianos reaparecen. Si hubieras estado despierto..."},
		{"speaker": "Raine", "text": "Y hoy es, precisamente, el Día de la Profecía: el día en que la Elegida del Maná recibe el oráculo de Martel. Colette, ¿qué es el viaje de regeneración del mundo?"},
		{"speaker": "Colette", "text": "Es un viaje para sellar a los desianos."},
		{"speaker": "Raine", "text": "Bien. Y además: la falta de maná provoca malas cosechas y sequías, y los desianos lo consumen en sus ranchos humanos. El viaje tiene dos propósitos: recuperar el maná y derrotar a los desianos."},
	])
	await c.flash(Color(1, 1, 0.9), 0.9)
	await c.shake_camera(0.25, 0.6)
	await c.script("iselia_school.intro.02", [
		{"speaker": "Genis", "text": "¡¿Qué ha sido esa luz?!"},
		{"speaker": "Raine", "text": "Venía del templo. Parece que ha llegado la hora del oráculo. Voy a la capilla a comprobarlo. Vosotros os quedáis aquí estudiando por vuestra cuenta."},
		{"speaker": "Colette", "text": "Profesora, ¿voy yo también?"},
		{"speaker": "Raine", "text": "No. Los sacerdotes vendrán a buscarte aquí. Que nadie salga del aula."},
	])
	await c.walk("raine", Vector3(0, 0, 7.5), 4.5, true)
	c.despawn("raine")
	await c.wait(0.4)
	await c.script("iselia_school.intro.03", [
		{"speaker": "Lloyd", "text": "Quiero ver con mis propios ojos qué pasa en el oráculo."},
		{"speaker": "Genis", "text": "¡Lloyd! ¡Raine ha dicho que nos quedemos!"},
	])
	var i := await c.choice("¿Qué le dices a Genis?", ["Es por investigación.", "Vale, está bien."])
	if i == 0:
		c.affection("genis", 1)
		await c.script("iselia_school.intro.04", [
			{"speaker": "Lloyd", "text": "Es por investigación. Como lo de Raine con las ruinas."},
			{"speaker": "Genis", "text": "Eso no es investigación, es cotillear..."},
		])
	else:
		c.affection("colette", 1)
		await c.script("iselia_school.intro.05", [
			{"speaker": "Lloyd", "text": "Vale, está bien... Pero es que es el día de Colette."},
			{"speaker": "Genis", "text": "Ya sé lo que viene ahora."},
		])
	await c.script("iselia_school.intro.06", [
		{"speaker": "Lloyd", "text": "Genis, somos los mejores amigos, ¿no? Ven conmigo. Y tú también, Colette. Es tu oráculo."},
		{"speaker": "Colette", "text": "Si Lloyd tiene curiosidad... yo también.", "mood": "happy"},
		{"speaker": "Lloyd", "text": "Juramento Enano número cuatro: «No dependas de los demás. Camina con tus propias piernas»."},
		{"speaker": "Genis", "text": "Siempre usas los Juramentos Enanos como excusa..."},
	])
	c.flag("oracle_seen")
	c.despawn("colette")
	c.despawn("genis")
	c.despawn("student_a")
	c.despawn("student_b")
	await c.caption("(Colette tropieza y atraviesa la pared de la escuela. El agujero tiene su forma.)", 2.6)
