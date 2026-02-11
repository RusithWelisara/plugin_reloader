@tool
extends VBoxContainer

# Removed explicit type to avoid potential cyclic reference issues
var plugin_interface
@onready var list : ItemList = $PluginList

func set_editor_interface(ei):
	plugin_interface = ei
	$Refresh.pressed.connect(refresh_plugins)
	$Reload.pressed.connect(_on_reload_selected)
	$ReloadAll.pressed.connect(reload_all_plugins)
	if not list.item_clicked.is_connected(_on_item_clicked):
		list.item_clicked.connect(_on_item_clicked)
	refresh_plugins()

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
	var sel = list.get_selected_items()
	if sel.is_empty():
		return
	reload_plugin(list.get_item_text(sel[0]))

func reload_all_plugins():
	for i in range(list.item_count):
		reload_plugin(list.get_item_text(i))

func reload_plugin(plugin_name:String):
	if plugin_name == "plugin_reloader":
		print("Cannot reload Plugin Reloader from within itself. Use Project Settings > Plugins.")
		return

	print("Reloading plugin: ", plugin_name)
	plugin_interface.set_plugin_enabled(plugin_name, false)
	
	# Force reload scripts from disk
	var plugin_path = "res://addons/" + plugin_name
	_reload_scripts_recursive(plugin_path)
	
	# Allow some time for cleanup and file system scan
	plugin_interface.get_resource_filesystem().scan()
	await get_tree().create_timer(0.1).timeout
	plugin_interface.set_plugin_enabled(plugin_name, true)

func _reload_scripts_recursive(path: String):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name == "." or file_name == "..":
				file_name = dir.get_next()
				continue
			
			var full_path = path + "/" + file_name
			if dir.current_is_dir():
				_reload_scripts_recursive(full_path)
			elif file_name.ends_with(".gd"):
				var res = ResourceLoader.load(full_path, "", ResourceLoader.CACHE_MODE_REPLACE)
				if res is GDScript:
					res.reload()
			
			file_name = dir.get_next()
		dir.list_dir_end()
