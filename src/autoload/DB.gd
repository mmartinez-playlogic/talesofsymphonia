extends Node
## Static game data loaded from JSON in res://src/data/.
## Access with DB.characters["lloyd"], DB.artes["demon_fang"], DB.enemies["wolf"], DB.items["apple_gel"].

var characters: Dictionary = {}
var artes: Dictionary = {}
var enemies: Dictionary = {}
var items: Dictionary = {}
var encounters: Dictionary = {}
var skits: Dictionary = {}

func _ready() -> void:
	characters = _load("characters")
	artes = _load("artes")
	enemies = _load("enemies")
	items = _load("items")
	encounters = _load("encounters")
	skits = _load("skits")
	print("[DB] loaded %d characters, %d artes, %d enemies, %d items" % [characters.size(), artes.size(), enemies.size(), items.size()])

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
