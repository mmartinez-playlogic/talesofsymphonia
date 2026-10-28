extends Control
## End-of-demo screen: summary, save, back to title.

var _cursor := 0
var _opts: Array[Label] = []
var _save_menu: SaveMenu
var _busy := false
var _msg: Label

func _ready() -> void:
	Game.set_flag("demo_complete", true)
	Game.current_map = "triet_desert"
	Game.spawn_point = "default"
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.03, 0.08)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)
	var title := Label.new()
	title.text = "Fin de la demo"
	title.add_theme_font_size_override("font_size", 88)
	title.add_theme_color_override("font_color", Color(0.96, 0.84, 0.42))
	title.add_theme_color_override("font_outline_color", Color(0.25, 0.12, 0.05))
	title.add_theme_constant_override("outline_size", 14)
	title.position = Vector2(160, 90)
	title.size = Vector2(1600, 110)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	var sub := Label.new()
	sub.text = "Capítulo 1: Iselia – Desierto de Triet"
	sub.add_theme_font_size_override("font_size", 34)
	sub.position = Vector2(160, 210)
	sub.size = Vector2(1600, 50)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(sub)
	var stats := RichTextLabel.new()
	stats.bbcode_enabled = true
	stats.scroll_active = false
	stats.position = Vector2(460, 300)
	stats.size = Vector2(1000, 420)
	stats.add_theme_font_size_override("normal_font_size", 30)
	stats.text = _summary()
	add_child(stats)
	var thanks := Label.new()
	thanks.text = "Lloyd y Genis han llegado a Triet. Colette está cerca...\nEl viaje continúa en el próximo capítulo. ¡Gracias por jugar!"
	thanks.add_theme_font_size_override("font_size", 28)
	thanks.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
	thanks.position = Vector2(160, 730)
	thanks.size = Vector2(1600, 90)
	thanks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(thanks)
	for i in 2:
		var l := Label.new()
		l.add_theme_font_size_override("font_size", 38)
		l.position = Vector2(960 - 260, 860 + i * 60)
		l.size = Vector2(520, 56)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(l)
		_opts.append(l)
	_msg = Label.new()
	_msg.add_theme_font_size_override("font_size", 24)
	_msg.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	_msg.position = Vector2(160, 1000)
	_msg.size = Vector2(1600, 40)
	_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_msg)
	_save_menu = SaveMenu.new()
	add_child(_save_menu)
	_refresh()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 1.2)

func _summary() -> String:
	var s := int(Game.play_time)
	var t := "[center][color=#f0d070]Tiempo de juego[/color]  %02d:%02d:%02d\n" % [s / 3600, (s / 60) % 60, s % 60]
	t += "[color=#f0d070]Grado[/color]  %.1f      [color=#f0d070]Gald[/color]  %d\n\n" % [Game.grade, Game.gald]
	for id in Game.members:
		var m: Dictionary = Game.members[id]
		t += "%s  Lv %d   «%s»\n" % [DB.characters[id]["name"], m["level"], str(DB.titles.get(m.get("title", ""), {}).get("name", ""))]
	t += "\n[color=#a0c0ff]Skits vistos[/color] %d / %d    [color=#a0c0ff]Recetas[/color] %d / %d[/center]" % [Game.seen_skits.size(), DB.skits.size(), Game.recipes.size(), DB.recipes.size()]
	return t

func _refresh() -> void:
	var names := ["Guardar partida", "Volver al título"]
	for i in 2:
		_opts[i].text = ("▶ " if i == _cursor else "") + names[i]
		_opts[i].modulate = Color(1, 0.9, 0.5) if i == _cursor else Color(0.82, 0.84, 0.9)

func _unhandled_input(event: InputEvent) -> void:
	if _busy or _save_menu.is_open():
		return
	if event.is_action_pressed("move_down") or event.is_action_pressed("move_up"):
		_cursor = 1 - _cursor
		_refresh()
	elif event.is_action_pressed("confirm"):
		get_viewport().set_input_as_handled()
		if _cursor == 0:
			_busy = true
			var slot: int = await _save_menu.open_save(Vector3(-50, 0.1, 0))
			_msg.text = ("Partida guardada en la ranura %d. Al continuar, apareces junto a la puerta de Triet." % (slot + 1)) if slot >= 0 else ""
			_busy = false
		else:
			_busy = true
			Router.goto_scene("res://src/Main.tscn")
