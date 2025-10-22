# 🖌️ System Configuration Notes

## **Core Components** 🏗️
### Hyprland
- **Role:** Window manager (Wayland compositor)
- **Purpose:** Controls window layout, animations, and keyboard shortcuts.
- **Config file:** `~/.config/hypr/hyprland.conf`
- **Key concept:** Tiling + gestures + transitions under Wayland.


### Waybar
- **Role:** Top bar / system status bar
- **Purpose:** Displays workspaces, system stats, clock, network, etc.
- **Config files:**
  - `~/.config/waybar/config`
  - `~/.config/waybar/style.css`
- **Tip:** Use CSS for hover animations and color themes.

### Wpaperd
- **Role:** Wallpaper manager for Wayland
- **Purpose:** Sets per-monitor wallpapers with transitions.
- **Config file:** `~/.config/wpaperd/config.toml`

---


## **Supporting Tools** 🧰
### Kitty
- **Role:** Terminal emulator
- **Purpose:** Main terminal, supports GPU rendering and transparency.
- **Config file:** `~/.config/kitty/kitty.conf`
- **Tips:**  
  - Add cursor trail and neon effects.  
  - Adjust opacity with `background_opacity`.
 
### Fish
- **Role:** Shell
- **Purpose:** User-friendly shell with autosuggestions and syntax highlighting.
- **Config file:** `~/.config/fish/config.fish`
- **Note:** Kitty uses Fish as its default shell (`shell fish`).

### Git + GitHub
- **Role:** Version control for configuration files.
- **Purpose:** Backup and sync `.dotfiles` across systems.
- **Main folder:** `~/.dotfiles`
- **Tip:** Use symbolic links (`ln -s`) to point config folders to `.dotfiles`.

### Symbolic Links
- **Role:** Connects real config files to your Git-tracked repo.
- **Purpose:** Keeps your `.config` organized and versioned without duplication.
- **Example:**
  ```bash
  ln -s ~/.dotfiles/hypr ~/.config/hypr
