# Hyprland Themes & Scripts

Collection of themes and custom scripts used in my Hyprland/Wayland setup.  
Includes Bash scripts, CSS tweaks, and various utilities.

## Installation

### Clone directly into your config directory:

```
git clone https://github.com/risav68111/hyprland_themes_scripts.git ~/dotfiles
```

### Required Packages
```
sudo pacman -S rofi hyprpaper swaync hyprlock hypridle wlogout swww hyprshot 
```
,etc.

### Make Scripts Executable
```
chmod -R +x ~/.config/scripts/
```
---
run below command once.
```
chmod +x ~/dotfiles/Default/.config/scripts/theme_selector.sh
bash ~/dotfiles/Default/.config/scripts/theme_selector.sh
``` 
then select theme.

---
## For Wallpapers
keep in '`~/.config/wallpapers`' 
  
  and keep the if you want to change different wallpapers changes through theme then keep in '`~/dotfiles/<theme>/.config/wallpapers/`' 
