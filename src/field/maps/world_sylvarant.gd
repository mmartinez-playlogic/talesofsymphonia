extends Field
## Sylvarant world map (south-east region): Iselia, Dirk's house, the road to the Triet desert.

func build() -> void:
	map_id = "world_sylvarant"
	map_title = "Sylvarant"
	encounter_table = "world_sylvarant_south"
	spawns["default"] = Vector3(70, 0.1, -84)
	spawns["iselia"] = Vector3(70, 0.1, -84)
	spawns["dirk"] = Vector3(30, 0.1, -34)
	spawns["triet"] = Vector3(-80, 0.1, 82)
	spawn_yaw["iselia"] = 0.0
	spawn_yaw["dirk"] = 0.0
	spawn_yaw["triet"] = PI * 0.75
	add_ground(Vector2(260, 260), Color(0.34, 0.56, 0.3))
	# sea at the edges
	add_patch(Vector3(0, 0, 135), Vector2(300, 30), Color(0.2, 0.45, 0.8), 0.04)
	add_patch(Vector3(135, 0, 0), Vector2(30, 300), Color(0.2, 0.45, 0.8), 0.04)
	# desert region south-west
	add_patch(Vector3(-85, 0, 85), Vector2(110, 110), Color(0.85, 0.75, 0.5), 0.03)
	add_patch(Vector3(-50, 0, 45), Vector2(60, 50), Color(0.72, 0.68, 0.45), 0.025)
	# roads
	add_path([Vector3(70, 0, -88), Vector3(60, 0, -60), Vector3(30, 0, -40), Vector3(10, 0, -10), Vector3(-20, 0, 20), Vector3(-50, 0, 50), Vector3(-80, 0, 78)], 3.5)
	# landmarks
	add_box(Vector3(64, 0, -95), Vector3(1.5, 4, 1.5), Color(0.55, 0.42, 0.3))
	add_box(Vector3(76, 0, -95), Vector3(1.5, 4, 1.5), Color(0.55, 0.42, 0.3))
	add_building(Vector3(70, 0, -102), Vector3(16, 5, 10), Color(0.9, 0.85, 0.7), Color(0.6, 0.3, 0.2))
	add_building(Vector3(30, 0, -48), Vector3(7, 4, 6), Color(0.75, 0.6, 0.4), Color(0.45, 0.3, 0.2))
	add_box(Vector3(70, 0, -124), Vector3(20, 14, 8), Color(0.85, 0.83, 0.78))   # Martel Temple far north
	for i in 5:
		add_palm(Vector3(-88 + i * 4, 0, 96 - (i % 2) * 5), 1.2)
	add_box(Vector3(-96, 0, 100), Vector3(12, 5, 6), Color(0.8, 0.7, 0.5))      # Triet walls
	var rng := RandomNumberGenerator.new()
	rng.seed = 2024
	for i in 160:
		var x := rng.randf_range(-120, 120)
		var z := rng.randf_range(-120, 120)
		if x < -30 and z > 30:
			if rng.randf() < 0.3:
				add_cactus(Vector3(x, 0, z), rng.randf_range(0.8, 1.4))
			continue
		if _near_road(Vector3(x, 0, z)):
			continue
		if rng.randf() < 0.15:
			add_rock(Vector3(x, 0, z), rng.randf_range(1.0, 2.5))
		else:
			add_tree(Vector3(x, 0, z), rng.randf_range(1.2, 2.2))
	add_wall(Vector3(-125, 0, -125), Vector3(-125, 0, 125))
	add_wall(Vector3(125, 0, -125), Vector3(125, 0, 125))
	add_wall(Vector3(-125, 0, -125), Vector3(125, 0, -125))
	add_wall(Vector3(-125, 0, 125), Vector3(125, 0, 125))
	add_sign(Vector3(33, 0, -38), "Casa de Dirk, el herrero enano.")
	add_sign(Vector3(-16, 0, 16), "Suroeste: desierto y ciudad de Triet.\nNoreste: Iselia.")
	add_chest("w1", Vector3(-5, 0, -30), "apple_gel", 2)
	add_chest("w2", Vector3(-60, 0, 20), "life_bottle")
	# monsters along the road
	add_monster(Vector3(48, 0, -58), ["wolf", "wolf"])
	add_monster(Vector3(14, 0, -22), ["hare", "hare", "bee"])
	add_monster(Vector3(-8, 0, 2), ["wolf", "hare"])
	add_monster(Vector3(-30, 0, 30), ["wolf", "wolf", "bee"])
	add_monster(Vector3(-62, 0, 58), ["sand_wolf", "hare"])
	add_monster(Vector3(20, 0, 20), ["wolf"])
	# exits
	add_exit(Vector3(70, 1, -93), Vector3(10, 3, 3), "iselia_village", "from_world",
		func(): return not Game.get_flag("exiled", false),
		[{"speaker": "Lloyd", "text": "Iselia... Ya no es nuestro hogar. Sigamos adelante."}])
	add_exit(Vector3(30, 1, -43.5), Vector3(4, 3, 2), "dirks_house", "default")
	add_exit(Vector3(-92, 1, 92), Vector3(14, 3, 8), "triet_desert", "default",
		func(): return Game.get_flag("left_for_journey", false),
		[{"speaker": "Lloyd", "text": "El desierto de Triet... Ahora no. Tengo que estar en la aldea cuando Colette se vaya."}])

func _near_road(p: Vector3) -> bool:
	var pts := [Vector3(70, 0, -88), Vector3(60, 0, -60), Vector3(30, 0, -40), Vector3(10, 0, -10), Vector3(-20, 0, 20), Vector3(-50, 0, 50), Vector3(-80, 0, 78)]
	for i in pts.size() - 1:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var ab := b - a
		var t: float = clamp((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		if (a + ab * t).distance_to(p) < 8.0:
			return true
	if p.distance_to(Vector3(70, 0, -100)) < 20 or p.distance_to(Vector3(30, 0, -46)) < 10 or p.distance_to(Vector3(-92, 0, 95)) < 16:
		return true
	return false

func on_enter(c: Cutscene) -> void:
	if c.has("ranch_visited") and not c.has("world_first_time"):
		c.flag("world_first_time")
		await c.say([
			{"speaker": "Genis", "text": "Desde aquí se ve todo el sur de Sylvarant. La casa de Dirk está siguiendo el camino, al suroeste de la aldea."},
			{"speaker": "Lloyd", "text": "Y más allá, el desierto. Nunca he ido tan lejos..."},
		])
