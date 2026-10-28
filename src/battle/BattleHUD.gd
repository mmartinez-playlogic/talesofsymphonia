class_name BattleHUD
extends CanvasLayer
## Party status panels, target info, combo counter, arte callouts, results and game over.

var manager: Node
var _party_box: HBoxContainer
var _panels: Dictionary = {}       # battler -> {hp: ProgressBar, tp: ProgressBar, hp_l, tp_l, name}
var _target_name: Label
var _target_hp: ProgressBar
var _combo: Label
var _combo_hits := 0
var _combo_dmg := 0
var _combo_timer := 0.0
var _arte_label: Label
var _arte_timer := 0.0
var _results: PanelContainer
var _results_text: RichTextLabel
var _center: Label
var _unison_bar: ProgressBar
var _unison_label: Label
var _menu_panel: PanelContainer
var _menu_list: VBoxContainer
var _menu_title: Label
var _menu_labels: Array[Label] = []
var _menu_entries: Array = []
var _menu_cursor := 0
var _menu_mode := ""
var _menu_item := ""
var _menu_done := false

func _ready() -> void:
	layer = 20
	_party_box = HBoxContainer.new()
	_party_box.position = Vector2(60, 1080 - 150)
	_party_box.size = Vector2(1800, 120)
	_party_box.add_theme_constant_override("separation", 20)
	add_child(_party_box)
	_target_name = Label.new()
	_target_name.position = Vector2(60, 40)
	_target_name.add_theme_font_size_override("font_size", 30)
	add_child(_target_name)
	_target_hp = _bar(Color(0.9, 0.25, 0.2))
	_target_hp.position = Vector2(60, 84)
	_target_hp.size = Vector2(360, 16)
	add_child(_target_hp)
	_combo = Label.new()
	_combo.position = Vector2(1920 - 460, 60)
	_combo.size = Vector2(400, 120)
	_combo.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_combo.add_theme_font_size_override("font_size", 40)
	_combo.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	add_child(_combo)
	_arte_label = Label.new()
	_arte_label.position = Vector2(560, 140)
	_arte_label.size = Vector2(800, 60)
	_arte_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_arte_label.add_theme_font_size_override("font_size", 44)
	_arte_label.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	_arte_label.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.3))
	_arte_label.add_theme_constant_override("outline_size", 8)
	add_child(_arte_label)
	_center = Label.new()
	_center.position = Vector2(360, 380)
	_center.size = Vector2(1200, 160)
	_center.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_center.add_theme_font_size_override("font_size", 90)
	_center.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	_center.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0.0))
	_center.add_theme_constant_override("outline_size", 12)
	_center.visible = false
	add_child(_center)
	_unison_bar = _bar(Color(0.3, 0.6, 1.0))
	_unison_bar.position = Vector2(1920 - 420, 1080 - 190)
	_unison_bar.size = Vector2(360, 14)
	_unison_bar.value = 0.0
	add_child(_unison_bar)
	_unison_label = Label.new()
	_unison_label.text = "UNISON [N]"
	_unison_label.position = Vector2(1920 - 420, 1080 - 222)
	_unison_label.add_theme_font_size_override("font_size", 20)
	_unison_label.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	add_child(_unison_label)
	_menu_panel = PanelContainer.new()
	var mstyle := StyleBoxFlat.new()
	mstyle.bg_color = Color(0.03, 0.05, 0.14, 0.94)
	mstyle.border_color = Color(0.85, 0.75, 0.45)
	mstyle.set_border_width_all(3)
	mstyle.set_corner_radius_all(12)
	mstyle.set_content_margin_all(24)
	_menu_panel.add_theme_stylebox_override("panel", mstyle)
	_menu_panel.position = Vector2(560, 220)
	_menu_panel.size = Vector2(800, 520)
	_menu_panel.visible = false
	add_child(_menu_panel)
	var mvb := VBoxContainer.new()
	_menu_panel.add_child(mvb)
	_menu_title = Label.new()
	_menu_title.add_theme_font_size_override("font_size", 32)
	_menu_title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5))
	mvb.add_child(_menu_title)
	_menu_list = VBoxContainer.new()
	mvb.add_child(_menu_list)
	_results = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.05, 0.14, 0.92)
	style.border_color = Color(0.85, 0.75, 0.45)
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(30)
	_results.add_theme_stylebox_override("panel", style)
	_results.position = Vector2(460, 180)
	_results.size = Vector2(1000, 620)
	_results.visible = false
	add_child(_results)
	_results_text = RichTextLabel.new()
	_results_text.bbcode_enabled = true
	_results_text.add_theme_font_size_override("normal_font_size", 30)
	_results_text.add_theme_font_size_override("bold_font_size", 34)
	_results.add_child(_results_text)

func _bar(color: Color) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.1, 0.15, 0.8)
	bg.set_corner_radius_all(4)
	var fg := StyleBoxFlat.new()
	fg.bg_color = color
	fg.set_corner_radius_all(4)
	b.add_theme_stylebox_override("background", bg)
	b.add_theme_stylebox_override("fill", fg)
	b.max_value = 1.0
	b.value = 1.0
	return b

func add_party_member(b: PlayerBattler) -> void:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.05, 0.14, 0.78)
	style.border_color = Color(0.7, 0.6, 0.35)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(400, 110)
	var vb := VBoxContainer.new()
	panel.add_child(vb)
	var name_l := Label.new()
	name_l.text = b.display_name
	name_l.add_theme_font_size_override("font_size", 26)
	vb.add_child(name_l)
	var hp_row := HBoxContainer.new()
	var hp_l := Label.new()
	hp_l.custom_minimum_size.x = 150
	hp_l.add_theme_font_size_override("font_size", 22)
	var hp_bar := _bar(Color(0.3, 0.85, 0.35))
	hp_bar.custom_minimum_size = Vector2(220, 14)
	hp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hp_row.add_child(hp_l)
	hp_row.add_child(hp_bar)
	vb.add_child(hp_row)
	var tp_row := HBoxContainer.new()
	var tp_l := Label.new()
	tp_l.custom_minimum_size.x = 150
	tp_l.add_theme_font_size_override("font_size", 22)
	var tp_bar := _bar(Color(0.35, 0.55, 0.95))
	tp_bar.custom_minimum_size = Vector2(220, 14)
	tp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tp_row.add_child(tp_l)
	tp_row.add_child(tp_bar)
	vb.add_child(tp_row)
	var ol_bar := _bar(Color(0.95, 0.55, 0.15))
	ol_bar.custom_minimum_size = Vector2(376, 6)
	ol_bar.value = 0.0
	vb.add_child(ol_bar)
	_party_box.add_child(panel)
	_panels[b] = {"hp": hp_bar, "tp": tp_bar, "hp_l": hp_l, "tp_l": tp_l, "name": name_l, "panel": panel, "ol": ol_bar}

func combo_hits() -> int:
	return _combo_hits

# ---------- battle item menu ----------
func item_menu(bm: BattleManager) -> void:
	_menu_mode = "items"
	_menu_cursor = 0
	_menu_done = false
	_menu_panel.visible = true
	_render_menu(bm)
	while not _menu_done:
		await get_tree().process_frame
	_menu_panel.visible = false
	_menu_mode = ""

func _render_menu(bm: BattleManager) -> void:
	for ch in _menu_list.get_children():
		ch.queue_free()
	_menu_labels.clear()
	_menu_entries.clear()
	if _menu_mode == "items":
		_menu_title.text = "Objetos  (Cancelar: volver al combate)"
		var ids: Array = Game.inventory.keys()
		ids.sort()
		for id in ids:
			var it: Dictionary = DB.items.get(id, {})
			if it.get("type", "") != "consumable":
				continue
			_menu_entries.append(id)
			_add_menu_row("%s  x%d   %s" % [it["name"], Game.inventory[id], it.get("desc", "")])
		if _menu_entries.is_empty():
			_add_menu_row("(sin objetos)")
	else:
		_menu_title.text = "Usar %s en..." % DB.items[_menu_item]["name"]
		for b in bm.party:
			_menu_entries.append(b)
			_add_menu_row("%s   HP %d/%d   TP %d/%d%s" % [b.display_name, b.stats["hp"], b.stats["max_hp"], b.stats["tp"], b.stats["max_tp"], "   (KO)" if not b.is_alive() else ""])
	for i in _menu_labels.size():
		var sel := i == _menu_cursor and not _menu_entries.is_empty()
		_menu_labels[i].modulate = Color(1, 0.9, 0.5) if sel else Color(0.85, 0.85, 0.9)
		_menu_labels[i].text = ("▶ " if sel else "   ") + _menu_labels[i].text.trim_prefix("▶ ").strip_edges()

func _add_menu_row(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 26)
	_menu_list.add_child(l)
	_menu_labels.append(l)

func _unhandled_input(event: InputEvent) -> void:
	if _menu_mode == "":
		return
	var bm := manager as BattleManager
	var n := _menu_entries.size()
	if event.is_action_pressed("move_down") and n > 0:
		_menu_cursor = (_menu_cursor + 1) % n
	elif event.is_action_pressed("move_up") and n > 0:
		_menu_cursor = (_menu_cursor - 1 + n) % n
	elif event.is_action_pressed("confirm") and n > 0:
		if _menu_mode == "items":
			_menu_item = _menu_entries[_menu_cursor]
			_menu_mode = "target"
			_menu_cursor = 0
		else:
			var b: PlayerBattler = _menu_entries[_menu_cursor]
			if _apply_item(_menu_item, b):
				_menu_done = true
	elif event.is_action_pressed("cancel") or event.is_action_pressed("menu"):
		if _menu_mode == "target":
			_menu_mode = "items"
			_menu_cursor = 0
		else:
			_menu_done = true
	else:
		return
	get_viewport().set_input_as_handled()
	if not _menu_done:
		_render_menu(bm)

func _apply_item(item_id: String, b: PlayerBattler) -> bool:
	var fx: Dictionary = DB.items.get(item_id, {}).get("effect", {})
	var boost := 1.0 + float(b.ex.get("item", 0.0))
	if fx.has("revive"):
		if b.is_alive():
			return false
		b.revive(float(fx["revive"]))
	else:
		if not b.is_alive():
			return false
		if fx.has("hp_pct"):
			b.heal(int(b.stats["max_hp"] * float(fx["hp_pct"]) * boost))
		if fx.has("tp_pct"):
			b.stats["tp"] = min(int(b.stats["max_tp"]), int(b.stats["tp"]) + int(b.stats["max_tp"] * float(fx["tp_pct"]) * boost))
		if fx.has("cure"):
			b.status = ""
	Game.add_item(item_id, -1)
	announce_arte(DB.items[item_id]["name"])
	return true

func _process(delta: float) -> void:
	for b in _panels:
		if not is_instance_valid(b):
			continue
		var p: Dictionary = _panels[b]
		p["hp"].value = b.hp_ratio()
		p["tp"].value = float(b.stats["tp"]) / max(1.0, float(b.stats["max_tp"]))
		p["hp_l"].text = "HP %d/%d" % [b.stats["hp"], b.stats["max_hp"]]
		p["tp_l"].text = "TP %d/%d" % [b.stats["tp"], b.stats["max_tp"]]
		p["name"].modulate = Color(1, 0.9, 0.5) if b == manager.controlled else Color(1, 1, 1)
		p["panel"].modulate.a = 0.5 if not b.is_alive() else 1.0
		p["ol"].value = 1.0 if b.over_limit_t > 0 else b.ol_gauge / 100.0
		p["ol"].modulate = Color(1, 0.5, 0.2) if b.over_limit_t > 0 else Color(1, 1, 1)
	_unison_bar.value = manager.unison_gauge / 100.0
	_unison_label.modulate = Color(1, 0.9, 0.4) if manager.unison_gauge >= 100.0 else Color(0.7, 0.85, 1.0)
	var c = manager.controlled
	if c and c.target and is_instance_valid(c.target):
		_target_name.text = c.target.display_name
		_target_hp.value = c.target.hp_ratio()
		_target_hp.visible = true
	else:
		_target_name.text = ""
		_target_hp.visible = false
	if _combo_timer > 0:
		_combo_timer -= delta
		if _combo_timer <= 0:
			_combo.text = ""
			_combo_hits = 0
			_combo_dmg = 0
	if _arte_timer > 0:
		_arte_timer -= delta
		_arte_label.modulate.a = clamp(_arte_timer * 2.0, 0, 1)

func register_hit(dmg: int) -> void:
	_combo_hits += 1
	_combo_dmg += dmg
	_combo_timer = 1.5
	_combo.text = "%d HIT%s\n%d" % [_combo_hits, "S" if _combo_hits > 1 else "", _combo_dmg]

func announce_arte(name: String) -> void:
	_arte_label.text = name
	_arte_timer = 1.2
	_arte_label.modulate.a = 1.0

func show_center(text: String, seconds := 1.2) -> void:
	_center.text = text
	_center.visible = true
	_center.modulate.a = 1.0
	var t := create_tween()
	t.tween_interval(seconds)
	t.tween_property(_center, "modulate:a", 0.0, 0.4)
	t.tween_callback(func(): _center.visible = false)

func show_results(bbcode: String) -> void:
	_results_text.text = bbcode
	_results.visible = true
