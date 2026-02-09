@tool
extends EditorPlugin

var dock

func _enter_tree():
	dock = preload("res://addons/plugin_reloader/reloader_dock.tscn").instantiate()
	add_control_to_dock(DOCK_SLOT_LEFT_UR, dock)
	dock.set_editor_interface(get_editor_interface())

func _exit_tree():
	remove_control_from_docks(dock)
	dock.queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_R and event.ctrl_pressed and event.alt_pressed:
			if dock:
				print("Shortcut triggered: Reloading all plugins...")
				dock.reload_all_plugins()
				get_viewport().set_input_as_handled()
