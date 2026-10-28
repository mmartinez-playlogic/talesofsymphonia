extends Node
## Static game data loaded from JSON in res://src/data/.
## Access with DB.characters["lloyd"], DB.artes["demon_fang"], DB.enemies["wolf"], DB.items["apple_gel"].

var characters: Dictionary = {}
var artes: Dictionary = {}
var enemies: Dictionary = {}
var items: Dictionary = {}
var encounters: Dictionary = {}
var skits: Dictionary = {}
var script: Dictionary = {}   # scene id -> Array of {speaker, text}; merged from src/data/script/*.json

func _ready() -> void:
	characters = _load("characters")
	artes = _load("artes")
	enemies = _load("enemies")
	items = _load("items")
	encounters = _load("encounters")
	skits = _load("skits")
	_load_script()
	print("[DB] loaded %d characters, %d artes, %d enemies, %d items" % [characters.size(), artes.size(), enemies.size(), items.size()])

func _load_script() -> void:
	script.clear()
	var dir := DirAccess.open("res://src/data/script")
	if dir == null:
		return
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if f.ends_with(".json") and not f.begins_with("_"):
			var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://src/data/script/" + f))
			if parsed is Dictionary:
				script.merge(parsed, true)
		f = dir.get_next()
	print("[DB] script lines loaded for %d scenes" % script.size())

func script_lines(id: String) -> Array:
	var v = script.get(id, [])
	return v if v is Array else []

func _load(name: String) -> Dictionary:
	var path := "res://src/data/%s.json" % name
	if not FileAccess.file_exists(path):
		push_warning("[DB] missing data file: " + path)
		return {}
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if parsed == null or not (parsed is Dictionary):
		push_error("[DB] failed to parse " + path)
		return {}
	return parsed

## Stat at a given level using the character's base and growth tables.
func stat_at(char_id: String, stat: String, level: int) -> int:
	var c: Dictionary = characters.get(char_id, {})
	var base: float = c.get("base", {}).get(stat, 10)
	var growth: float = c.get("growth", {}).get(stat, 1.0)
	return int(round(base + growth * (level - 1)))

## EXP required to reach the given level (cumulative), Symphonia-like curve.
func exp_for_level(level: int) -> int:
	if level <= 1:
		return 0
	return int(round(8.0 * pow(level - 1, 2.4) + 12.0 * (level - 1)))
