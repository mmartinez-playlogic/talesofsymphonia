extends StaticBody3D
var lines: Array = []
func interact(field) -> void:
	await field.dialogue.show_lines(lines)
