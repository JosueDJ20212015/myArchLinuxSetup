#!/bin/bash

# Cambia el wallpaper cada 5 minutos.
# Primero intenta uno nuevo de internet; sin conexion usa los descargados.
while true; do
    ~/.local/bin/cambiarWallpaperOnline.sh || ~/.local/bin/cambiarWallpaper.sh
    sleep 300
done
