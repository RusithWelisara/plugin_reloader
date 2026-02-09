# Plugin Reloader

A simple yet powerful Godot addon that allows you to reload all active plugins without restarting the editor.

## Why use this?

Developing tools or plugins in Godot often requires frequent testing. Traditionally, if you make changes to a `tool` script or a plugin's core logic, you might need to restart the editor or disable/enable the plugin to see changes take effect. 

**Plugin Reloader** solves this by adding a convenient dock that lets you reload specific plugins or all of them with a single click.

## Features

- **Selective Reload**: Toggle individual plugins on/off to reload only what you need.
- **Global Shortcut**: Press `Ctrl + Alt + R` to reload all active plugins instantly.
- **One-Click Reload**: Reload all enabled plugins via the dock button.
- **Time Saver**: Drastically reduces iteration time for plugin developers.
- **Simple Integration**: Just install and use, no configuration required.

## Installation

1. Copy the `addons/plugin_reloader` folder into your project's `addons/` directory.
2. Go to **Project -> Project Settings -> Plugins**.
3. Find **Plugin Reloader** and tick the **Enable** box.
4. A new dock named **"Reloader"** will appear in the **Left Dock** panel (Upper Right slot).

## Usage

### Using the Dock
1. Open the **Reloader** dock.
2. You will see a list of all active plugins with checkboxes.
3. **Toggle** the checkboxes to enable or disable specific plugins from the reload process.
4. Click the **"Reload Plugins"** button to reload all selected plugins.

### Using Shortcuts
- **`Ctrl + Alt + R`**:  Immediately reloads all enabled plugins.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.