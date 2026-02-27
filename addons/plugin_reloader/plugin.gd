@tool
extends EditorPlugin

var dock

func _enter_tree():
	dock = preload("reloader_dock.tscn").instantiate()
	add_control_to_dock(DOCK_SLOT_LEFT_UR, dock)
	dock.set_editor_interface(get_editor_interface())

func _exit_tree():
	remove_control_from_docks(dock)
	dock.queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and dock:
		if dock.is_reload_all_shortcut(event):
			print("Shortcut triggered: Reloading all plugins...")
			dock.reload_all_plugins()
			get_viewport().set_input_as_handled()
