class_name Skits
extends RefCounted
## Skit availability. Data in src/data/skits.json:
##   "id": {"title": "...", "requires": ["flag"], "forbids": ["flag"], "map": "optional_map",
##          "party": ["lloyd"], "lines": [{"speaker": "Lloyd", "text": "...", "mood": "happy"}]}

static func available(map_id: String) -> Array:
	var out: Array = []
	for id in DB.skits:
		if id in Game.seen_skits:
			continue
		var s: Dictionary = DB.skits[id]
		if s.has("map") and s["map"] != map_id:
			continue
		var ok := true
		for f in s.get("requires", []):
			if not Game.get_flag(f, false):
				ok = false
		for f in s.get("forbids", []):
			if Game.get_flag(f, false):
				ok = false
		for c in s.get("party", []):
			if not Game.party.has(c):
				ok = false
		if ok:
			out.append(id)
	return out

static func title(id: String) -> String:
	return str(DB.skits.get(id, {}).get("title", id))
