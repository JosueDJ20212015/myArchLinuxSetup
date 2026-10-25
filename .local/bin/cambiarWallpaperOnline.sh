#!/bin/bash

# Descarga un wallpaper oscuro de Wallhaven y lo aplica.
# Sale con error si no hay internet o no encuentra uno adecuado;
# wallpaper-loop.sh entonces usa cambiarWallpaper.sh con los ya descargados.

API="${WALLHAVEN_API:-https://wallhaven.cc/api/v1/search}"

# Se guardan dentro de Wallpapers/ para que el modo sin internet tambien los use
CACHE_DIR="$HOME/Pictures/Wallpapers/online"
MAX_CACHE=30

# Temas de busqueda (uno al azar en cada cambio)
TERMS=("samurai" "ninja" "silhouette" "katana" "anime" "amoled" "minimalist" "dark" "night city" "dragon")

# Colores dominantes de Wallhaven: negro y gris oscuro
COLORS=("000000" "424153")

# Limites para que combine con las islas (0-100)
MAX_LUZ=28
MAX_SATURACION=55

# Array de transiciones disponibles
TRANSITIONS=("fade" "wipe" "grow" "outer" "wave")

mkdir -p "$CACHE_DIR"

TERM_Q=${TERMS[$RANDOM % ${#TERMS[@]}]}
COLOR=${COLORS[$RANDOM % ${#COLORS[@]}]}

# categories=110: general + anime, purity=100: solo SFW
URLS=$(curl -sfG --max-time 10 "$API" \
    --data-urlencode "q=$TERM_Q" \
    -d categories=110 -d purity=100 -d sorting=random \
    -d colors="$COLOR" -d ratios=16x9 \
    -d resolutions=1920x1080,2560x1440,3840x2160 |
    jq -r '.data[].path' 2>/dev/null | shuf -n 5)

[ -z "$URLS" ] && exit 1

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

for URL in $URLS; do
    FILE="$TMP/$(basename "$URL")"
    curl -sf --max-time 30 -o "$FILE" "$URL" || continue

    # Brillo (L) y saturacion (S) promedio en HSL
    read -r LUZ SAT < <(magick "$FILE" -resize 64x64! -colorspace HSL \
        -format "%[fx:int(mean.b*100)] %[fx:int(mean.g*100)]" info: 2>/dev/null)
    [ -z "$LUZ" ] && continue
    [ "$LUZ" -gt "$MAX_LUZ" ] || [ "$SAT" -gt "$MAX_SATURACION" ] && continue

    WALLPAPER="$CACHE_DIR/$(basename "$URL")"
    mv "$FILE" "$WALLPAPER"

    # Borrar los mas viejos si hay demasiados (solo dentro de CACHE_DIR;
    # ${VAR:?} aborta en vez de borrar si alguna variable quedara vacia)
    ls -1t "$CACHE_DIR" | tail -n +$((MAX_CACHE + 1)) | while read -r OLD; do
        rm -f -- "${CACHE_DIR:?}/${OLD:?}"
    done

    TRANSITION=${TRANSITIONS[$RANDOM % ${#TRANSITIONS[@]}]}

    # Misma curva ease-out que las animaciones de Hyprland
    awww img "$WALLPAPER" --transition-type "$TRANSITION" --transition-duration 2 \
        --transition-bezier .23,1,.32,1 --transition-fps 60
    exit 0
done

exit 1
