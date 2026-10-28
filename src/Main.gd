extends Control
## Title screen: New Game / Continue (slot picker, greyed out without saves) / Exit.

var _cursor := 0
var _options: Array[Label] = []
var _names := ["Nueva partida", "Continuar", "Salir"]
var _save_menu: SaveMenu
var _busy := false
var _has_save := false
var _t := 0.0
var _logo: Label

func _ready() -> void:
	var bg := TextureRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	var grad := Gradient.new()
	grad.set_color(0, Color(0.03, 0.05, 0.16))
	grad.set_color(1, Color(0.2, 0.32, 0.55))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0.5, 1.0)
	gt.fill_to = Vector2(0.5, 0.0)
	gt.width = 64
	gt.height = 256
	bg.texture = gt
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(bg)
	# the Tower of Salvation on the horizon
	var tower := ColorRect.new()
	tower.color = Color(0.85, 0.9, 1.0, 0.25)
	tower.position = Vector2(1440, 0)
	tower.size = Vector2(26, 900)
	add_child(tower)
	var glow := ColorRect.new()
	glow.color = Color(0.9, 0.95, 1.0, 0.08)
	glow.position = Vector2(1400, 0)
	glow.size = Vector2(106, 900)
	add_child(glow)
	_logo = Label.new()
	_logo.text = "TALES OF SYMPHONIA"
	_logo.add_theme_font_size_override("font_size", 104)
	_logo.add_theme_color_override("font_color", Color(0.96, 0.84, 0.42))
	_logo.add_theme_color_override("font_outline_color", Color(0.25, 0.12, 0.05))
	_logo.add_theme_constant_override("outline_size", 18)
	_logo.position = Vector2(200, 200)
	_logo.size = Vector2(1520, 140)
	_logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_logo)
	var sub := Label.new()
	sub.text = "Remake fan · Demo: Capítulo 1 (Iselia – Desierto de Triet)"
	sub.add_theme_font_size_override("font_size", 30)
	sub.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	sub.position = Vector2(200, 350)
	sub.size = Vector2(1520, 44)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(sub)
	for i in _names.size():
		var l := Label.new()
		l.add_theme_font_size_override("font_size", 42)
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		l.add_theme_constant_override("outline_size", 8)
		l.position = Vector2(960 - 220, 580 + i * 70)
		l.size = Vector2(440, 60)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(l)
		_options.append(l)
	var hint := Label.new()
	hint.text = "J / Espacio: confirmar · K / Esc: cancelar · WASD / flechas: mover"
	hint.add_theme_font_size_override("font_size", 22)
	hint.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	hint.position = Vector2(200, 1000)
	hint.size = Vector2(1520, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hint)
	_save_menu = SaveMenu.new()
	add_child(_save_menu)
	_has_save = Game.any_save()
	_cursor = 1 if _has_save else 0
	_refresh()

func _process(delta: float) -> void:
	_t += delta
	_logo.modulate = Color(1, 1, 1, 0.9 + 0.1 * sin(_t * 1.5))

func _refresh() -> void:
	for i in _options.size():
		var enabled := not (i == 1 and not _has_save)
		var sel := i == _cursor
		_options[i].text = ("▶ " if sel else "") + _names[i]
		if not enabled:
			_options[i].modulate = Color(0.45, 0.45, 0.5)
		else:
			_options[i].modulate = Color(1, 0.9, 0.5) if sel else Color(0.82, 0.84, 0.9)

func _unhandled_input(event: InputEvent) -> void:
	if _busy or _save_menu.is_open():
		return
	if event.is_action_pressed("move_down"):
		_cursor = (_cursor + 1) % _options.size()
		_refresh()
	elif event.is_action_pressed("move_up"):
		_cursor = (_cursor - 1 + _options.size()) % _options.size()
		_refresh()
	elif event.is_action_pressed("confirm"):
		get_viewport().set_input_as_handled()
		match _cursor:
			0:
				_busy = true
				Game.new_game()
				Router.goto_map("iselia_school", "default")
			1:
				if not _has_save:
					return
				_busy = true
				var slot: int = await _save_menu.open_load()
				if slot >= 0:
					Router.goto_map(Game.current_map, Game.spawn_point)
				else:
					_busy = false
			2:
				get_tree().quit()
