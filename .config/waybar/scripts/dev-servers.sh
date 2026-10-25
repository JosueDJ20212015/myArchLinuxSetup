#!/bin/bash

# Servidores de desarrollo en escucha. Waybar oculta el modulo si no hay ninguno.
# Uso: dev-servers.sh        -> JSON para Waybar
#      dev-servers.sh abrir  -> abre uno en el navegador (elige con wofi si hay varios)

# Puertos tipicos de desarrollo: Vite/Next/React/Flask (3000-5999),
# Django/Spring/Express (8000-8999), Hugo (1313), Storybook (6006)
es_dev() {
    local p=$1
    { [ "$p" -ge 3000 ] && [ "$p" -le 5999 ]; } ||
        { [ "$p" -ge 8000 ] && [ "$p" -le 8999 ]; } ||
        [ "$p" -eq 1313 ] || [ "$p" -eq 6006 ]
}

declare -A PROCESO
while read -r direccion info; do
    puerto=${direccion##*:}
    [[ $puerto =~ ^[0-9]+$ ]] || continue
    es_dev "$puerto" || continue
    # Solo se ve el nombre de los procesos propios (los de root salen como "?")
    nombre=$(grep -oP 'users:\(\("\K[^"]+' <<< "$info")
    PROCESO[$puerto]=${nombre:-?}
done < <(ss -tlnpH | awk '{print $4, $6}')

mapfile -t PUERTOS < <(printf '%s\n' "${!PROCESO[@]}" | grep . | sort -n)

if [ "$1" = "abrir" ]; then
    [ ${#PUERTOS[@]} -eq 0 ] && exit 0
    if [ ${#PUERTOS[@]} -eq 1 ]; then
        elegido=${PUERTOS[0]}
    else
        elegido=$(for p in "${PUERTOS[@]}"; do echo "$p  ${PROCESO[$p]}"; done |
            wofi --dmenu --prompt "Abrir servidor" | cut -d' ' -f1)
    fi
    [ -n "$elegido" ] && xdg-open "http://localhost:$elegido"
    exit 0
fi

if [ ${#PUERTOS[@]} -eq 0 ]; then
    echo '{"text": ""}'
    exit 0
fi

texto="󰒍"
tooltip=""
for p in "${PUERTOS[@]}"; do
    texto+=" :$p"
    tooltip+="localhost:$p  →  ${PROCESO[$p]}\n"
done
tooltip+="Clic para abrir en el navegador"

jq -nc --arg t "$texto" --arg tt "$tooltip" '{text: $t, tooltip: ($tt | gsub("\\\\n"; "\n"))}'
