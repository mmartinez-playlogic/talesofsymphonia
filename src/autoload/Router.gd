extends CanvasLayer
## Scene transitions with fade, battle entry/exit.

signal transition_finished

var _fade: ColorRect
var _busy := false
var _pending_battle: Dictionary = {}

func _ready() -> void:
	layer = 100
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)

func fade_out(duration := 0.35) -> void:
	var t := create_tween()
	t.tween_property(_fade, "color:a", 1.0, duration)
	await t.finished

func fade_in(duration := 0.35) -> void:
	var t := create_tween()
	t.tween_property(_fade, "color:a", 0.0, duration)
	await t.finished

func flash(color := Color(1, 1, 1), duration := 0.5) -> void:
	_fade.color = Color(color.r, color.g, color.b, 1.0)
	var t := create_tween()
	t.tween_property(_fade, "color:a", 0.0, duration)
	await t.finished
	_fade.color = Color(0, 0, 0, 0)

func goto_scene(path: String) -> void:
	if _busy:
		return
	_busy = true
	await fade_out()
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await fade_in()
	_busy = false
	transition_finished.emit()

## Load a field map by id (res://src/field/maps/<id>.tscn).
func goto_map(map_id: String, spawn := "default") -> void:
	Game.current_map = map_id
	Game.spawn_point = spawn
	Game.return_to_field = false
	await goto_scene("res://src/field/maps/%s.tscn" % map_id)

## Enter battle. encounter: {"enemies": ["wolf","wolf"], "advantage": "normal"|"player"|"enemy"}
func start_battle(encounter: Dictionary) -> void:
	if _busy:
		return
	_pending_battle = encounter
	_busy = true
	Audio.sfx("encounter")
	await _battle_swirl()
	get_tree().change_scene_to_file("res://src/battle/Battle.tscn")
	await get_tree().process_frame
	await fade_in(0.2)
	_busy = false

func consume_pending_battle() -> Dictionary:
	var e := _pending_battle
	_pending_battle = {}
	return e

func return_from_battle() -> void:
	Game.return_to_field = true
	await goto_scene("res://src/field/maps/%s.tscn" % Game.current_map)

## Fade to black and then back in on the same scene (used for time skips inside an event).
func blink(hold := 0.6) -> void:
	await fade_out(0.4)
	await get_tree().create_timer(hold).timeout
	await fade_in(0.4)

func _battle_swirl() -> void:
	# Quick flash + fade, Tales style.
	var t := create_tween()
	_fade.color = Color(1, 1, 1, 0)
	t.tween_property(_fade, "color:a", 1.0, 0.08)
	t.tween_property(_fade, "color", Color(0, 0, 0, 1), 0.25)
	await t.finished

## Debug: `godot --path . <scene> -- --shot out.png [--frames 40]` saves a screenshot then quits.
var _shot_path := ""
var _shot_frames := 40
var _frame_count := 0

func _enter_tree() -> void:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--shot" and i + 1 < args.size():
			_shot_path = args[i + 1]
		if args[i] == "--frames" and i + 1 < args.size():
			_shot_frames = int(args[i + 1])

func _process(_delta: float) -> void:
	if _shot_path == "":
		return
	_frame_count += 1
	if _frame_count == _shot_frames:
		var img := get_viewport().get_texture().get_image()
		img.save_png(_shot_path)
		print("SHOT saved ", _shot_path)
		get_tree().quit()
