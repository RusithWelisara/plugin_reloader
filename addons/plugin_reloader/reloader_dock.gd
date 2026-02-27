@tool
extends VBoxContainer

const REMOTE_PLUGIN_CFG_URL := "https://raw.githubusercontent.com/RusithWelisara/plugin_reloader/main/addons/plugin_reloader/plugin.cfg"

# Removed explicit type to avoid potential cyclic reference issues
var plugin_interface
@onready var list: ItemList = $PluginList
@onready var options_button: MenuButton = $TopBar/Options
@onready var about_dialog: AcceptDialog = $AboutDialog
@onready var settings_dialog: AcceptDialog = $SettingsDialog
@onready var modifiers_ctrl: CheckBox = $SettingsDialog/VBoxContainer/Modifiers/Ctrl
@onready var modifiers_alt: CheckBox = $SettingsDialog/VBoxContainer/Modifiers/Alt
@onready var modifiers_shift: CheckBox = $SettingsDialog/VBoxContainer/Modifiers/Shift
@onready var modifiers_meta: CheckBox = $SettingsDialog/VBoxContainer/Modifiers/Meta
@onready var key_selector: OptionButton = $SettingsDialog/VBoxContainer/KeySelector

var _is_busy := false
var _about_buttons_initialized := false

# Default shortcut: Ctrl+Alt+R
var reload_all_shortcut := {
	"keycode": KEY_R,
	"ctrl": true,
	"alt": true,
	"shift": false,
	"meta": false,
}

func _set_busy(busy: bool):
	_is_busy = busy
	$Refresh.disabled = busy
	$Reload.disabled = busy
	$ReloadAll.disabled = busy
	# Block input on the list to prevent selection changes
	list.mouse_filter = Control.MOUSE_FILTER_IGNORE if busy else Control.MOUSE_FILTER_STOP

func set_editor_interface(ei):
	plugin_interface = ei
	$Refresh.pressed.connect(refresh_plugins)
	$Reload.pressed.connect(_on_reload_selected)
	$ReloadAll.pressed.connect(reload_all_plugins)
	
	# Top‑right options menu
	var popup := options_button.get_popup()
	popup.clear()
	popup.add_item("About", 0)
	popup.add_item("Settings", 1)
	if not popup.id_pressed.is_connected(_on_options_id_pressed):
		popup.id_pressed.connect(_on_options_id_pressed)

	# About dialog: add "Check for updates" button once
	if not _about_buttons_initialized:
		if not about_dialog.custom_action.is_connected(_on_about_custom_action):
			about_dialog.custom_action.connect(_on_about_custom_action)
		about_dialog.add_button("Check for updates", false, "check_updates")
		_about_buttons_initialized = true
	
	# Settings dialog wiring
	if not settings_dialog.confirmed.is_connected(_on_settings_dialog_confirmed):
		settings_dialog.confirmed.connect(_on_settings_dialog_confirmed)
	_populate_key_selector()
	_load_shortcut_from_settings()
	_apply_shortcut_to_ui()

	if not list.item_clicked.is_connected(_on_item_clicked):
		list.item_clicked.connect(_on_item_clicked)
	refresh_plugins()

func _on_options_id_pressed(id: int) -> void:
	match id:
		0:
			about_dialog.popup_centered()
		1:
			_apply_shortcut_to_ui()
			settings_dialog.popup_centered()

func _on_settings_dialog_confirmed() -> void:
	_update_shortcut_from_ui()
	_save_shortcut_to_settings()

func _on_about_custom_action(action: StringName) -> void:
	if action == "check_updates":
		_check_for_updates()

func _populate_key_selector() -> void:
	key_selector.clear()
	# Add a reasonable set of keys; extend as needed
	var keys: Array[int] = []
	# Digits 0-9
	keys.append_array([KEY_0, KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9])
	# Letters A-Z
	keys.append_array([
		KEY_A, KEY_B, KEY_C, KEY_D, KEY_E, KEY_F, KEY_G, KEY_H, KEY_I, KEY_J,
		KEY_K, KEY_L, KEY_M, KEY_N, KEY_O, KEY_P, KEY_Q, KEY_R, KEY_S, KEY_T,
		KEY_U, KEY_V, KEY_W, KEY_X, KEY_Y, KEY_Z
	])
	# Function keys
	keys.append_array([
		KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5, KEY_F6,
		KEY_F7, KEY_F8, KEY_F9, KEY_F10, KEY_F11, KEY_F12
	])
	# Arrows
	keys.append_array([KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT])

	for k in keys:
		var name := OS.get_keycode_string(k)
		if name != "":
			var idx := key_selector.item_count
			key_selector.add_item(name)
			key_selector.set_item_metadata(idx, k)

	# Limit popup height so it doesn't cover the whole screen; it will scroll instead.
	var popup := key_selector.get_popup()
	if popup:
		var max_size := popup.max_size
		max_size.y = 300
		popup.max_size = max_size

func _apply_shortcut_to_ui() -> void:
	modifiers_ctrl.button_pressed = reload_all_shortcut.get("ctrl", false)
	modifiers_alt.button_pressed = reload_all_shortcut.get("alt", false)
	modifiers_shift.button_pressed = reload_all_shortcut.get("shift", false)
	modifiers_meta.button_pressed = reload_all_shortcut.get("meta", false)

	var keycode: int = reload_all_shortcut.get("keycode", KEY_R)
	for i in range(key_selector.item_count):
		if key_selector.get_item_metadata(i) == keycode:
			key_selector.selected = i
			break

func _update_shortcut_from_ui() -> void:
	var selected_index := key_selector.selected
	if selected_index < 0 or selected_index >= key_selector.item_count:
		return
	var keycode: int = key_selector.get_item_metadata(selected_index)
	reload_all_shortcut = {
		"keycode": keycode,
		"ctrl": modifiers_ctrl.button_pressed,
		"alt": modifiers_alt.button_pressed,
		"shift": modifiers_shift.button_pressed,
		"meta": modifiers_meta.button_pressed,
	}

func _load_shortcut_from_settings() -> void:
	var key := "plugin_reloader/reload_all_shortcut"
	if ProjectSettings.has_setting(key):
		var value = ProjectSettings.get_setting(key)
		if typeof(value) == TYPE_DICTIONARY:
			reload_all_shortcut = value

func _save_shortcut_to_settings() -> void:
	var key := "plugin_reloader/reload_all_shortcut"
	ProjectSettings.set_setting(key, reload_all_shortcut)
	ProjectSettings.save()

func _get_local_version() -> String:
	var cfg := ConfigFile.new()
	var err := cfg.load("res://addons/plugin_reloader/plugin.cfg")
	if err != OK:
		return "0.0.0"
	return str(cfg.get_value("plugin", "version", "0.0.0"))

func _check_for_updates() -> void:
	var local_version := _get_local_version()
	about_dialog.dialog_text = "Plugin Reloader\n\nCurrent version: %s\n\nChecking for updates..." % local_version

	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_update_check_completed.bind(http, local_version))

	var err := http.request(REMOTE_PLUGIN_CFG_URL)
	if err != OK:
		about_dialog.dialog_text = "Plugin Reloader\n\nCurrent version: %s\n\nFailed to start update check: %s" % [local_version, error_string(err)]

func _on_update_check_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest, local_version: String) -> void:
	http.queue_free()

	if response_code != 200 or result != OK:
		about_dialog.dialog_text = "Plugin Reloader\n\nCurrent version: %s\n\nUpdate check failed (HTTP %d)." % [local_version, response_code]
		return

	var text := body.get_string_from_utf8()
	var cfg := ConfigFile.new()
	var err := cfg.parse(text)
	if err != OK:
		about_dialog.dialog_text = "Plugin Reloader\n\nCurrent version: %s\n\nUpdate check failed: invalid remote config." % local_version
		return

	var remote_version := str(cfg.get_value("plugin", "version", "0.0.0"))
	var up_to_date := _is_version_at_least(local_version, remote_version)

	if up_to_date:
		about_dialog.dialog_text = "Plugin Reloader\n\nYou are up to date.\n\nCurrent version: %s\nLatest version:  %s" % [local_version, remote_version]
	else:
		about_dialog.dialog_text = "Plugin Reloader\n\nA new version is available!\n\nCurrent version: %s\nLatest version:  %s" % [local_version, remote_version]

func _is_version_at_least(current: String, latest: String) -> bool:
	var c_parts := current.split(".")
	var l_parts := latest.split(".")
	var max_len := max(c_parts.size(), l_parts.size())
	for i in range(max_len):
		var c := 0
		if i < c_parts.size():
			c = int(c_parts[i])
		var l := 0
		if i < l_parts.size():
			l = int(l_parts[i])
		if c < l:
			return false
		if c > l:
			return true
	return true

func is_reload_all_shortcut(event: InputEventKey) -> bool:
	if not event.pressed or event.echo:
		return false
	return (
		event.keycode == reload_all_shortcut.get("keycode", KEY_R)
		and event.ctrl_pressed == reload_all_shortcut.get("ctrl", false)
		and event.alt_pressed == reload_all_shortcut.get("alt", false)
		and event.shift_pressed == reload_all_shortcut.get("shift", false)
		and event.meta_pressed == reload_all_shortcut.get("meta", false)
	)

func refresh_plugins():
	list.clear()
	var dir = DirAccess.open("res://addons")
	if dir:
		dir.list_dir_begin()
		var name = dir.get_next()
		while name != "":
			if name == "." or name == "..":
				name = dir.get_next()
				continue
			if dir.current_is_dir() and FileAccess.file_exists("res://addons/%s/plugin.cfg" % name):
				var is_enabled = plugin_interface.is_plugin_enabled(name)
				var icon = get_theme_icon("checked", "CheckBox") if is_enabled else get_theme_icon("unchecked", "CheckBox")
				list.add_item(name, icon)
				# Store current state in metadata for easy toggling
				list.set_item_metadata(list.item_count - 1, is_enabled)
			name = dir.get_next()
		dir.list_dir_end()

func _on_item_clicked(index: int, _at_position: Vector2, _mouse_button_index: int):
	var plugin_name = list.get_item_text(index)
	# Prevent disabling self
	if plugin_name == "plugin_reloader":
		print("Cannot disable Plugin Reloader from within itself.")
		return

	var current_state = list.get_item_metadata(index)
	var new_state = !current_state
	
	plugin_interface.set_plugin_enabled(plugin_name, new_state)
	
	# Update UI
	var icon = get_theme_icon("checked", "CheckBox") if new_state else get_theme_icon("unchecked", "CheckBox")
	list.set_item_icon(index, icon)
	list.set_item_metadata(index, new_state)
	
	print("Plugin '", plugin_name, "' is now ", "Enabled" if new_state else "Disabled")

func _on_reload_selected():
	if _is_busy:
		return
		
	var sel = list.get_selected_items()
	if sel.is_empty():
		return
	
	_set_busy(true)
	await reload_plugin(list.get_item_text(sel[0]))
	_set_busy(false)

func reload_all_plugins():
	if _is_busy:
		return

	_set_busy(true)
	# Execute sequentially to avoid coroutine errors and potential conflicts
	for i in range(list.item_count):
		var pname = list.get_item_text(i)
		# Skip self to avoid reloading the reloader itself which could interupt the process
		if pname == "plugin_reloader":
			continue
		
		await reload_plugin(pname)
			
	_set_busy(false)

func reload_plugin(plugin_name:String):
	if plugin_name == "plugin_reloader":
		print("Cannot reload Plugin Reloader from within itself. Use Project Settings > Plugins.")
		return

	print("Reloading plugin: ", plugin_name)
	plugin_interface.set_plugin_enabled(plugin_name, false)
	
	# Wait briefly for plugin to be fully disabled and autoloads/nodes to clean up,
	# then rescan the filesystem and re‑enable the plugin. Rely on Godot's normal
	# reload behavior instead of forcing GDScript.reload(), which can fail if
	# instances still exist (e.g. autoload singletons like dialogue_manager).
	await get_tree().create_timer(0.5).timeout
	plugin_interface.get_resource_filesystem().scan()
	await get_tree().create_timer(0.1).timeout
	plugin_interface.set_plugin_enabled(plugin_name, true)
