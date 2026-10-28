class_name PauseMenu
extends CanvasLayer
## Field pause menu: items, equipment, artes shortcuts, cooking, titles, EX skills, status, manual, save.
## Navigation: up/down move, left/right change sub-selection, confirm, cancel/menu back.

var field: Node
var _root: Control
var _menu: VBoxContainer
var _content: RichTextLabel
var _list: VBoxContainer
var _hint: Label
var _open := false
var _closed := false
var _mode := "main"
var _cursor := 0
var _labels: Array[Label] = []
var _entries: Array = []
var _item_sel := ""
var _char_sel := ""
var _slot_sel := 0
var _recipe_sel := ""
var _equip_slot := "weapon"
var _msg := ""
const MAIN := ["Objetos", "Equipo", "Artes", "Cocina", "Títulos", "EX Skills", "Estado", "Manual", "Guardar", "Cerrar"]

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
	var left := _panel(Vector2(100, 100), Vector2(360, 820))
	_root.add_child(left)
	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 8)
	left.add_child(_menu)
	var right := _panel(Vector2(490, 100), Vector2(1330, 820))
	_root.add_child(right)
	var vb := VBoxContainer.new()
	right.add_child(vb)
	_content = RichTextLabel.new()
	_content.bbcode_enabled = true
	_content.custom_minimum_size = Vector2(1270, 260)
	_content.add_theme_font_size_override("normal_font_size", 26)
	_content.add_theme_font_size_override("bold_font_size", 30)
	vb.add_child(_content)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 4)
	vb.add_child(_list)
	_hint = Label.new()
	_hint.position = Vector2(490, 930)
	_hint.size = Vector2(1330, 40)
	_hint.add_theme_font_size_override("font_size", 22)
	_hint.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	_root.add_child(_hint)

func _panel(pos: Vector2, size: Vector2) -> PanelContainer:
	var p := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.05, 0.14, 0.94)
	style.border_color = Color(0.85, 0.75, 0.45)
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(22)
	p.add_theme_stylebox_override("panel", style)
	p.position = pos
	p.size = size
	return p

func open() -> void:
	_open = true
	_closed = false
	_mode = "main"
	_cursor = 0
	_msg = ""
	_root.visible = true
	_render()
	while not _closed:
		await get_tree().process_frame
	_root.visible = false
	_open = false

func _name(id: String) -> String:
	return str(DB.characters.get(id, {}).get("name", id)).split(" ")[0]

func _item_name(id: String) -> String:
	return str(DB.items.get(id, {}).get("name", "-" if id == "" else id))

func _render() -> void:
	for c in _menu.get_children():
		c.queue_free()
	for c in _list.get_children():
		c.queue_free()
	_labels.clear()
	_entries.clear()
	var hdr := Label.new()
	hdr.text = "Gald: %d\nTiempo: %s\nGrado: %.1f" % [Game.gald, _time(), Game.grade]
	hdr.add_theme_font_size_override("font_size", 20)
	hdr.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
	_menu.add_child(hdr)
	for i in MAIN.size():
		var l := Label.new()
		l.text = MAIN[i]
		l.add_theme_font_size_override("font_size", 30)
		l.modulate = Color(1, 0.9, 0.5) if (_mode == "main" and i == _cursor) else Color(0.85, 0.85, 0.9)
		_menu.add_child(l)
	var msg := ("\n[color=#a0ffa0]%s[/color]" % _msg) if _msg != "" else ""
	match _mode:
		"main":
			_content.text = _party_summary() + msg
			_hint.text = "Confirmar: elegir   Cancelar: cerrar"
		"items":
			_content.text = "[b]Objetos[/b]" + msg
			var ids: Array = Game.inventory.keys()
			ids.sort()
			for id in ids:
				var it: Dictionary = DB.items.get(id, {})
				var t: String = str(it.get("type", ""))
				_entries.append(id)
				_add_row("%s  x%d   [%s]  %s" % [it.get("name", id), Game.inventory[id], _type_name(t), it.get("desc", "")])
			if _entries.is_empty():
				_add_row("(inventario vacío)")
			_hint.text = "Confirmar: usar (consumibles)   Cancelar: volver"
		"items_target":
			_content.text = "[b]Usar %s en...[/b]" % _item_name(_item_sel)
			for id in Game.party:
				_entries.append(id)
				_add_row(_member_row(id))
			_hint.text = "Confirmar: usar   Cancelar: volver"
		"char_pick":
			_content.text = "[b]%s: elige personaje[/b]" % MAIN[_cursor_main]
			for id in Game.party:
				_entries.append(id)
				_add_row(_member_row(id))
			_hint.text = "Confirmar: elegir   Cancelar: volver"
		"equip":
			var m: Dictionary = Game.members[_char_sel]
			_content.text = "[b]Equipo de %s[/b]   ATK %d  DEF %d  INT %d  SPR %d  ACC %d  EVA %d%s" % [_name(_char_sel), Game.stat(_char_sel, "atk"), Game.stat(_char_sel, "def"), Game.stat(_char_sel, "int"), Game.stat(_char_sel, "spr"), Game.stat(_char_sel, "acc"), Game.stat(_char_sel, "eva"), msg]
			for slot in Game.SLOTS:
				_entries.append(slot)
				_add_row("%s: %s" % [Game.SLOT_NAMES[slot], _item_name(str(m["equipment"].get(slot, "")))])
			_hint.text = "Confirmar: cambiar   Izquierda: quitar   Cancelar: volver"
		"equip_pick":
			_content.text = "[b]%s · %s[/b]  (los números muestran el cambio de ATK/DEF)" % [_name(_char_sel), Game.SLOT_NAMES[_equip_slot]]
			var cur_atk := Game.stat(_char_sel, "atk")
			var cur_def := Game.stat(_char_sel, "def")
			for id in Game.equippable_items(_char_sel, _equip_slot):
				_entries.append(id)
				var st: Dictionary = DB.items[id].get("stats", {})
				var cur_item: Dictionary = DB.items.get(str(Game.members[_char_sel]["equipment"].get(_equip_slot, "")), {})
				var d_atk: int = int(st.get("atk", 0)) - int(cur_item.get("stats", {}).get("atk", 0))
				var d_def: int = int(st.get("def", 0)) - int(cur_item.get("stats", {}).get("def", 0))
				_add_row("%s  x%d   ATK %+d  DEF %+d" % [_item_name(id), Game.item_count(id), d_atk, d_def])
			if _entries.is_empty():
				_add_row("(nada equipable en este hueco)")
			_hint.text = "Confirmar: equipar   Cancelar: volver"
		"artes":
			var m: Dictionary = Game.members[_char_sel]
			var sc: Array = m.get("shortcuts", [])
			_content.text = "[b]%s: artes y atajos[/b]\nAtajo 1 (Arte): %s   Atajo 2 (↑+Arte): %s   Atajo 3 (↓+Arte): %s\nSelecciona un arte y pulsa Confirmar para asignarla al atajo %d (Izq/Der cambia el atajo)." % [
				_name(_char_sel), _arte_name(sc, 0), _arte_name(sc, 1), _arte_name(sc, 2), _slot_sel + 1]
			for a in m["artes"]:
				_entries.append(a)
				var d: Dictionary = DB.artes[a]
				_add_row("%s   TP %d   %s" % [d["name"], d["tp"], d.get("desc", "")])
			_hint.text = "Confirmar: asignar   Izq/Der: atajo   Cancelar: volver"
		"cook":
			_content.text = "[b]Cocina[/b]  Elige una receta; luego quién cocina. Cada éxito mejora la habilidad del cocinero." + msg
			for r in Game.recipes:
				var rd: Dictionary = DB.recipes[r]
				var ings := []
				for ing in rd["ingredients"]:
					ings.append("%s x%d (%d)" % [_item_name(ing), rd["ingredients"][ing], Game.item_count(ing)])
				_entries.append(r)
				_add_row("%s%s   %s   [%s]" % ["" if Game.can_cook(r) else "✗ ", rd["name"], rd.get("desc", ""), ", ".join(ings)])
			if _entries.is_empty():
				_add_row("(no conoces ninguna receta)")
			_hint.text = "Confirmar: elegir receta   Cancelar: volver"
		"cook_who":
			_content.text = "[b]%s: ¿quién cocina?[/b]" % DB.recipes[_recipe_sel]["name"]
			for id in Game.party:
				_entries.append(id)
				var stars := "★".repeat(min(5, Game.cook_skill(id, _recipe_sel)))
				_add_row("%s   habilidad %s%s" % [_name(id), stars if stars != "" else "-", "   (le sale bien)" if (DB.recipes[_recipe_sel].get("best", []) as Array).has(id) else ""])
			_hint.text = "Confirmar: cocinar   Cancelar: volver"
		"titles":
			var m: Dictionary = Game.members[_char_sel]
			_content.text = "[b]Títulos de %s[/b]  Título actual: %s" % [_name(_char_sel), str(DB.titles.get(m.get("title", ""), {}).get("name", "-"))]
			for t in m["titles"]:
				_entries.append(t)
				var td: Dictionary = DB.titles[t]
				var mods := []
				for k in td.get("mods", {}):
					mods.append("%s %+d%%" % [k.to_upper(), int(round(float(td["mods"][k]) * 100))])
				_add_row("%s%s   %s   %s" % ["● " if m.get("title", "") == t else "   ", td["name"], td.get("desc", ""), ", ".join(mods)])
			_hint.text = "Confirmar: equipar título   Cancelar: volver"
		"ex":
			var m: Dictionary = Game.members[_char_sel]
			_content.text = "[b]EX Skills de %s[/b]  Gemas: Nv1 x%d  Nv2 x%d  Nv3 x%d  Nv4 x%d%s" % [_name(_char_sel), Game.item_count("ex_gem_1"), Game.item_count("ex_gem_2"), Game.item_count("ex_gem_3"), Game.item_count("ex_gem_4"), msg]
			for lvl in [1, 2, 3, 4]:
				_entries.append(lvl)
				var sid: String = str(m["ex_gems"].get(str(lvl), ""))
				var sname := "-"
				for sk in DB.ex_skills.get(_char_sel, []):
					if sk["id"] == sid:
						sname = "%s  (%s)" % [sk["name"], sk["desc"]]
				_add_row("Nivel %d: %s" % [lvl, sname])
			_hint.text = "Confirmar: elegir skill   Izquierda: quitar gema   Cancelar: volver"
		"ex_pick":
			_content.text = "[b]%s · EX Skill nivel %d[/b]  (necesitas una EX Gem Nv. %d si el hueco está vacío)" % [_name(_char_sel), _slot_sel, _slot_sel]
			for sk in Game.ex_skills_for(_char_sel, _slot_sel):
				_entries.append(sk["id"])
				_add_row("%s   %s" % [sk["name"], sk["desc"]])
			_hint.text = "Confirmar: asignar   Cancelar: volver"
		"status":
			_content.text = _status_text()
			_hint.text = "Cancelar: volver"
		"manual":
			_content.text = _manual_text()
			_hint.text = "Cancelar: volver"
		"saved":
			_content.text = "[b]Partida guardada.[/b]"
			_hint.text = "Cancelar: volver"
	_refresh_rows()

var _cursor_main := 0

func _type_name(t: String) -> String:
	return {"consumable": "objeto", "ingredient": "ingrediente", "weapon": "arma", "body": "cuerpo", "head": "cabeza", "arm": "brazos", "accessory": "accesorio", "key": "clave", "ex_gem": "EX Gem"}.get(t, t)

func _member_row(id: String) -> String:
	var m: Dictionary = Game.members[id]
	return "%s   Lv %d   HP %d/%d   TP %d/%d" % [_name(id), m["level"], m["hp"], Game.max_hp(id), m["tp"], Game.max_tp(id)]

func _arte_name(sc: Array, i: int) -> String:
	if i < sc.size() and DB.artes.has(sc[i]):
		return DB.artes[sc[i]]["name"]
	return "-"

func _add_row(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 24)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 1260
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
		t += "%s  «%s»  Lv %d   HP %d/%d   TP %d/%d\n" % [DB.characters[id]["name"], str(DB.titles.get(m.get("title", ""), {}).get("name", "")), m["level"], m["hp"], Game.max_hp(id), m["tp"], Game.max_tp(id)]
	return t

func _status_text() -> String:
	var t := "[b]Estado[/b]\n"
	for id in Game.party:
		var m: Dictionary = Game.members[id]
		var nxt: int = DB.exp_for_level(int(m["level"]) + 1) - int(m["exp"])
		t += "[color=#f0d070]%s[/color]  «%s»  Lv %d  (EXP para subir: %d)\n" % [DB.characters[id]["name"], str(DB.titles.get(m.get("title", ""), {}).get("name", "")), m["level"], nxt]
		t += "   HP %d/%d  TP %d/%d  ATK %d  DEF %d  INT %d  SPR %d  ACC %d  EVA %d  LUCK %d\n" % [
			m["hp"], Game.max_hp(id), m["tp"], Game.max_tp(id), Game.stat(id, "atk"), Game.stat(id, "def"),
			Game.stat(id, "int"), Game.stat(id, "spr"), Game.stat(id, "acc"), Game.stat(id, "eva"), Game.stat(id, "luck")]
		var eq: Dictionary = m["equipment"]
		t += "   Arma: %s   Cuerpo: %s   Cabeza: %s   Brazos: %s   Acc: %s / %s\n" % [_item_name(str(eq.get("weapon", ""))), _item_name(str(eq.get("body", ""))), _item_name(str(eq.get("head", ""))), _item_name(str(eq.get("arm", ""))), _item_name(str(eq.get("acc1", ""))), _item_name(str(eq.get("acc2", "")))]
	return t

func _manual_text() -> String:
	return "[b]Manual de entrenamiento[/b]\n" + \
		"Campo: WASD/flechas mover · Shift andar · J confirmar/hablar · K lanzar el Anillo del Hechicero (aturde monstruos) · I menú · U skit.\n" + \
		"Combate: A/D moverse en línea · W/S cambiar fila · J atacar (hasta 3 golpes) · K arte (↑/↓ + K otros atajos) · L guardar · Tab cambiar objetivo · Shift carrera libre · I objetos · N Unison Attack (con la barra llena).\n" + \
		"Over Limit: al recibir daño se carga la barra naranja; llena, el personaje no se tambalea y pega más fuerte durante unos segundos.\n" + \
		"Unison Attack: cada golpe del grupo carga la barra azul; con N, todo el grupo lanza un arte a la vez.\n" + \
		"Ventaja: tocar a un monstruo por la espalda da ventaja; que te toque por la espalda, emboscada. Un monstruo aturdido por el anillo siempre da ventaja.\n" + \
		"Cocina: tras conseguir recetas, cocina desde el menú para curar a todo el grupo. Cada cocinero mejora con la práctica.\n" + \
		"EX Skills: equipa EX Gems por nivel para desbloquear habilidades pasivas. Títulos: cambian ligeramente las estadísticas."

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
	elif event.is_action_pressed("move_right") and _mode == "artes":
		_slot_sel = (_slot_sel + 1) % 3
		_render()
	elif event.is_action_pressed("move_left") and _mode == "artes":
		_slot_sel = (_slot_sel + 2) % 3
		_render()
	elif event.is_action_pressed("move_left") and _mode == "equip" and not _entries.is_empty():
		Game.unequip(_char_sel, _entries[_cursor])
		_render()
	elif event.is_action_pressed("move_left") and _mode == "ex" and not _entries.is_empty():
		Game.set_ex_gem(_char_sel, int(_entries[_cursor]), "")
		_render()
	elif event.is_action_pressed("confirm"):
		_confirm()
	elif event.is_action_pressed("cancel") or event.is_action_pressed("menu"):
		_msg = ""
		if _mode == "main":
			_closed = true
		else:
			_mode = {"items_target": "items", "equip_pick": "equip", "cook_who": "cook", "ex_pick": "ex", "equip": "char_pick", "artes": "char_pick", "titles": "char_pick", "ex": "char_pick"}.get(_mode, "main")
			if _mode == "main":
				_cursor = _cursor_main
			else:
				_cursor = 0
			_render()
	else:
		return
	get_viewport().set_input_as_handled()

func _confirm() -> void:
	_msg = ""
	match _mode:
		"main":
			_cursor_main = _cursor
			match _cursor:
				0: _mode = "items"
				1, 2, 4, 5: _mode = "char_pick"
				3: _mode = "cook"
				6: _mode = "status"
				7: _mode = "manual"
				8:
					Game.save(0)
					_mode = "saved"
				9:
					_closed = true
					return
			_cursor = 0
			_render()
		"items":
			if _entries.is_empty():
				return
			_item_sel = _entries[_cursor]
			if DB.items[_item_sel].get("type", "") != "consumable":
				_msg = "Ese objeto no se puede usar aquí."
				_render()
				return
			_mode = "items_target"
			_cursor = 0
			_render()
		"items_target":
			if _entries.is_empty():
				return
			if Game.use_item(_item_sel, _entries[_cursor]):
				_msg = "Has usado %s." % _item_name(_item_sel)
				if not Game.has_item(_item_sel):
					_mode = "items"
					_cursor = 0
			else:
				_msg = "No tiene efecto."
			_render()
		"char_pick":
			if _entries.is_empty():
				return
			_char_sel = _entries[_cursor]
			_mode = {1: "equip", 2: "artes", 4: "titles", 5: "ex"}.get(_cursor_main, "main")
			_slot_sel = 0
			_cursor = 0
			_render()
		"equip":
			_equip_slot = _entries[_cursor]
			_mode = "equip_pick"
			_cursor = 0
			_render()
		"equip_pick":
			if _entries.is_empty():
				return
			Game.equip(_char_sel, _equip_slot, _entries[_cursor])
			_mode = "equip"
			_cursor = Game.SLOTS.find(_equip_slot)
			_msg = "Equipado."
			_render()
		"artes":
			if _entries.is_empty():
				return
			var m: Dictionary = Game.members[_char_sel]
			var sc: Array = m.get("shortcuts", []).duplicate()
			if sc.is_empty():
				sc = m["artes"].slice(0, 3).duplicate()
			while sc.size() < 3:
				sc.append("")
			sc[_slot_sel] = _entries[_cursor]
			m["shortcuts"] = sc
			_render()
		"cook":
			if _entries.is_empty():
				return
			_recipe_sel = _entries[_cursor]
			if not Game.can_cook(_recipe_sel):
				_msg = "Faltan ingredientes."
				_render()
				return
			_mode = "cook_who"
			_cursor = 0
			_render()
		"cook_who":
			if _entries.is_empty():
				return
			var r: Dictionary = Game.cook(_recipe_sel, _entries[_cursor])
			_msg = r["msg"]
			_mode = "cook"
			_cursor = 0
			_render()
		"titles":
			if _entries.is_empty():
				return
			Game.set_title(_char_sel, _entries[_cursor])
			_render()
		"ex":
			_slot_sel = int(_entries[_cursor])
			_mode = "ex_pick"
			_cursor = 0
			_render()
		"ex_pick":
			if _entries.is_empty():
				return
			if Game.set_ex_gem(_char_sel, _slot_sel, _entries[_cursor]):
				_msg = "EX Skill asignada."
			else:
				_msg = "Necesitas una EX Gem Nv. %d." % _slot_sel
			_mode = "ex"
			_cursor = _slot_sel - 1
			_render()
