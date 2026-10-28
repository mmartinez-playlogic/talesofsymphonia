extends Control
## Title screen.

var _cursor := 0
var _options: Array[Label] = []

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.07, 0.14)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)
	var title := Label.new()
	title.text = "TALES OF SYMPHONIA"
	title.add_theme_font_size_override("font_size", 96)
	title.add_theme_color_override("font_color", Color(0.93, 0.80, 0.35))
	title.set_anchors_preset(PRESET_CENTER_TOP)
	title.position = Vector2(960 - 520, 220)
	title.size = Vector2(1040, 120)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	var sub := Label.new()
	sub.text = "Remake fan · Godot 4"
	sub.add_theme_font_size_override("font_size", 28)
	sub.position = Vector2(960 - 200, 340)
	sub.size = Vector2(400, 40)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(sub)
	var names := ["Nueva partida", "Continuar", "Salir"]
	for i in names.size():
		var l := Label.new()
		l.text = names[i]
		l.add_theme_font_size_override("font_size", 40)
		l.position = Vector2(960 - 150, 560 + i * 64)
		l.size = Vector2(300, 56)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(l)
		_options.append(l)
	_refresh()

func _refresh() -> void:
	for i in _options.size():
		_options[i].modulate = Color(1, 0.9, 0.5) if i == _cursor else Color(0.7, 0.7, 0.75)
		_options[i].text = ("▶ " if i == _cursor else "   ") + _options[i].text.trim_prefix("▶ ").strip_edges()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_down"):
		_cursor = (_cursor + 1) % _options.size()
		_refresh()
	elif event.is_action_pressed("move_up"):
		_cursor = (_cursor - 1 + _options.size()) % _options.size()
		_refresh()
	elif event.is_action_pressed("confirm"):
		match _cursor:
			0:
				Game.new_game()
				Router.goto_map("iselia_school", "default")
			1:
				if Game.load_save(0):
					Router.goto_map(Game.current_map, Game.spawn_point)
			2:
				get_tree().quit()
