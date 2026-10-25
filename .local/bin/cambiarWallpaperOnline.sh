#!/bin/bash

# Descarga un wallpaper oscuro de Wallhaven y lo aplica.
# Sale con error si no hay internet o no encuentra uno adecuado;
# wallpaper-loop.sh entonces usa cambiarWallpaper.sh con los ya descargados.

API="${WALLHAVEN_API:-https://wallhaven.cc/api/v1/search}"

# Se guardan dentro de Wallpapers/ para que el modo sin internet tambien los use
CACHE_DIR="$HOME/Pictures/Wallpapers/online"
MAX_CACHE=30

# Estilos (se turnan al azar): dark samurai, dark naturaleza, naturaleza neon
DARK_SAMURAI=("dark samurai" "samurai silhouette" "samurai" "katana" "ronin")
DARK_NATURALEZA=("dark forest" "dark nature" "misty forest" "night lake" "dark mountains")
NATURALEZA_NEON=("neon landscape" "neon nature" "cyberpunk nature" "neon mountains" "synthwave landscape")

# Limites para que combine con las islas (0-100)
MAX_LUZ=28
MAX_SATURACION=55

# Array de transiciones disponibles
TRANSITIONS=("fade" "wipe" "grow" "outer" "wave")

mkdir -p "$CACHE_DIR"

# Colores dominantes de Wallhaven: negro o gris oscuro
DARK_COLORS=("000000" "424153")
DARK_COLOR=${DARK_COLORS[$RANDOM % ${#DARK_COLORS[@]}]}

case $((RANDOM % 3)) in
    0) TERMS=("${DARK_SAMURAI[@]}"); COLOR_ARGS=(-d colors="$DARK_COLOR") ;;
    1) TERMS=("${DARK_NATURALEZA[@]}"); COLOR_ARGS=(-d colors="$DARK_COLOR") ;;
    # El neon tiene color: sin filtro de color, mas saturacion permitida,
    # pero igual tiene que ser oscuro
    2) TERMS=("${NATURALEZA_NEON[@]}"); COLOR_ARGS=(); MAX_SATURACION=75; MAX_LUZ=30 ;;
esac
TERM_Q=${TERMS[$RANDOM % ${#TERMS[@]}]}

# categories=110: general + anime, purity=100: solo SFW
# sorting=favorites: los mas guardados suelen ser mas fieles a la busqueda
buscar() {
    curl -sfG --max-time 10 "$API" \
        --data-urlencode "q=$TERM_Q" \
        -d categories=110 -d purity=100 -d sorting=favorites -d page="$1" \
        "${COLOR_ARGS[@]}" -d ratios=16x9 \
        -d resolutions=1920x1080,2560x1440,3840x2160
}

# Pagina al azar entre las primeras 5 que existan
RESPUESTA=$(buscar 1) || exit 1
PAGINAS=$(jq -r '.meta.last_page // 1' <<< "$RESPUESTA")
[ "$PAGINAS" -gt 5 ] && PAGINAS=5
PAGINA=$((RANDOM % PAGINAS + 1))
[ "$PAGINA" -gt 1 ] && { RESPUESTA=$(buscar "$PAGINA") || exit 1; }

URLS=$(jq -r '.data[].path' <<< "$RESPUESTA" 2>/dev/null | shuf -n 5)

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
