extends Node
## Music (looping, cross-fade) and sound effects (pooled players).
##   Audio.play_music("battle")   Audio.stop_music()   Audio.sfx("hit")
## Files: res://assets/audio/music/<id>.ogg, res://assets/audio/sfx/<id>.wav

const MUSIC_DIR := "res://assets/audio/music/"
const SFX_DIR := "res://assets/audio/sfx/"
const NO_LOOP := ["victory", "gameover"]

var music_volume_db := -6.0
var sfx_volume_db := -3.0
var current := ""
var _players: Array[AudioStreamPlayer] = []
var _active := 0
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_cache: Dictionary = {}
var _music_cache: Dictionary = {}
var _stack: Array[String] = []          # for push/pop (battle -> back to field music)
var _last_sfx_time: Dictionary = {}
var played: Dictionary = {}               # sfx id -> times requested (used by tests)
var music_log: Array[String] = []         # tracks started, in order (used by tests)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		p.volume_db = -80.0
		add_child(p)
		_players.append(p)
	for i in 14:
		var s := AudioStreamPlayer.new()
		s.volume_db = sfx_volume_db
		add_child(s)
		_sfx_pool.append(s)

func _music_stream(id: String) -> AudioStream:
	if _music_cache.has(id):
		return _music_cache[id]
	var path := MUSIC_DIR + id + ".ogg"
	if not ResourceLoader.exists(path):
		push_warning("[Audio] missing music " + path)
		return null
	var st: AudioStream = load(path)
	if st is AudioStreamOggVorbis:
		(st as AudioStreamOggVorbis).loop = not NO_LOOP.has(id)
	_music_cache[id] = st
	return st

func has_music(id: String) -> bool:
	return ResourceLoader.exists(MUSIC_DIR + id + ".ogg")

func has_sfx(id: String) -> bool:
	return ResourceLoader.exists(SFX_DIR + id + ".wav")

## Cross-fade to a track. Same track already playing: nothing happens.
func play_music(id: String, fade := 0.8, restart := false) -> void:
	if id == "":
		return
	if id == current and not restart and _players[_active].playing:
		return
	var st := _music_stream(id)
	if st == null:
		return
	current = id
	music_log.append(id)
	var old := _players[_active]
	_active = 1 - _active
	var nw := _players[_active]
	nw.stream = st
	nw.volume_db = -40.0 if fade > 0 else music_volume_db
	nw.play()
	if fade > 0:
		var t := create_tween().set_parallel(true)
		t.tween_property(nw, "volume_db", music_volume_db, fade)
		t.tween_property(old, "volume_db", -60.0, fade)
		t.chain().tween_callback(old.stop)
	else:
		old.stop()

func stop_music(fade := 0.8) -> void:
	current = ""
	var p := _players[_active]
	if fade <= 0:
		p.stop()
		return
	var t := create_tween()
	t.tween_property(p, "volume_db", -60.0, fade)
	t.tween_callback(p.stop)

## Remember the current track (e.g. before a battle) and switch.
func push_music(id: String, fade := 0.3) -> void:
	_stack.append(current)
	play_music(id, fade, true)

func pop_music(fade := 0.8) -> void:
	var prev: String = _stack.pop_back() if not _stack.is_empty() else ""
	if prev != "":
		play_music(prev, fade, true)

func is_playing(id: String) -> bool:
	return current == id and _players[_active].playing

## Play a sound effect. Rapid repeats of the same effect are rate-limited.
func sfx(id: String, volume_db := 0.0, pitch_jitter := 0.04) -> void:
	played[id] = int(played.get(id, 0)) + 1
	var now := Time.get_ticks_msec()
	if now - int(_last_sfx_time.get(id, -1000)) < 35:
		return
	_last_sfx_time[id] = now
	var st: AudioStream = _sfx_cache.get(id)
	if st == null:
		var path := SFX_DIR + id + ".wav"
		if not ResourceLoader.exists(path):
			push_warning("[Audio] missing sfx " + path)
			return
		st = load(path)
		_sfx_cache[id] = st
	var p: AudioStreamPlayer = null
	for s in _sfx_pool:
		if not s.playing:
			p = s
			break
	if p == null:
		p = _sfx_pool[0]
	p.stream = st
	p.volume_db = sfx_volume_db + volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.play()
