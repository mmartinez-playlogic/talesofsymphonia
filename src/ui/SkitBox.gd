class_name SkitBox
extends CanvasLayer
## Tales skit presentation: dimmed screen, title, speaker tags that light up, text, confirm to advance.

const COLORS := {
	"Lloyd": Color(0.85, 0.2, 0.2), "Colette": Color(0.95, 0.85, 0.5), "Genis": Color(0.3, 0.5, 0.9),
	"Raine": Color(0.9, 0.55, 0.2), "Kratos": Color(0.45, 0.25, 0.6), "Sheena": Color(0.6, 0.3, 0.7),
	"Zelos": Color(0.95, 0.5, 0.7), "Presea": Color(0.95, 0.6, 0.75), "Regal": Color(0.3, 0.35, 0.6),
}
var _root: Control
var _title: Label
var _text: RichTextLabel
var _tags: HBoxContainer
var _tag_nodes: Dictionary = {}
var _active := false
var _advance := false

func _ready() -> void:
	layer = 60
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.visible = false
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	_title = Label.new()
	_title.position = Vector2(120, 80)
	_title.size = Vector2(1680, 60)
	_title.add_theme_font_size_override("font_size", 40)
	_title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5))
	_root.add_child(_title)
	_tags = HBoxContainer.new()
	_tags.position = Vector2(160, 300)
	_tags.size = Vector2(1600, 300)
	_tags.add_theme_constant_override("separation", 40)
	_tags.alignment = BoxContainer.ALIGNMENT_CENTER
	_root.add_child(_tags)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.05, 0.12, 0.9)
	style.border_color = Color(0.85, 0.75, 0.45)
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", style)
	panel.position = Vector2(160, 700)
	panel.size = Vector2(1600, 220)
	_root.add_child(panel)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.add_theme_font_size_override("normal_font_size", 32)
	panel.add_child(_text)

func play(skit_id: String) -> void:
	var s: Dictionary = DB.skits.get(skit_id, {})
	if s.is_empty():
		return
	_title.text = str(s.get("title", ""))
	for c in _tags.get_children():
		c.queue_free()
	_tag_nodes.clear()
	var speakers: Array = []
	for l in s.get("lines", []):
		if not speakers.has(l["speaker"]):
			speakers.append(l["speaker"])
	for sp in speakers:
		var p := PanelContainer.new()
		var st := StyleBoxFlat.new()
		st.bg_color = COLORS.get(sp, Color(0.4, 0.4, 0.45))
		st.set_corner_radius_all(16)
		st.set_content_margin_all(26)
		p.add_theme_stylebox_override("panel", st)
		p.custom_minimum_size = Vector2(260, 260)
		var l := Label.new()
		l.text = sp
		l.add_theme_font_size_override("font_size", 40)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.set_anchors_preset(Control.PRESET_FULL_RECT)
		p.add_child(l)
		_tags.add_child(p)
		_tag_nodes[sp] = p
	_root.visible = true
	_active = true
	for l in s.get("lines", []):
		for sp in _tag_nodes:
			_tag_nodes[sp].modulate = Color(1, 1, 1) if sp == l["speaker"] else Color(0.45, 0.45, 0.5)
			_tag_nodes[sp].scale = Vector2.ONE
		var mood: String = str(l.get("mood", ""))
		var tag: Control = _tag_nodes[l["speaker"]]
		if mood == "shout" or mood == "angry":
			var t := create_tween()
			t.tween_property(tag, "position:x", tag.position.x + 10, 0.05)
			t.tween_property(tag, "position:x", tag.position.x - 10, 0.05)
			t.tween_property(tag, "position:x", tag.position.x, 0.05)
		elif mood == "happy":
			var t := create_tween()
			t.tween_property(tag, "position:y", tag.position.y - 16, 0.12)
			t.tween_property(tag, "position:y", tag.position.y, 0.12)
		_text.text = "[color=#f0d070]%s[/color]: %s" % [l["speaker"], l["text"]]
		_text.visible_ratio = 0.0
		var total := _text.get_total_character_count()
		var t2 := 0.0
		_advance = false
		while _text.visible_ratio < 1.0:
			if not is_inside_tree():
				return
			await get_tree().process_frame
			if not is_inside_tree():
				return
			if _advance:
				_text.visible_ratio = 1.0
				break
			t2 += get_process_delta_time()
			_text.visible_ratio = min(1.0, t2 * 60.0 / max(1, total))
		_advance = false
		while not _advance:
			if not is_inside_tree():
				return
			await get_tree().process_frame
	_active = false
	_root.visible = false
	if not Game.seen_skits.has(skit_id):
		Game.seen_skits.append(skit_id)

func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed("confirm") or event.is_action_pressed("cancel") or event.is_action_pressed("skit"):
		get_viewport().set_input_as_handled()
		_advance = true
