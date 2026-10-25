#!/bin/bash

# "No me gusta" (Super + Shift + W): borra el wallpaper actual si es uno
# descargado de internet y pasa al siguiente. Los wallpapers propios
# (fuera de Wallpapers/online) nunca se borran, solo se saltan.

CACHE_DIR="$HOME/Pictures/Wallpapers/online"

ACTUAL=$(awww query | grep -oP 'image: \K.*' | head -n 1)

# Pasar al siguiente primero, para no quedarse con la pantalla sin fondo
~/.local/bin/cambiarWallpaperOnline.sh || ~/.local/bin/cambiarWallpaper.sh

if [ -n "$ACTUAL" ] && [ "$(dirname -- "$ACTUAL")" = "$CACHE_DIR" ] && [ -f "$ACTUAL" ]; then
    rm -f -- "${CACHE_DIR:?}/$(basename -- "${ACTUAL:?}")"
    notify-send -a wallpaper -t 2000 "󰋩  Wallpaper descartado" "$(basename -- "$ACTUAL")"
else
    notify-send -a wallpaper -t 2000 "󰋩  Wallpaper saltado" "Es de tu colección, no se borra"
fi
