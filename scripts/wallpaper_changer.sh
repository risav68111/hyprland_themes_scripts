#!/usr/bin/env bash
# ------------------------------------------------------------
# apply-wallpaper  –  sequential + remember last wallpaper per theme
# ------------------------------------------------------------
set -euo pipefail

export PATH="$PATH:/usr/bin:/usr/local/bin"
export XDG_RUNTIME_DIR="/run/user/$UID"

STATE_FILE="$HOME/.config/hypr/.current_theme"
THEMES_DIR="$HOME/.config/themes"
WALL_STATE_DIR="$HOME/.cache/theme-wallpaper-state"   # <-- NEW
DEFAULT_WALL="$HOME/.config/hypr/default_wallpaper.jpg"

# ---------- ensure hyprpaper ----------
if ! hyprctl hyprpaper status >/dev/null 2>&1; then
    hyprpaper &>/dev/null &
    sleep 1
fi

# ---------- read current theme ----------
[[ -f "$STATE_FILE" ]] || { echo "Error: No current theme found!"; exit 1; }
THEME_INDEX=$(<"$STATE_FILE")
THEME_NAME=$(ls -1 "$THEMES_DIR" | sed -n "$((THEME_INDEX + 1))p")
THEME_DIR="$THEMES_DIR/$THEME_NAME"

# ---------- wallpaper source ----------
mkdir -p "$WALL_STATE_DIR"
STATE_FOR_THEME="$WALL_STATE_DIR/$THEME_NAME"

if [[ -d "$THEME_DIR/wallpapers" && -n "$(ls -A "$THEME_DIR/wallpapers")" ]]; then
    WALL_DIR="$THEME_DIR/wallpapers"
else
    WALL_DIR="$THEME_DIR"
    [[ -f "$WALL_DIR/wallpaper.jpg" ]] || WALL_DIR=""
fi

# ---------- pick next wallpaper ----------
if [[ -z "$WALL_DIR" ]]; then
    WALLPAPER="$DEFAULT_WALL"
else
    # Build a sorted list (deterministic order)
    mapfile -t WALLS < <(find "$WALL_DIR" -type f -print0 | xargs -0 -n1 basename | sort)
    if [[ ${#WALLS[@]} -eq 0 ]]; then
        WALLPAPER="$DEFAULT_WALL"
    else
        # Last used index (0-based)
        if [[ -f "$STATE_FOR_THEME" ]]; then
            IDX=$(<"$STATE_FOR_THEME")
        else
            IDX=-1
        fi
        IDX=$(( (IDX + 1) % ${#WALLS[@]} ))
        NEXT_WALL="${WALLS[$IDX]}"
        WALLPAPER="$(find "$WALL_DIR" -type f -name "$NEXT_WALL" | head -n1)"
        echo "$IDX" > "$STATE_FOR_THEME"   # remember for next time
    fi
fi

# ---------- fallback ----------
[[ -f "$WALLPAPER" ]] || WALLPAPER="$DEFAULT_WALL"

# ---------- cache for hyprlock ----------
mkdir -p ~/.cache
ln -sf "$WALLPAPER" ~/.cache/current_wallpaper

# ---------- apply ----------
hyprctl hyprpaper unload all >/dev/null 2>&1 || true
hyprctl hyprpaper preload "$WALLPAPER" >/dev/null 2>&1 || true
while read -r MON; do
    hyprctl hyprpaper wallpaper "$MON,$WALLPAPER" >/dev/null 2>&1 || true
done < <(hyprctl monitors | awk '/^Monitor /{print $2}')

echo "Wallpaper → $THEME_NAME : $(basename "$WALLPAPER")"
