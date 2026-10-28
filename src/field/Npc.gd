class_name Npc
extends StaticBody3D
## Talkable NPC with a model and dialogue lines. Dialogue may be a flag-conditional list.

@export var npc_name := "Villager"
@export var model_id := "zelos"
@export var lines: Array = []     # [{"speaker": "...", "text": "..."}]
@export var face_player := true
@export var idle_anim := "Idle"
const MODEL_SCALE := {"dirk": 0.78, "genis": 0.82, "presea": 0.85, "colette": 0.95, "marble": 0.92, "phaidra": 0.9, "mithos": 0.85, "forcystus": 1.12, "vidarr": 1.5}
var model: CharacterModel
var on_interact: Callable  # optional custom handler(field) -> void (awaitable)

func _ready() -> void:
	collision_layer = 1 | 4
	collision_mask = 0
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.6
	shape.shape = cap
	shape.position.y = 0.85
	add_child(shape)
	model = CharacterModel.new()
	add_child(model)
	model.load_model(model_id)
	model.rotation.y = PI  # glb faces -Z; node forward is +Z (same convention as FieldPlayer)
	var sc: float = MODEL_SCALE.get(model_id, 1.0)
	model.scale = Vector3.ONE * sc
	model.play(idle_anim)

func interact(field) -> void:
	if on_interact.is_valid():
		await on_interact.call(field)
		return
	if lines.is_empty():
		return
	if face_player and field.player:
		var d: Vector3 = field.player.global_position - global_position
		d.y = 0
		if d.length() > 0.01:
			rotation.y = atan2(d.x, d.z)
	await field.dialogue.show_lines(lines)

func face_pos(pos: Vector3) -> void:
	var d: Vector3 = pos - global_position
	d.y = 0
	if d.length() > 0.01:
		rotation.y = atan2(d.x, d.z)
