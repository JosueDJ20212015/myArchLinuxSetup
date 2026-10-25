#!/bin/bash

# Sube/baja el brillo y muestra UNA sola notificacion que se va actualizando
# (--replace-id), con barra de progreso. Mismo estilo que volumen.sh.
# Uso: brillo.sh up | down

# Nunca por debajo de este % (con la pantalla en negro no se puede volver a subir)
MINIMO=5
PASO=5

# mako asigna el ID de cada notificacion; se guarda para reemplazarla en la
# siguiente pulsacion en vez de apilar otra
ARCHIVO_ID="${XDG_RUNTIME_DIR:-/tmp}/brillo.id"

actual() {
    brightnessctl -c backlight -m | cut -d, -f4 | tr -d '%'
}

case "$1" in
    up) brightnessctl -c backlight -q set "+$PASO%" ;;
    down)
        if [ "$(actual)" -le $((MINIMO + PASO)) ]; then
            brightnessctl -c backlight -q set "$MINIMO%"
        else
            brightnessctl -c backlight -q set "$PASO%-"
        fi
        ;;
    *) echo "Uso: $0 up | down" >&2; exit 1 ;;
esac

PCT=$(actual)
ID=$(cat "$ARCHIVO_ID" 2>/dev/null)
notify-send -p -a brillo -r "${ID:-0}" -t 1500 -h int:value:"$PCT" \
    "󰃠  Brillo" "$PCT %" > "$ARCHIVO_ID"
