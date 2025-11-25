#!/usr/bin/env bash

THEMES_DIR="$HOME/.config/themes"
STATE_FILE="$HOME/.config/hypr/.current_theme"
DEFAULT_WALL="$HOME/.config/hypr/default_wallpaper.jpg"
ROFI_THEME="$HOME/.config/rofi/themes/drun-translucent.rasi"

# 1. Ensure default theme exists
if [[ ! -d "$THEMES_DIR" || -z "$(ls -A "$THEMES_DIR" 2>/dev/null)" ]]; then
  mkdir -p "$THEMES_DIR/default/hypr"
  echo "source = ~/.config/hypr/hyprland.conf" > "$THEMES_DIR/default/hypr/hyprland.conf"
  notify-send "No themes found" "Created default theme"
  THEMES=("default")
else
  mapfile -t THEMES < <(ls -1 "$THEMES_DIR" 2>/dev/null)
fi

# 2. Build Rofi input with icons
ROFI_INPUT=""
for theme in "${THEMES[@]}"; do
  icon=""
  for ext in png jpg jpeg svg; do
    if [[ -f "$THEMES_DIR/$theme/icon.$ext" ]]; then
      icon="$THEMES_DIR/$theme/icon.$ext"
      break
    elif [[ -f "$THEMES_DIR/$theme/preview.$ext" ]]; then
      icon="$THEMES_DIR/$theme/preview.$ext"
      break
    fi
  done

  # Use placeholder icon if none
  # [[ -z "$icon" ]] && icon="  "

  # Rofi zero-width space trick for icons
  # ROFI_INPUT+="$(printf '%b' "\0$icon    ")"
  ROFI_INPUT+="$theme\n"
done

# 3. Show Rofi with icons
SELECTED=$(echo -e "$ROFI_INPUT" | \
  rofi -dmenu \
       -p "Select theme" \
       -i \
       -theme "$ROFI_THEME" \
       -show-icons \
       -markup-rows)

[[ -z "$SELECTED" ]] && { notify-send "Theme selection cancelled"; exit 0; }

# 4. Find index
for i in "${!THEMES[@]}"; do
  [[ "${THEMES[$i]}" == "$SELECTED" ]] && { NEXT=$i; break; }
done

THEME="$SELECTED"
THEME_DIR="$THEMES_DIR/$THEME"

# 5. DYNAMIC CONFIG FOLDER SYNC (Protected hypr)
for src_dir in "$THEME_DIR"/*/; do
  src_dir=${src_dir%/}
  folder_name=$(basename "$src_dir")
  [[ "$folder_name" == "wallpapers" ]] && continue
  target_dir="$HOME/.config/$folder_name"

  [[ ! -d "$src_dir" ]] && continue

  if [[ "$folder_name" == "hypr" ]]; then
    mkdir -p "$target_dir"
    # rsync -av --exclude='hyprland.conf' --exclude='scripts/' "$src_dir/" "$target_dir/"
    # [[ ! -f "$target_dir/hyprland.conf" ]] && cp -v "$src_dir/hyprland.conf" "$target_dir/"
  #   [[ ! -d "$target_dir/scripts" ]] && cp -r "$src_dir/scripts" "$target_dir/"
  #   [[ ! -d "$target_dir/config" ]] && cp -r "$src_dir/scripts" "$target_dir/"
  # else
    rm -rf "$target_dir"
    cp -r "$src_dir" "$HOME/.config/"
  fi
done

# 6. WALLPAPER HANDLING
if [[ -d "$THEME_DIR/wallpapers" && -n "$(ls -A "$THEME_DIR/wallpapers")" ]]; then
  WALLPAPER=$(find "$THEME_DIR/wallpapers" -type f | shuf -n 1)
else
  WALLPAPER="$THEME_DIR/wallpaper.jpg"
  [[ -f "$WALLPAPER" ]] || WALLPAPER="$DEFAULT_WALL"
fi

# Start hyprpaper
if ! hyprctl hyprpaper status >/dev/null 2>&1; then
  hyprpaper &>/dev/null &
  sleep 1
fi

# Apply wallpaper
hyprctl hyprpaper unload all >/dev/null 2>&1 || true
hyprctl hyprpaper preload "$WALLPAPER" >/dev/null 2>&1 || true
while read -r MON; do
  hyprctl hyprpaper wallpaper "$MON,$WALLPAPER" >/dev/null 2>&1 || true
done < <(hyprctl monitors | awk '/^Monitor /{print $2}')

[[ ! -f "$WALLPAPER" ]] && WALLPAPER="$DEFAULT_WALL"

# Symlink for hyprlock
mkdir -p ~/.cache
ln -sf "$WALLPAPER" ~/.cache/current_wallpaper

# 7. RESTART & NOTIFY
# pkill -USR2 waybar 2>/dev/null || true
kill waybar && 
waybar  & 
hyprctl reload
echo "$NEXT" > "$STATE_FILE"
notify-send "Theme switched to: $THEME" "Wallpaper: $(basename "$WALLPAPER")"
