class_name DialogueBox
extends CanvasLayer
## Tales-style dialogue window: name tag, typewriter text, portrait-less for now.
## Usage: await DialogueBox.show_lines([{"speaker":"Lloyd","text":"..."}, ...])

signal finished
signal line_shown(index: int)

var _panel: PanelContainer
var _name: Label
var _text: RichTextLabel
var _cursor: Label
var _lines: Array = []
var _index := 0
var _typing := false
var _active := false
var _skip_requested := false
const CHARS_PER_SEC := 60.0

func _ready() -> void:
	layer = 50
	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.05, 0.12, 0.88)
	style.border_color = Color(0.85, 0.75, 0.45)
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	_panel.add_theme_stylebox_override("panel", style)
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

func show_lines(lines: Array) -> void:
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
		await get_tree().process_frame
		if _skip_requested:
			_text.visible_ratio = 1.0
			break
		t += get_process_delta_time()
		_text.visible_ratio = min(1.0, (t * CHARS_PER_SEC) / max(1, total))
	_typing = false
	_cursor.visible = true

func _process(_delta: float) -> void:
	if _cursor.visible:
		_cursor.modulate.a = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 150.0)

func _unhandled_input(event: InputEvent) -> void:
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
	return _active
