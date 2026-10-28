class_name DialogueBox
extends CanvasLayer
## Tales-style dialogue window: name tag, typewriter text, choices and captions.
## Usage: await dialogue.show_lines([{"speaker":"Lloyd","text":"..."}, ...])
##        var i: int = await dialogue.show_choice("¿Qué hacemos?", ["Ir", "Esperar"])
##        await dialogue.show_caption("Al día siguiente...", 2.0)

signal finished
signal line_shown(index: int)
signal choice_made(index: int)

var _panel: PanelContainer
var _name: Label
var _text: RichTextLabel
var _cursor: Label
var _lines: Array = []
var _index := 0
var _typing := false
var _active := false
var _skip_requested := false
var _choice_panel: PanelContainer
var _choice_box: VBoxContainer
var _choice_labels: Array[Label] = []
var _choice_cursor := 0
var _choice_active := false
var _caption: Label
const CHARS_PER_SEC := 60.0

func _ready() -> void:
	layer = 50
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", _style(Color(0.03, 0.05, 0.12, 0.88)))
	_panel.position = Vector2(160, 1080 - 290)
	_panel.size = Vector2(1600, 220)
	add_child(_panel)
	var vb := VBoxContainer.new()
	_panel.add_child(vb)
	_name = Label.new()
	_name.add_theme_font_size_override("font_size", 30)
	_name.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5))
	vb.add_child(_name)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.add_theme_font_size_override("normal_font_size", 32)
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.scroll_active = false
	vb.add_child(_text)
	_cursor = Label.new()
	_cursor.text = "▼"
	_cursor.add_theme_font_size_override("font_size", 26)
	_cursor.position = Vector2(1600 - 60, 220 - 44)
	_panel.add_child(_cursor)
	_panel.visible = false
	# choices
	_choice_panel = PanelContainer.new()
	_choice_panel.add_theme_stylebox_override("panel", _style(Color(0.05, 0.07, 0.16, 0.94)))
	_choice_panel.position = Vector2(1180, 1080 - 290 - 40)
	_choice_panel.size = Vector2(580, 60)
	_choice_panel.visible = false
	add_child(_choice_panel)
	_choice_box = VBoxContainer.new()
	_choice_panel.add_child(_choice_box)
	# caption
	_caption = Label.new()
	_caption.position = Vector2(260, 120)
	_caption.size = Vector2(1400, 80)
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.add_theme_font_size_override("font_size", 38)
	_caption.add_theme_color_override("font_color", Color(0.98, 0.95, 0.85))
	_caption.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_caption.add_theme_constant_override("outline_size", 10)
	_caption.visible = false
	add_child(_caption)

func _style(bg: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = Color(0.85, 0.75, 0.45)
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	return style

func show_lines(lines: Array) -> void:
	if lines.is_empty():
		return
	_lines = lines
	_index = 0
	_active = true
	_panel.visible = true
	await _show_current()
	await finished

func _show_current() -> void:
	var line: Dictionary = _lines[_index]
	_name.text = str(line.get("speaker", ""))
	_name.visible = _name.text != ""
	_text.text = str(line.get("text", ""))
	_text.visible_ratio = 0.0
	_cursor.visible = false
	_typing = true
	_skip_requested = false
	line_shown.emit(_index)
	var total := _text.get_total_character_count()
	var t := 0.0
	while _text.visible_ratio < 1.0:
		if not is_inside_tree():
			return
		await get_tree().process_frame
		if not is_inside_tree():
			return
		if _skip_requested:
			_text.visible_ratio = 1.0
			break
		t += get_process_delta_time()
		_text.visible_ratio = min(1.0, (t * CHARS_PER_SEC) / max(1, total))
	_typing = false
	_cursor.visible = true

## Show a prompt in the dialogue box and a list of options; returns the chosen index.
func show_choice(prompt: String, options: Array) -> int:
	_panel.visible = true
	_name.visible = false
	_text.text = prompt
	_text.visible_ratio = 1.0
	_cursor.visible = false
	for c in _choice_box.get_children():
		c.queue_free()
	_choice_labels.clear()
	for o in options:
		var l := Label.new()
		l.text = str(o)
		l.add_theme_font_size_override("font_size", 30)
		_choice_box.add_child(l)
		_choice_labels.append(l)
	_choice_panel.size = Vector2(580, 40 + options.size() * 44)
	_choice_panel.position = Vector2(1180, 1080 - 290 - _choice_panel.size.y - 10)
	_choice_cursor = 0
	_choice_active = true
	_refresh_choice()
	_choice_panel.visible = true
	var idx: int = await choice_made
	_choice_active = false
	_choice_panel.visible = false
	_panel.visible = false
	return idx

func _refresh_choice() -> void:
	for i in _choice_labels.size():
		var l := _choice_labels[i]
		l.modulate = Color(1, 0.9, 0.5) if i == _choice_cursor else Color(0.8, 0.8, 0.85)
		l.text = ("▶ " if i == _choice_cursor else "   ") + l.text.trim_prefix("▶ ").strip_edges()

## Centered caption (location names, "got item" notices). Non-modal.
func show_caption(text: String, seconds := 2.0) -> void:
	_caption.text = text
	_caption.visible = true
	_caption.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(_caption, "modulate:a", 1.0, 0.25)
	t.tween_interval(seconds)
	t.tween_property(_caption, "modulate:a", 0.0, 0.35)
	await t.finished
	_caption.visible = false

func _process(_delta: float) -> void:
	if _cursor.visible:
		_cursor.modulate.a = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 150.0)

func _unhandled_input(event: InputEvent) -> void:
	if _choice_active:
		if event.is_action_pressed("move_down"):
			_choice_cursor = (_choice_cursor + 1) % _choice_labels.size()
			_refresh_choice()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("move_up"):
			_choice_cursor = (_choice_cursor - 1 + _choice_labels.size()) % _choice_labels.size()
			_refresh_choice()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("confirm"):
			get_viewport().set_input_as_handled()
			choice_made.emit(_choice_cursor)
		return
	if not _active:
		return
	if event.is_action_pressed("confirm") or event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		if _typing:
			_skip_requested = true
			return
		_index += 1
		if _index >= _lines.size():
			_active = false
			_panel.visible = false
			finished.emit()
		else:
			_show_current()

func is_active() -> bool:
	return _active or _choice_active
