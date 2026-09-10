#!/bin/bash

# Directorio de wallpapers
WALLPAPER_DIR="$HOME/Pictures/Wallpapers/"

# Array de transiciones disponibles
TRANSITIONS=("fade" "wipe" "grow" "outer" "wave")

# Seleccionar una imagen aleatoria
WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) | shuf -n 1)

# Seleccionar una transición aleatoria
TRANSITION=${TRANSITIONS[$RANDOM % ${#TRANSITIONS[@]}]}

# Aplicar el wallpaper con la transición
swww img "$WALLPAPER" --transition-type "$TRANSITION" --transition-duration 2
