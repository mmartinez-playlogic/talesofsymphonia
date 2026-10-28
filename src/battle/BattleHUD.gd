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
	_party_box.add_child(panel)
	_panels[b] = {"hp": hp_bar, "tp": tp_bar, "hp_l": hp_l, "tp_l": tp_l, "name": name_l, "panel": panel}

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
