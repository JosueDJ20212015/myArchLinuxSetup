#!/bin/bash

# "Minimizar" ventanas en Hyprland: se mandan a un escritorio especial oculto
# y se recuerda en que escritorio estaban, para devolverlas ahi.
# Uso: minimizar.sh min        -> minimiza la ventana enfocada (Super+Shift+M)
#      minimizar.sh restaurar  -> restaura la ultima minimizada
#      minimizar.sh elegir     -> elige cual restaurar con wofi
#      minimizar.sh estado     -> JSON para el indicador de Waybar

ESPECIAL="minimizadas"
# Lineas "direccion<TAB>escritorio", en orden de minimizado
ESTADO="${XDG_RUNTIME_DIR:-/tmp}/minimizadas"
SENAL=8 # pkill -RTMIN+8 waybar refresca el indicador al instante

touch "$ESTADO"

# Ventanas que siguen en el escritorio oculto: direccion<TAB>clase<TAB>titulo
minimizadas() {
    hyprctl clients -j | jq -r --arg ws "special:$ESPECIAL" \
        '.[] | select(.workspace.name == $ws) | [.address, .class, .title] | @tsv'
}

# Olvida las ventanas que ya no estan minimizadas (cerradas o movidas a mano)
limpiar() {
    local vivas
    vivas=$(minimizadas | cut -f1)
    grep -F -f <(printf '%s\n' "${vivas:-NINGUNA}") "$ESTADO" > "$ESTADO.tmp"
    mv "$ESTADO.tmp" "$ESTADO"
}

refrescar() {
    pkill -RTMIN+$SENAL waybar
}

restaurar() {
    local dir=$1 ws
    ws=$(grep -F "$dir" "$ESTADO" | tail -n 1 | cut -f2)
    # Si no se sabe de donde vino, va al escritorio actual
    [ -z "$ws" ] && ws=$(hyprctl activeworkspace -j | jq -r .id)
    hyprctl dispatch "hl.dsp.window.move({ workspace = $ws, follow = false, window = \"address:$dir\" })" >/dev/null
    hyprctl dispatch "hl.dsp.focus({ window = \"address:$dir\" })" >/dev/null
    grep -vF "$dir" "$ESTADO" > "$ESTADO.tmp"
    mv "$ESTADO.tmp" "$ESTADO"
    refrescar
}

icono() {
    case "${1,,}" in
        kitty | dropterm | foot | alacritty) echo "" ;;
        firefox | firedragon | chromium | brave*) echo "󰈹" ;;
        code | code-oss | vscodium) echo "󰨞" ;;
        thunar | ranger | nemo) echo "" ;;
        spotify) echo "󰓇" ;;
        discord | vesktop) echo "󰙯" ;;
        *) echo "󰖯" ;;
    esac
}

case "$1" in
    min)
        read -r dir ws nombre < <(hyprctl activewindow -j |
            jq -r '[.address, .workspace.id, .workspace.name] | @tsv')
        # Nada enfocado, o ya esta en un escritorio especial (p. ej. la terminal desplegable)
        [ -z "$dir" ] || [ "$dir" = "null" ] || [[ $nombre == special:* ]] && exit 0
        printf '%s\t%s\n' "$dir" "$ws" >> "$ESTADO"
        hyprctl dispatch "hl.dsp.window.move({ workspace = \"special:$ESPECIAL\", follow = false, window = \"address:$dir\" })" >/dev/null
        refrescar
        ;;
    restaurar)
        limpiar
        dir=$(tail -n 1 "$ESTADO" | cut -f1)
        [ -z "$dir" ] && dir=$(minimizadas | tail -n 1 | cut -f1)
        [ -n "$dir" ] && restaurar "$dir"
        ;;
    elegir)
        limpiar
        lista=$(minimizadas)
        [ -z "$lista" ] && exit 0
        if [ "$(grep -c . <<< "$lista")" -eq 1 ]; then
            restaurar "$(cut -f1 <<< "$lista")"
            exit 0
        fi
        elegido=$(while IFS=$'\t' read -r dir clase titulo; do
            printf '%s  %s — %s\t%s\n' "$(icono "$clase")" "$clase" "$titulo" "$dir"
        done <<< "$lista" | wofi --dmenu --prompt "Restaurar" | cut -f2)
        [ -n "$elegido" ] && restaurar "$elegido"
        ;;
    estado)
        limpiar
        lista=$(minimizadas)
        if [ -z "$lista" ]; then
            echo '{"text": ""}'
            exit 0
        fi
        texto=""
        tooltip=""
        while IFS=$'\t' read -r dir clase titulo; do
            texto+="$(icono "$clase") "
            tooltip+="$clase — $titulo"$'\n'
        done <<< "$lista"
        tooltip+="Clic: restaurar la última · Clic derecho: elegir"
        jq -nc --arg t "${texto% }" --arg tt "$tooltip" '{text: $t, tooltip: $tt}'
        ;;
    *)
        echo "Uso: $0 min | restaurar | elegir | estado" >&2
        exit 1
        ;;
esac
