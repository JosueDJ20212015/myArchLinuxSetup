#!/bin/bash

# "Minimizar" ventanas en Hyprland: se mandan a un escritorio especial oculto
# y se recuerda en que escritorio estaban, para devolverlas ahi.
# Uso: minimizar.sh min [dir]  -> minimiza la ventana enfocada (Super+Shift+M) o la indicada
#      minimizar.sh restaurar  -> restaura la ultima minimizada
#      minimizar.sh elegir     -> elige cual restaurar con wofi
#      minimizar.sh estado     -> JSON para el indicador de Waybar

ESPECIAL="minimizadas"
# Lineas "direccion<TAB>escritorio<TAB>flotante<TAB>x<TAB>y<TAB>ancho<TAB>alto",
# en orden de minimizado
ESTADO="${XDG_RUNTIME_DIR:-/tmp}/minimizadas"
SENAL=8 # pkill -RTMIN+8 waybar refresca el indicador al instante
# Efecto estilo macOS: la ventana se encoge hacia la isla central y se mete debajo
MINI_W=96
MINI_H=54
ANIMACION=0.3 # segundos; windowsMove dura ~0.4 s pero casi todo pasa al inicio

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

despachar() {
    hyprctl dispatch "$1" >/dev/null
}

# Encoge la ventana hasta la mitad de arriba del monitor (debajo de la isla central)
encoger() {
    local dir=$1 monitor=$2 mx mw x
    read -r mx mw < <(hyprctl monitors -j | jq -r --argjson m "$monitor" \
        '.[] | select(.id == $m) | [.x, .width] | @tsv')
    x=$((mx + mw / 2 - MINI_W / 2))
    despachar "hl.dsp.window.resize({ x = $MINI_W, y = $MINI_H, window = \"address:$dir\" })"
    despachar "hl.dsp.window.move({ x = $x, y = 0, window = \"address:$dir\" })"
}

restaurar() {
    local dir=$1 ws flotante x y w h monitor
    IFS=$'\t' read -r _ ws flotante x y w h < <(grep -F "$dir" "$ESTADO" | tail -n 1)
    # Si no se sabe de donde vino, va al escritorio actual
    [ -z "$ws" ] && ws=$(hyprctl activeworkspace -j | jq -r .id)
    # Monitor del escritorio destino (si ya no existe, el monitor enfocado)
    monitor=$(hyprctl workspaces -j | jq -r --argjson ws "$ws" '.[] | select(.id == $ws) | .monitor_id')
    [ -z "$monitor" ] && monitor=$(hyprctl activeworkspace -j | jq -r .monitor_id)
    # Sale chiquita desde la isla central y crece hasta su lugar
    encoger "$dir" "$monitor"
    despachar "hl.dsp.window.move({ workspace = $ws, follow = false, window = \"address:$dir\" })"
    if [ "$flotante" = "false" ]; then
        despachar "hl.dsp.window.float({ action = \"disable\", window = \"address:$dir\" })"
    elif [ -n "$w" ]; then
        despachar "hl.dsp.window.resize({ x = $w, y = $h, window = \"address:$dir\" })"
        despachar "hl.dsp.window.move({ x = $x, y = $y, window = \"address:$dir\" })"
    fi
    despachar "hl.dsp.focus({ window = \"address:$dir\" })"
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
        # Por defecto la ventana enfocada; "min <direccion>" minimiza otra
        if [ -n "$2" ]; then
            ventana=$(hyprctl clients -j | jq --arg d "$2" '.[] | select(.address == $d)')
        else
            ventana=$(hyprctl activewindow -j)
        fi
        IFS=$'\t' read -r dir ws nombre monitor flotante x y w h < <(jq -r '[.address, .workspace.id, .workspace.name, .monitor, .floating, .at[0], .at[1], .size[0], .size[1]] | @tsv' <<< "$ventana")
        # Nada enfocado, o ya esta en un escritorio especial (p. ej. la terminal desplegable)
        [ -z "$dir" ] || [ "$dir" = "null" ] || [[ $nombre == special:* ]] && exit 0
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$dir" "$ws" "$flotante" "$x" "$y" "$w" "$h" >> "$ESTADO"
        # Flotante para poder encogerla; las demas ventanas se reacomodan a la vez
        despachar "hl.dsp.window.float({ action = \"enable\", window = \"address:$dir\" })"
        encoger "$dir" "$monitor"
        sleep "$ANIMACION"
        despachar "hl.dsp.window.move({ workspace = \"special:$ESPECIAL\", follow = false, window = \"address:$dir\" })"
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
