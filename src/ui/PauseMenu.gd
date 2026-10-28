class_name PauseMenu
extends CanvasLayer
## Field pause menu: items, artes shortcuts, status, save. Opened with `menu`; closed with `cancel`.

var field: Node
var _root: Control
var _menu: VBoxContainer
var _content: RichTextLabel
var _list: VBoxContainer
var _hint: Label
var _open := false
var _closed := false
var _mode := "main"          # main | items | items_target | artes_char | artes_list | status | saved
var _cursor := 0
var _labels: Array[Label] = []
var _entries: Array = []     # ids for the current list
var _item_sel := ""
var _char_sel := ""
var _slot_sel := 0
const MAIN := ["Objetos", "Artes", "Estado", "Guardar", "Cerrar"]

func _ready() -> void:
	layer = 70
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.visible = false
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var left := _panel(Vector2(120, 120), Vector2(380, 760))
	_root.add_child(left)
	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 12)
	left.add_child(_menu)
	var right := _panel(Vector2(540, 120), Vector2(1260, 760))
	_root.add_child(right)
	var vb := VBoxContainer.new()
	right.add_child(vb)
	_content = RichTextLabel.new()
	_content.bbcode_enabled = true
	_content.custom_minimum_size = Vector2(1200, 300)
	_content.add_theme_font_size_override("normal_font_size", 28)
	_content.add_theme_font_size_override("bold_font_size", 30)
	vb.add_child(_content)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 6)
	vb.add_child(_list)
	_hint = Label.new()
	_hint.position = Vector2(540, 900)
	_hint.size = Vector2(1260, 40)
	_hint.add_theme_font_size_override("font_size", 24)
	_hint.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	_root.add_child(_hint)

func _panel(pos: Vector2, size: Vector2) -> PanelContainer:
	var p := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.05, 0.14, 0.94)
	style.border_color = Color(0.85, 0.75, 0.45)
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(24)
	p.add_theme_stylebox_override("panel", style)
	p.position = pos
	p.size = size
	return p

func open() -> void:
	_open = true
	_closed = false
	_mode = "main"
	_cursor = 0
	_root.visible = true
	_render()
	while not _closed:
		await get_tree().process_frame
	_root.visible = false
	_open = false

func _render() -> void:
	for c in _menu.get_children():
		c.queue_free()
	for c in _list.get_children():
		c.queue_free()
	_labels.clear()
	_entries.clear()
	var hdr := Label.new()
	hdr.text = "Gald: %d    Tiempo: %s" % [Game.gald, _time()]
	hdr.add_theme_font_size_override("font_size", 22)
	hdr.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
	_menu.add_child(hdr)
	for i in MAIN.size():
		var l := Label.new()
		l.text = MAIN[i]
		l.add_theme_font_size_override("font_size", 34)
		l.modulate = Color(1, 0.9, 0.5) if (_mode == "main" and i == _cursor) else Color(0.85, 0.85, 0.9)
		_menu.add_child(l)
	match _mode:
		"main":
			_content.text = _party_summary()
			_hint.text = "Confirmar: elegir   Cancelar: cerrar"
		"items":
			_content.text = "[b]Objetos[/b]"
			var ids: Array = Game.inventory.keys()
			ids.sort()
			for id in ids:
				var it: Dictionary = DB.items.get(id, {})
				if it.get("type", "") != "consumable":
					continue
				_entries.append(id)
				_add_row("%s  x%d   [%s]" % [it.get("name", id), Game.inventory[id], it.get("desc", "")])
			if _entries.is_empty():
				_add_row("(sin objetos usables)")
			_hint.text = "Confirmar: usar   Cancelar: volver"
		"items_target":
			_content.text = "[b]Usar %s en...[/b]" % DB.items[_item_sel]["name"]
			for id in Game.party:
				_entries.append(id)
				var m: Dictionary = Game.members[id]
				_add_row("%s   HP %d/%d   TP %d/%d" % [DB.characters[id]["name"], m["hp"], Game.max_hp(id), m["tp"], Game.max_tp(id)])
			_hint.text = "Confirmar: usar   Cancelar: volver"
		"artes_char":
			_content.text = "[b]Artes: elige personaje[/b]"
			for id in Game.party:
				_entries.append(id)
				_add_row(DB.characters[id]["name"])
			_hint.text = "Confirmar: elegir   Cancelar: volver"
		"artes_list":
			var m: Dictionary = Game.members[_char_sel]
			var sc: Array = m.get("shortcuts", [])
			_content.text = "[b]%s: atajos de artes[/b]\nAtajo 1: %s   Atajo 2 (↑): %s   Atajo 3 (↓): %s\nSelecciona un arte y pulsa Confirmar para asignarla al atajo %d." % [
				DB.characters[_char_sel]["name"], _arte_name(sc, 0), _arte_name(sc, 1), _arte_name(sc, 2), _slot_sel + 1]
			for a in m["artes"]:
				_entries.append(a)
				var d: Dictionary = DB.artes[a]
				_add_row("%s   TP %d   %s" % [d["name"], d["tp"], d.get("desc", "")])
			_hint.text = "Confirmar: asignar al atajo %d   Izq/Der: cambiar atajo   Cancelar: volver" % (_slot_sel + 1)
		"status":
			_content.text = _status_text()
			_hint.text = "Cancelar: volver"
		"saved":
			_content.text = "[b]Partida guardada.[/b]"
			_hint.text = "Cancelar: volver"
	_refresh_rows()

func _arte_name(sc: Array, i: int) -> String:
	if i < sc.size() and DB.artes.has(sc[i]):
		return DB.artes[sc[i]]["name"]
	return "-"

func _add_row(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 26)
	_list.add_child(l)
	_labels.append(l)

func _refresh_rows() -> void:
	for i in _labels.size():
		var sel := (i == _cursor and _mode != "main" and not _entries.is_empty())
		_labels[i].modulate = Color(1, 0.9, 0.5) if sel else Color(0.85, 0.85, 0.9)
		_labels[i].text = ("▶ " if sel else "   ") + _labels[i].text.trim_prefix("▶ ").strip_edges()

func _time() -> String:
	var s := int(Game.play_time)
	return "%02d:%02d:%02d" % [s / 3600, (s / 60) % 60, s % 60]

func _party_summary() -> String:
	var t := "[b]Grupo[/b]\n"
	for id in Game.party:
		var m: Dictionary = Game.members[id]
		t += "%s   Lv %d   HP %d/%d   TP %d/%d\n" % [DB.characters[id]["name"], m["level"], m["hp"], Game.max_hp(id), m["tp"], Game.max_tp(id)]
	return t

func _status_text() -> String:
	var t := "[b]Estado[/b]\n"
	for id in Game.party:
		var m: Dictionary = Game.members[id]
		var nxt: int = DB.exp_for_level(int(m["level"]) + 1) - int(m["exp"])
		t += "[color=#f0d070]%s[/color]  «%s»  Lv %d  (EXP para subir: %d)\n" % [DB.characters[id]["name"], m.get("title", ""), m["level"], nxt]
		t += "   HP %d/%d  TP %d/%d  ATK %d  DEF %d  INT %d  SPR %d  ACC %d  EVA %d  LUCK %d\n" % [
			m["hp"], Game.max_hp(id), m["tp"], Game.max_tp(id), Game.stat(id, "atk"), Game.stat(id, "def"),
			Game.stat(id, "int"), Game.stat(id, "spr"), Game.stat(id, "acc"), Game.stat(id, "eva"), Game.stat(id, "luck")]
		var eq: Dictionary = m["equipment"]
		t += "   Arma: %s   Cuerpo: %s\n" % [DB.items.get(eq.get("weapon", ""), {}).get("name", "-"), DB.items.get(eq.get("body", ""), {}).get("name", "-")]
	return t

func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	var n := MAIN.size() if _mode == "main" else _entries.size()
	if event.is_action_pressed("move_down") and n > 0:
		_cursor = (_cursor + 1) % n
		_render()
	elif event.is_action_pressed("move_up") and n > 0:
		_cursor = (_cursor - 1 + n) % n
		_render()
	elif event.is_action_pressed("move_right") and _mode == "artes_list":
		_slot_sel = (_slot_sel + 1) % 3
		_render()
	elif event.is_action_pressed("move_left") and _mode == "artes_list":
		_slot_sel = (_slot_sel + 2) % 3
		_render()
	elif event.is_action_pressed("confirm"):
		_confirm()
	elif event.is_action_pressed("cancel") or event.is_action_pressed("menu"):
		if _mode == "main":
			_closed = true
		else:
			_mode = "items" if _mode == "items_target" else ("artes_char" if _mode == "artes_list" else "main")
			_cursor = 0
			_render()
	else:
		return
	get_viewport().set_input_as_handled()

func _confirm() -> void:
	match _mode:
		"main":
			match _cursor:
				0: _mode = "items"
				1: _mode = "artes_char"
				2: _mode = "status"
				3:
					Game.save(0)
					_mode = "saved"
				4:
					_closed = true
					return
			_cursor = 0
			_render()
		"items":
			if _entries.is_empty():
				return
			_item_sel = _entries[_cursor]
			_mode = "items_target"
			_cursor = 0
			_render()
		"items_target":
			if _entries.is_empty():
				return
			if Game.use_item(_item_sel, _entries[_cursor]):
				if not Game.has_item(_item_sel):
					_mode = "items"
					_cursor = 0
			_render()
		"artes_char":
			if _entries.is_empty():
				return
			_char_sel = _entries[_cursor]
			_slot_sel = 0
			_mode = "artes_list"
			_cursor = 0
			_render()
		"artes_list":
			if _entries.is_empty():
				return
			var m: Dictionary = Game.members[_char_sel]
			var sc: Array = m.get("shortcuts", m["artes"].slice(0, 3)).duplicate()
			while sc.size() < 3:
				sc.append("")
			sc[_slot_sel] = _entries[_cursor]
			m["shortcuts"] = sc
			_render()
