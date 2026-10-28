extends Node
## Mutable game state: party, inventory, equipment, titles, EX skills, cooking, story flags, affection, gald. Save/load.

signal party_changed
signal flag_changed(flag: String, value)
signal title_earned(char_id: String, title_id: String)

const SAVE_PATH := "user://save_%d.json"
const SLOT_COUNT := 3
const MAP_TITLES := {"iselia_school": "Iselia · Escuela", "iselia_village": "Iselia", "iselia_forest": "Bosque de Iselia",
	"martel_temple_ext": "Templo de Martel", "martel_temple": "Templo de Martel · Interior", "iselia_ranch": "Rancho de Iselia",
	"dirks_house": "Casa de Dirk", "world_sylvarant": "Sylvarant", "triet_desert": "Desierto de Triet"}
var pending_load_pos = null      # Vector3 to spawn at after loading a save
const SLOTS := ["weapon", "body", "head", "arm", "acc1", "acc2"]
const SLOT_NAMES := {"weapon": "Arma", "body": "Cuerpo", "head": "Cabeza", "arm": "Brazos", "acc1": "Accesorio 1", "acc2": "Accesorio 2"}

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
var seen_skits: Array = []
var recipes: Array = []          # known recipe ids
var cook_successes: int = 0

func _process(delta: float) -> void:
	play_time += delta

func new_game() -> void:
	party.clear()
	members.clear()
	inventory.clear()
	flags.clear()
	affection.clear()
	seen_skits.clear()
	recipes.clear()
	cook_successes = 0
	gald = 0
	grade = 0.0
	play_time = 0.0
	current_map = "iselia_school"
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
	var titles: Array = []
	for tid in DB.titles:
		var t: Dictionary = DB.titles[tid]
		if t.get("user", "") == id and (bool(t.get("start", false)) or (t.has("flag") and get_flag(t["flag"], false))):
			titles.append(tid)
	var state := {
		"id": id,
		"level": lvl,
		"exp": DB.exp_for_level(lvl),
		"hp": 0,
		"tp": 0,
		"artes": _artes_known(id, lvl),
		"shortcuts": [],
		"equipment": data.get("start_equipment", {}).duplicate(),
		"titles": titles,
		"title": titles[0] if titles.size() > 0 else "",
		"ex_gems": {"1": "", "2": "", "3": "", "4": ""},   # level -> ex skill id
		"cooking": {},                                      # recipe -> successes
		"strategy": "normal",
	}
	members[id] = state
	state["hp"] = max_hp(id)
	state["tp"] = max_tp(id)
	if party.size() < 4:
		party.append(id)
	party_changed.emit()

func remove_from_party(id: String) -> void:
	party.erase(id)
	party_changed.emit()

## Replace the active party (ids must already be members; unknown ids are added).
func set_party(ids: Array) -> void:
	party.clear()
	for id in ids:
		if not members.has(id):
			add_member(id)
			party.erase(id)
		if party.size() < 4:
			party.append(id)
	party_changed.emit()

func has_member(id: String) -> bool:
	return members.has(id)

func leader() -> String:
	return party[0] if party.size() > 0 else "lloyd"

func _artes_known(id: String, level: int) -> Array:
	var known: Array = []
	for arte_id in DB.artes:
		var a: Dictionary = DB.artes[arte_id]
		if a.get("user", "") == id and int(a.get("level", 999)) <= level:
			known.append(arte_id)
	return known

# ---------- stats ----------
func max_hp(id: String) -> int:
	var v := float(DB.stat_at(id, "hp", members[id]["level"]))
	v *= 1.0 + float(ex_effects(id).get("max_hp", 0.0))
	v *= 1.0 + float(title_mods(id).get("hp", 0.0))
	return int(round(v))

func max_tp(id: String) -> int:
	var v := float(DB.stat_at(id, "tp", members[id]["level"]))
	v *= 1.0 + float(title_mods(id).get("tp", 0.0))
	return int(round(v))

func stat(id: String, name: String) -> int:
	var m: Dictionary = members[id]
	var v := float(DB.stat_at(id, name, m["level"]))
	for slot in m["equipment"]:
		var item: Dictionary = DB.items.get(m["equipment"][slot], {})
		v += float(item.get("stats", {}).get(name, 0))
	v *= 1.0 + float(title_mods(id).get(name, 0.0)) + float(ex_effects(id).get(name, 0.0))
	return int(round(v))

func title_mods(id: String) -> Dictionary:
	var t: String = str(members[id].get("title", ""))
	return DB.titles.get(t, {}).get("mods", {})

## Merged effects of all equipped EX skills: {"atk": 0.1, "tp_cost": -0.25, "super_armor": true, ...}
func ex_effects(id: String) -> Dictionary:
	var out := {}
	var gems: Dictionary = members[id].get("ex_gems", {})
	for lvl in gems:
		var sid: String = str(gems[lvl])
		if sid == "":
			continue
		for sk in DB.ex_skills.get(id, []):
			if sk["id"] == sid and int(sk["level"]) == int(lvl):
				for k in sk["effect"]:
					var val = sk["effect"][k]
					if val is bool:
						out[k] = out.get(k, false) or val
					else:
						out[k] = float(out.get(k, 0.0)) + float(val) if k != "combo" and k != "ol_rate" else val
	return out

func ex_skills_for(id: String, level: int) -> Array:
	return DB.ex_skills.get(id, []).filter(func(s): return int(s["level"]) == level)

func set_ex_gem(id: String, level: int, skill_id: String) -> bool:
	var m: Dictionary = members[id]
	var key := str(level)
	if skill_id == "":
		if str(m["ex_gems"].get(key, "")) != "":
			add_item("ex_gem_%d" % level, 1)
			m["ex_gems"][key] = ""
		return true
	if str(m["ex_gems"].get(key, "")) == "":
		if not has_item("ex_gem_%d" % level):
			return false
		add_item("ex_gem_%d" % level, -1)
	m["ex_gems"][key] = skill_id
	_clamp_hp(id)
	return true

# ---------- equipment ----------
func can_equip(id: String, item_id: String, slot: String) -> bool:
	var it: Dictionary = DB.items.get(item_id, {})
	if it.is_empty():
		return false
	var t: String = str(it.get("type", ""))
	if slot == "acc1" or slot == "acc2":
		if t != "accessory":
			return false
	elif t != slot:
		return false
	if it.has("users") and not (it["users"] as Array).has(id):
		return false
	return true

func equip(id: String, slot: String, item_id: String) -> bool:
	if not can_equip(id, item_id, slot) or not has_item(item_id):
		return false
	var m: Dictionary = members[id]
	var old: String = str(m["equipment"].get(slot, ""))
	add_item(item_id, -1)
	if old != "":
		add_item(old, 1)
	m["equipment"][slot] = item_id
	_clamp_hp(id)
	return true

func unequip(id: String, slot: String) -> void:
	var m: Dictionary = members[id]
	var old: String = str(m["equipment"].get(slot, ""))
	if old != "":
		add_item(old, 1)
		m["equipment"][slot] = ""
		_clamp_hp(id)

func _clamp_hp(id: String) -> void:
	var m: Dictionary = members[id]
	m["hp"] = min(int(m["hp"]), max_hp(id))
	m["tp"] = min(int(m["tp"]), max_tp(id))

func equippable_items(id: String, slot: String) -> Array:
	var out: Array = []
	for item_id in inventory:
		if can_equip(id, item_id, slot):
			out.append(item_id)
	out.sort()
	return out

# ---------- titles ----------
func set_title(id: String, title_id: String) -> void:
	if (members[id]["titles"] as Array).has(title_id):
		members[id]["title"] = title_id
		_clamp_hp(id)

## Check title conditions for a flag; returns [[char_id, title_id], ...] newly earned.
func _check_titles(flag: String) -> Array:
	var earned: Array = []
	for tid in DB.titles:
		var t: Dictionary = DB.titles[tid]
		if t.get("flag", "") != flag:
			continue
		var uid: String = str(t.get("user", ""))
		if members.has(uid) and not (members[uid]["titles"] as Array).has(tid):
			members[uid]["titles"].append(tid)
			earned.append([uid, tid])
			title_earned.emit(uid, tid)
	return earned

# ---------- experience ----------
func grant_exp(id: String, amount: int) -> Array:
	## Returns list of levels gained.
	var m: Dictionary = members[id]
	amount = int(amount * (1.0 + float(ex_effects(id).get("exp", 0.0))))
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

# ---------- items ----------
func add_item(id: String, count: int = 1) -> void:
	inventory[id] = int(inventory.get(id, 0)) + count
	if inventory[id] <= 0:
		inventory.erase(id)

func has_item(id: String) -> bool:
	return int(inventory.get(id, 0)) > 0

func item_count(id: String) -> int:
	return int(inventory.get(id, 0))

func use_item(item_id: String, char_id: String) -> bool:
	var item: Dictionary = DB.items.get(item_id, {})
	if item.is_empty() or not has_item(item_id) or not members.has(char_id):
		return false
	var fx: Dictionary = item.get("effect", {})
	var m: Dictionary = members[char_id]
	var boost := 1.0
	for pid in party:
		boost = max(boost, 1.0 + float(ex_effects(pid).get("item", 0.0)))
	if fx.has("revive"):
		if int(m["hp"]) > 0:
			return false
		m["hp"] = max(1, int(max_hp(char_id) * float(fx["revive"])))
	else:
		if int(m["hp"]) <= 0:
			return false
		if fx.has("hp_pct"):
			m["hp"] = min(max_hp(char_id), int(m["hp"]) + int(max_hp(char_id) * float(fx["hp_pct"]) * boost))
		if fx.has("tp_pct"):
			m["tp"] = min(max_tp(char_id), int(m["tp"]) + int(max_tp(char_id) * float(fx["tp_pct"]) * boost))
		if fx.has("cure"):
			m["status"] = ""
	add_item(item_id, -1)
	return true

func sell_price(item_id: String) -> int:
	return int(DB.items.get(item_id, {}).get("price", 0)) / 2

func buy(item_id: String, count: int = 1) -> bool:
	var price: int = int(DB.items.get(item_id, {}).get("price", 0)) * count
	if price > gald or price <= 0:
		return false
	gald -= price
	add_item(item_id, count)
	return true

func sell(item_id: String, count: int = 1) -> bool:
	if item_count(item_id) < count:
		return false
	var it: Dictionary = DB.items.get(item_id, {})
	if it.get("type", "") == "key":
		return false
	gald += sell_price(item_id) * count
	add_item(item_id, -count)
	return true

# ---------- cooking ----------
func learn_recipe(id: String) -> bool:
	if recipes.has(id) or not DB.recipes.has(id):
		return false
	recipes.append(id)
	return true

func can_cook(recipe_id: String) -> bool:
	var r: Dictionary = DB.recipes.get(recipe_id, {})
	for ing in r.get("ingredients", {}):
		if item_count(ing) < int(r["ingredients"][ing]):
			return false
	return true

func cook_skill(char_id: String, recipe_id: String) -> int:
	return int(members[char_id].get("cooking", {}).get(recipe_id, 0))

## Cook a recipe with a given party member. Returns {"ok": bool, "msg": String}.
func cook(recipe_id: String, char_id: String) -> Dictionary:
	var r: Dictionary = DB.recipes.get(recipe_id, {})
	if r.is_empty() or not recipes.has(recipe_id):
		return {"ok": false, "msg": "Receta desconocida."}
	if not can_cook(recipe_id):
		return {"ok": false, "msg": "Faltan ingredientes."}
	for ing in r["ingredients"]:
		add_item(ing, -int(r["ingredients"][ing]))
	var skill := cook_skill(char_id, recipe_id)
	var chance: float = 0.45 + skill * 0.1 - (int(r.get("difficulty", 1)) - 1) * 0.1
	if (r.get("best", []) as Array).has(char_id):
		chance += 0.25
	chance = clamp(chance, 0.2, 0.98)
	var ok := randf() < chance
	var cooking: Dictionary = members[char_id].get("cooking", {})
	cooking[recipe_id] = skill + (1 if ok else 0)
	members[char_id]["cooking"] = cooking
	var name: String = DB.characters[char_id]["name"].split(" ")[0]
	if not ok:
		return {"ok": false, "msg": "%s ha quemado %s. Qué desastre..." % [name, r["name"]]}
	var fx: Dictionary = r.get("effect", {})
	for pid in party:
		var m: Dictionary = members[pid]
		if int(m["hp"]) <= 0:
			continue
		if fx.has("hp_pct"):
			m["hp"] = min(max_hp(pid), int(m["hp"]) + int(max_hp(pid) * float(fx["hp_pct"])))
		if fx.has("tp_pct"):
			m["tp"] = min(max_tp(pid), int(m["tp"]) + int(max_tp(pid) * float(fx["tp_pct"])))
		if fx.has("cure"):
			m["status"] = ""
	cook_successes += 1
	if cook_successes >= 10:
		set_flag("cook_10", true)
	return {"ok": true, "msg": "¡%s ha preparado %s! Todo el grupo se recupera." % [name, r["name"]]}

# ---------- flags ----------
func set_flag(flag: String, value = true) -> void:
	flags[flag] = value
	flag_changed.emit(flag, value)
	if value:
		_check_titles(flag)

func get_flag(flag: String, default = false):
	return flags.get(flag, default)

func heal_all() -> void:
	for id in members:
		members[id]["hp"] = max_hp(id)
		members[id]["tp"] = max_tp(id)

# ---------- save / load ----------
func save(slot: int = 0, pos = null) -> void:
	var lv: Array = []
	for id in party:
		lv.append([id, int(members[id]["level"])])
	var meta := {"map": current_map, "map_title": MAP_TITLES.get(current_map, current_map), "time": play_time,
		"date": Time.get_datetime_string_from_system(false, true), "party": lv, "gald": gald,
		"demo_complete": bool(get_flag("demo_complete", false))}
	var data := {
		"meta": meta, "pos": [pos.x, pos.y, pos.z] if pos is Vector3 else null,
		"party": party, "members": members, "inventory": inventory, "gald": gald, "grade": grade,
		"flags": flags, "affection": affection, "play_time": play_time, "current_map": current_map,
		"spawn_point": spawn_point, "seen_skits": seen_skits, "recipes": recipes, "cook_successes": cook_successes,
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
	seen_skits.assign(data.get("seen_skits", []))
	recipes.assign(data.get("recipes", []))
	cook_successes = int(data.get("cook_successes", 0))
	var p = data.get("pos", null)
	pending_load_pos = Vector3(float(p[0]), float(p[1]) + 0.1, float(p[2])) if p is Array and p.size() == 3 else null
	last_field_position = Vector3.ZERO
	return_to_field = false
	party_changed.emit()
	return true

## Summary of a slot for menus: {} when empty.
func slot_info(slot: int) -> Dictionary:
	var path := SAVE_PATH % slot
	if not FileAccess.file_exists(path):
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (data is Dictionary):
		return {}
	var meta: Dictionary = data.get("meta", {})
	if meta.is_empty():
		meta = {"map": data.get("current_map", "?"), "map_title": MAP_TITLES.get(str(data.get("current_map", "")), "?"), "time": data.get("play_time", 0), "date": "", "party": [], "gald": data.get("gald", 0)}
	return meta

func any_save() -> bool:
	for i in SLOT_COUNT:
		if save_exists(i):
			return true
	return false

func delete_save(slot: int) -> void:
	if save_exists(slot):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH % slot))

func save_exists(slot: int = 0) -> bool:
	return FileAccess.file_exists(SAVE_PATH % slot)
