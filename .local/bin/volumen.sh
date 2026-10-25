#!/bin/bash

# Sube/baja/silencia el volumen o el microfono y muestra UNA sola notificacion
# que se va actualizando (--replace-id), con barra de progreso.
# Uso: volumen.sh up | down | mute | mic

# mako asigna el ID de cada notificacion; se guarda para reemplazarla en la
# siguiente pulsacion en vez de apilar otra
ESTADO="${XDG_RUNTIME_DIR:-/tmp}"

# notificar <archivo-id> <notify-send args...>
notificar() {
    local archivo="$ESTADO/$1" id
    shift
    id=$(cat "$archivo" 2>/dev/null)
    notify-send -p -a volumen -r "${id:-0}" -t 1500 "$@" > "$archivo"
}

notificar_volumen() {
    local vol
    vol=$(pamixer --get-volume)
    if [ "$(pamixer --get-mute)" = "true" ]; then
        notificar volumen.id -h int:value:0 "󰝟  Volumen" "Silenciado"
    else
        notificar volumen.id -h int:value:"$vol" "󰕾  Volumen" "$vol %"
    fi
}

case "$1" in
    up)
        pamixer --increase 5
        # Tope explicito en 100 % por si otra app (p. ej. pavucontrol) lo subio
        [ "$(pamixer --get-volume)" -gt 100 ] && pamixer --set-volume 100
        notificar_volumen
        ;;
    down) pamixer --decrease 5; notificar_volumen ;;
    mute) pamixer --toggle-mute; notificar_volumen ;;
    mic)
        pactl set-source-mute @DEFAULT_SOURCE@ toggle
        if [ "$(pamixer --default-source --get-mute)" = "true" ]; then
            notificar mic.id "󰍭  Micrófono" "Silenciado"
        else
            notificar mic.id "󰍬  Micrófono" "Activado"
        fi
        ;;
    *) echo "Uso: $0 up | down | mute | mic" >&2; exit 1 ;;
esac
