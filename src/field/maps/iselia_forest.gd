extends Field
## Iselia Forest: the woods between the village of Iselia and the Martel Temple.

func build() -> void:
	map_id = "iselia_forest"
	encounter_table = "iselia_forest"
	spawns["default"] = Vector3(0, 0.1, 18)
	spawns["from_village"] = Vector3(0, 0.1, 18)
	spawns["from_temple"] = Vector3(0, 0.1, -40)
	add_ground(Vector2(70, 110), Color(0.30, 0.55, 0.26))
	add_path([Vector3(0, 0, 22), Vector3(0, 0, 8), Vector3(-6, 0, -4), Vector3(2, 0, -18), Vector3(0, 0, -34), Vector3(0, 0, -50)])
	# tree ring + scattered
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	for i in 90:
		var x := rng.randf_range(-33, 33)
		var z := rng.randf_range(-52, 24)
		if abs(x) < 7 and z > -40:
			continue
		add_tree(Vector3(x, 0, z), rng.randf_range(0.8, 1.5), Color(0.15, 0.45 + rng.randf() * 0.15, 0.2))
	for i in 14:
		add_rock(Vector3(rng.randf_range(-20, 20), 0, rng.randf_range(-45, 20)), rng.randf_range(0.6, 1.6))
	add_wall(Vector3(-35, 0, -55), Vector3(-35, 0, 25))
	add_wall(Vector3(35, 0, -55), Vector3(35, 0, 25))
	add_wall(Vector3(-35, 0, 25), Vector3(35, 0, 25))
	add_wall(Vector3(-35, 0, -55), Vector3(35, 0, -55))
	add_sign(Vector3(2.5, 0, 14), "Norte: Templo de Martel.\nSur: Aldea de Iselia.")
	add_npc("villager1", Vector3(-3, 0, 12), "Aldeano", "regal",
		[{"speaker": "Aldeano", "text": "Ten cuidado en el bosque, Lloyd. Últimamente los lobos se acercan mucho al camino."},
		 {"speaker": "Lloyd", "text": "Tranquilo, unos lobos no son nada para mí."}])
	add_monster(Vector3(-4, 0, -2), ["wolf"])
	add_monster(Vector3(5, 0, -12), ["wolf", "wolf"])
	add_monster(Vector3(-3, 0, -24), ["rabbit", "rabbit", "bee"])
	add_monster(Vector3(4, 0, -36), ["wolf", "rabbit", "bee"])
	add_exit(Vector3(0, 1, 24), Vector3(12, 3, 1.5), "iselia_forest", "from_temple")   # placeholder loop until village exists
	add_exit(Vector3(0, 1, -54), Vector3(12, 3, 1.5), "iselia_forest", "from_village") # placeholder loop until temple exists
