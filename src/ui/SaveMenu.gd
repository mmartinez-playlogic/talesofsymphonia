class_name SaveMenu
extends CanvasLayer
## Save / load slot picker.
##   var slot: int = await menu.open_save(player_pos)   # -1 if cancelled
##   var slot: int = await menu.open_load()             # -1 if cancelled; the save is already loaded into Game

var _root: Control
var _title: Label
var _rows: Array[PanelContainer] = []
var _labels: Array[RichTextLabel] = []
var _hint: Label
var _cursor := 0
var _mode := "save"
var _open := false
var _result := -2
var _confirm_overwrite := false
var _pos = null

func _ready() -> void:
	layer = 80
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.visible = false
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	_title = Label.new()
	_title.position = Vector2(360, 110)
	_title.size = Vector2(1200, 60)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 44)
	_title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5))
	_root.add_child(_title)
	for i in Game.SLOT_COUNT:
		var p := PanelContainer.new()
		p.position = Vector2(360, 210 + i * 210)
		p.size = Vector2(1200, 180)
		_root.add_child(p)
		var t := RichTextLabel.new()
		t.bbcode_enabled = true
		t.scroll_active = false
		t.add_theme_font_size_override("normal_font_size", 28)
		t.add_theme_font_size_override("bold_font_size", 32)
		p.add_child(t)
		_rows.append(p)
		_labels.append(t)
	_hint = Label.new()
	_hint.position = Vector2(360, 860)
	_hint.size = Vector2(1200, 40)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 24)
	_hint.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	_root.add_child(_hint)

func _style(selected: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.08, 0.1, 0.24, 0.96) if selected else Color(0.03, 0.05, 0.13, 0.92)
	s.border_color = Color(1.0, 0.88, 0.5) if selected else Color(0.6, 0.55, 0.4)
	s.set_border_width_all(4 if selected else 2)
	s.set_corner_radius_all(12)
	s.set_content_margin_all(22)
	return s

func _fmt_time(t: float) -> String:
	var s := int(t)
	return "%02d:%02d:%02d" % [s / 3600, (s / 60) % 60, s % 60]

func _render() -> void:
	_title.text = "Guardar partida" if _mode == "save" else "Cargar partida"
	for i in Game.SLOT_COUNT:
		_rows[i].add_theme_stylebox_override("panel", _style(i == _cursor))
		var info: Dictionary = Game.slot_info(i)
		if info.is_empty():
			_labels[i].text = "[b]Ranura %d[/b]\n[color=#888899]— Vacía —[/color]" % (i + 1)
			continue
		var party_txt := []
		for e in info.get("party", []):
			party_txt.append("%s Lv%d" % [str(DB.characters.get(str(e[0]), {}).get("name", e[0])).split(" ")[0], int(e[1])])
		_labels[i].text = "[b]Ranura %d · %s[/b]%s\n%s\nTiempo %s    Gald %d    [color=#9090a8]%s[/color]" % [
			i + 1, info.get("map_title", "?"), "   [color=#f0d070]★ Demo completada[/color]" if info.get("demo_complete", false) else "",
			"   ".join(party_txt), _fmt_time(float(info.get("time", 0))), int(info.get("gald", 0)), str(info.get("date", ""))]
	if _confirm_overwrite:
		_hint.text = "La ranura %d ya tiene una partida. Confirmar otra vez para sobrescribir · Cancelar: no" % (_cursor + 1)
	else:
		_hint.text = "Arriba/Abajo: elegir · Confirmar: %s · Cancelar: volver" % ("guardar" if _mode == "save" else "cargar")

func open_save(pos) -> int:
	_mode = "save"
	_pos = pos
	return await _run()

func open_load() -> int:
	_mode = "load"
	_pos = null
	return await _run()

func _run() -> int:
	_cursor = 0
	_confirm_overwrite = false
	_result = -2
	_open = true
	_root.visible = true
	_render()
	while _result == -2:
		if not is_inside_tree():
			return -1
		await get_tree().process_frame
	_root.visible = false
	_open = false
	return _result

func is_open() -> bool:
	return _open

func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("move_down"):
		_cursor = (_cursor + 1) % Game.SLOT_COUNT
		_confirm_overwrite = false
		Audio.sfx("ui_cursor")
	elif event.is_action_pressed("move_up"):
		_cursor = (_cursor - 1 + Game.SLOT_COUNT) % Game.SLOT_COUNT
		_confirm_overwrite = false
		Audio.sfx("ui_cursor")
	elif event.is_action_pressed("confirm"):
		if _mode == "save":
			if Game.save_exists(_cursor) and not _confirm_overwrite:
				_confirm_overwrite = true
				Audio.sfx("ui_error")
			else:
				Game.save(_cursor, _pos)
				Audio.sfx("save")
				_result = _cursor
		else:
			if Game.save_exists(_cursor) and Game.load_save(_cursor):
				Audio.sfx("save")
				_result = _cursor
			else:
				Audio.sfx("ui_error")
	elif event.is_action_pressed("cancel") or event.is_action_pressed("menu"):
		Audio.sfx("ui_cancel")
		if _confirm_overwrite:
			_confirm_overwrite = false
		else:
			_result = -1
	else:
		return
	get_viewport().set_input_as_handled()
	if _open:
		_render()
