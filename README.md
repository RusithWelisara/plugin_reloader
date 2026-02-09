# Plugin Reloader

A simple yet powerful Godot addon that allows you to reload all active plugins without restarting the editor.

## Why use this?

Developing tools or plugins in Godot often requires frequent testing. Traditionally, if you make changes to a `tool` script or a plugin's core logic, you might need to restart the editor or disable/enable the plugin to see changes take effect. 

**Plugin Reloader** solves this by adding a convenient dock that lets you reload specific plugins or all of them with a single click.

## Features

- **One-Click Reload**: Reload all enabled plugins instantly.
- **Selective Reload**: Choose specific plugins to reload (if implemented in future updates, currently reloads all).
- **Time Saver**: drastic reduction in iteration time for plugin developers.
- **Simple Integration**: Just install and use, no configuration required.

## Installation

1. Copy the `addons/plugin_reloader` folder into your project's `addons/` directory.
2. Go to **Project -> Project Settings -> Plugins**.
3. Find **Plugin Reloader** and tick the **Enable** box.
4. A new dock named **"Reloader"** will appear in the bottom panel (or wherever you choose to dock it).

## Usage

1. Open the **Reloader** dock.
2. Click the **"Reload Plugins"** button.
3. Watch the Output log for confirmation that plugins have been reloaded.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.