extends StaticBody3D
## Generic interactable: `handler(field)` coroutine is awaited on confirm.
var handler: Callable
var modulate_opened := false
func interact(field) -> void:
	if handler.is_valid():
		await handler.call(field)
