extends Node
## Mutable game state: party, inventory, story flags, affection, gald. Save/load.

signal party_changed
signal flag_changed(flag: String, value)

const SAVE_PATH := "user://save_%d.json"

## Ordered list of character ids in the active party (max 4 fighting).
var party: Array[String] = []
## All recruited members (ids) and their runtime state keyed by id.
var members: Dictionary = {}
var inventory: Dictionary = {}  # item_id -> count
var gald: int = 0
var grade: float = 0.0
var flags: Dictionary = {}
var affection: Dictionary = {}  # char_id -> int
var play_time: float = 0.0
var current_map: String = "iselia_forest"
var spawn_point: String = "default"
var last_field_position: Vector3 = Vector3.ZERO
var return_to_field: bool = false

func _process(delta: float) -> void:
	play_time += delta

func new_game() -> void:
	party.clear()
	members.clear()
	inventory.clear()
	flags.clear()
	affection.clear()
	gald = 0
	grade = 0.0
	play_time = 0.0
	current_map = "iselia_forest"
	spawn_point = "default"
	# Prologue party of Symphonia.
	add_member("lloyd")
	add_member("genis")
	add_member("colette")
	add_item("apple_gel", 3)
	add_item("orange_gel", 1)
	gald = 500

func add_member(id: String, level: int = 1) -> void:
	if members.has(id):
		return
	var data: Dictionary = DB.characters.get(id, {})
	if data.is_empty():
		push_error("Unknown character " + id)
		return
	var lvl: int = level if level > 1 else int(data.get("start_level", 1))
	var state := {
		"id": id,
		"level": lvl,
		"exp": DB.exp_for_level(lvl),
		"hp": DB.stat_at(id, "hp", lvl),
		"tp": DB.stat_at(id, "tp", lvl),
		"artes": _artes_known(id, lvl),
		"equipment": data.get("start_equipment", {}).duplicate(),
		"title": data.get("start_title", ""),
		"strategy": "normal",
	}
	members[id] = state
	if party.size() < 4:
		party.append(id)
	party_changed.emit()

func remove_from_party(id: String) -> void:
	party.erase(id)
	party_changed.emit()

func _artes_known(id: String, level: int) -> Array:
	var known: Array = []
	for arte_id in DB.artes:
		var a: Dictionary = DB.artes[arte_id]
		if a.get("user", "") == id and int(a.get("level", 999)) <= level:
			known.append(arte_id)
	return known

func max_hp(id: String) -> int:
	return DB.stat_at(id, "hp", members[id]["level"])

func max_tp(id: String) -> int:
	return DB.stat_at(id, "tp", members[id]["level"])

func stat(id: String, name: String) -> int:
	var m: Dictionary = members[id]
	var v := DB.stat_at(id, name, m["level"])
	for slot in m["equipment"]:
		var item: Dictionary = DB.items.get(m["equipment"][slot], {})
		v += int(item.get("stats", {}).get(name, 0))
	return v

func grant_exp(id: String, amount: int) -> Array:
	## Returns list of levels gained.
	var m: Dictionary = members[id]
	m["exp"] += amount
	var gained: Array = []
	while m["exp"] >= DB.exp_for_level(m["level"] + 1) and m["level"] < 250:
		m["level"] += 1
		gained.append(m["level"])
		for arte_id in DB.artes:
			var a: Dictionary = DB.artes[arte_id]
			if a.get("user", "") == id and int(a.get("level", 999)) == m["level"] and not m["artes"].has(arte_id):
				m["artes"].append(arte_id)
	return gained

func add_item(id: String, count: int = 1) -> void:
	inventory[id] = int(inventory.get(id, 0)) + count
	if inventory[id] <= 0:
		inventory.erase(id)

func has_item(id: String) -> bool:
	return int(inventory.get(id, 0)) > 0

func set_flag(flag: String, value = true) -> void:
	flags[flag] = value
	flag_changed.emit(flag, value)

func get_flag(flag: String, default = false):
	return flags.get(flag, default)

func heal_all() -> void:
	for id in members:
		members[id]["hp"] = max_hp(id)
		members[id]["tp"] = max_tp(id)

func save(slot: int = 0) -> void:
	var data := {
		"party": party, "members": members, "inventory": inventory, "gald": gald, "grade": grade,
		"flags": flags, "affection": affection, "play_time": play_time, "current_map": current_map,
		"spawn_point": spawn_point,
	}
	var f := FileAccess.open(SAVE_PATH % slot, FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "\t"))

func load_save(slot: int = 0) -> bool:
	var path := SAVE_PATH % slot
	if not FileAccess.file_exists(path):
		return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if data == null:
		return false
	party.assign(data["party"])
	members = data["members"]
	inventory = data["inventory"]
	gald = int(data["gald"])
	grade = float(data["grade"])
	flags = data["flags"]
	affection = data["affection"]
	play_time = float(data["play_time"])
	current_map = data["current_map"]
	spawn_point = data["spawn_point"]
	party_changed.emit()
	return true
