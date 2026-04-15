extends Node


signal event_logged(message: String)


func log_event(message: String) -> void:
	print(get_path(), ": ", message)
	event_logged.emit(message)
