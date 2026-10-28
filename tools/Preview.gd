extends Node3D
## Preview tool: shows every character model in a row, plays an animation, saves a screenshot.
## godot --path . res://tools/Preview.tscn -- --anim Sword_Regular_A --shot preview.png

var _models: Array[CharacterModel] = []
var _frames := 0
var _shot := ""
var _anim := "Idle"

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--shot" and i + 1 < args.size():
			_shot = args[i + 1]
		if args[i] == "--anim" and i + 1 < args.size():
			_anim = args[i + 1]
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.7, 0.9)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.6, 0.65, 0.8)
	e.ambient_light_energy = 0.6
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 30, 0)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	add_child(sun)
	var floor_mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 40)
	floor_mi.mesh = pm
	floor_mi.set_surface_override_material(0, ToonMaterial.make(Color(0.35, 0.6, 0.3), false))
	add_child(floor_mi)
	var ids := ["lloyd", "colette", "genis", "raine", "kratos", "sheena", "zelos", "presea", "regal", "zombie", "desian", "vidarr", "wolf", "rabbit", "bee"]
	var n := ids.size()
	for i in n:
		var cm := CharacterModel.new()
		add_child(cm)
		cm.load_model(ids[i])
		cm.position = Vector3((i - (n - 1) / 2.0) * 1.3, 0, 0)
		cm.play(_anim if cm.humanoid else "Attack")
		_models.append(cm)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.8, 11.5)
	cam.look_at_from_position(cam.position, Vector3(0, 0.9, 0), Vector3.UP)
	cam.fov = 60
	add_child(cam)
	cam.current = true

