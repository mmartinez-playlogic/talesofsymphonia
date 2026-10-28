class_name ShopMenu
extends CanvasLayer
## Buy/sell shop. Usage: await shop.open("iselia")

var _root: Control
var _title: Label
var _list: VBoxContainer
var _info: RichTextLabel
var _hint: Label
var _labels: Array[Label] = []
var _entries: Array = []
var _cursor := 0
var _mode := "top"      # top | buy | sell
var _qty := 1
var _open := false
var _closed := false
var _shop_id := ""
var _msg := ""

func _ready() -> void:
	layer = 72
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.visible = false
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var p := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.04, 0.12, 0.95)
	style.border_color = Color(0.85, 0.75, 0.45)
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(24)
	p.add_theme_stylebox_override("panel", style)
	p.position = Vector2(200, 100)
	p.size = Vector2(1520, 820)
	_root.add_child(p)
	var vb := VBoxContainer.new()
	p.add_child(vb)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 36)
	_title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5))
	vb.add_child(_title)
	_info = RichTextLabel.new()
	_info.bbcode_enabled = true
	_info.custom_minimum_size = Vector2(1460, 90)
	_info.add_theme_font_size_override("normal_font_size", 24)
	vb.add_child(_info)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 4)
	vb.add_child(_list)
	_hint = Label.new()
	_hint.position = Vector2(200, 930)
	_hint.size = Vector2(1520, 40)
	_hint.add_theme_font_size_override("font_size", 22)
	_hint.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	_root.add_child(_hint)

func open(shop_id: String) -> void:
	_shop_id = shop_id
	_mode = "top"
	_cursor = 0
	_qty = 1
	_msg = ""
	_open = true
	_closed = false
	_root.visible = true
	_render()
	while not _closed:
		await get_tree().process_frame
	_root.visible = false
	_open = false

func _render() -> void:
	for c in _list.get_children():
		c.queue_free()
	_labels.clear()
	_entries.clear()
	var shop: Dictionary = DB.shops.get(_shop_id, {"name": "Tienda", "items": []})
	_title.text = "%s        Gald: %d" % [shop.get("name", "Tienda"), Game.gald]
	var msg := ("[color=#a0ffa0]%s[/color]" % _msg) if _msg != "" else ""
	match _mode:
		"top":
			_info.text = "¿Qué deseas?  " + msg
			for e in ["Comprar", "Vender", "Salir"]:
				_entries.append(e)
				_add_row(e)
			_hint.text = "Confirmar: elegir   Cancelar: salir"
		"buy":
			_info.text = "Comprar · cantidad: x%d  (Izq/Der cambia la cantidad)  " % _qty + msg
			for id in shop.get("items", []):
				var it: Dictionary = DB.items.get(id, {})
				if it.is_empty():
					continue
				_entries.append(id)
				_add_row("%s   %d Gald   (tienes %d)   %s" % [it["name"], int(it.get("price", 0)) * _qty, Game.item_count(id), it.get("desc", _stats_desc(it))])
			_hint.text = "Confirmar: comprar   Izq/Der: cantidad   Cancelar: volver"
		"sell":
			_info.text = "Vender (a mitad de precio) · cantidad: x%d  " % _qty + msg
			var ids: Array = Game.inventory.keys()
			ids.sort()
			for id in ids:
				var it: Dictionary = DB.items.get(id, {})
				if it.get("type", "") == "key" or int(it.get("price", 0)) <= 0:
					continue
				_entries.append(id)
				_add_row("%s  x%d   %d Gald c/u" % [it["name"], Game.item_count(id), Game.sell_price(id)])
			if _entries.is_empty():
				_add_row("(nada que vender)")
			_hint.text = "Confirmar: vender   Izq/Der: cantidad   Cancelar: volver"
	for i in _labels.size():
		var sel := (i == _cursor)
		_labels[i].modulate = Color(1, 0.9, 0.5) if sel else Color(0.85, 0.85, 0.9)
		_labels[i].text = ("▶ " if sel else "   ") + _labels[i].text.trim_prefix("▶ ").strip_edges()

func _stats_desc(it: Dictionary) -> String:
	var parts := []
	for k in it.get("stats", {}):
		parts.append("%s +%d" % [k.to_upper(), int(it["stats"][k])])
	if it.has("users"):
		parts.append("para " + ", ".join((it["users"] as Array).map(func(u): return str(DB.characters.get(u, {}).get("name", u)).split(" ")[0])))
	return ", ".join(parts)

func _add_row(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 24)
	_list.add_child(l)
	_labels.append(l)

func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	var n := _entries.size()
	if event.is_action_pressed("move_down") and n > 0:
		_cursor = (_cursor + 1) % n
	elif event.is_action_pressed("move_up") and n > 0:
		_cursor = (_cursor - 1 + n) % n
	elif event.is_action_pressed("move_right") and _mode != "top":
		_qty = min(99, _qty + 1)
	elif event.is_action_pressed("move_left") and _mode != "top":
		_qty = max(1, _qty - 1)
	elif event.is_action_pressed("confirm"):
		_confirm()
	elif event.is_action_pressed("cancel") or event.is_action_pressed("menu"):
		_msg = ""
		if _mode == "top":
			_closed = true
		else:
			_mode = "top"
			_cursor = 0
			_qty = 1
	else:
		return
	get_viewport().set_input_as_handled()
	_render()

func _confirm() -> void:
	_msg = ""
	match _mode:
		"top":
			match _cursor:
				0: _mode = "buy"
				1: _mode = "sell"
				2:
					_closed = true
					return
			_cursor = 0
			_qty = 1
		"buy":
			if _entries.is_empty():
				return
			var id: String = _entries[_cursor]
			if Game.buy(id, _qty):
				_msg = "Has comprado %s x%d." % [DB.items[id]["name"], _qty]
			else:
				_msg = "No tienes suficiente Gald."
		"sell":
			if _entries.is_empty():
				return
			var id: String = _entries[_cursor]
			var q: int = min(_qty, Game.item_count(id))
			if Game.sell(id, q):
				_msg = "Has vendido %s x%d." % [DB.items[id]["name"], q]
				if not Game.has_item(id):
					_cursor = max(0, _cursor - 1)
