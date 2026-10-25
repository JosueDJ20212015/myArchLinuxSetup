#!/bin/bash

# Contenedores Docker corriendo. Waybar oculta el modulo si no hay ninguno
# (o si Docker no esta disponible).

LISTA=$(docker ps --format '{{.Names}}\t{{.Status}}' 2>/dev/null) || LISTA=""

if [ -z "$LISTA" ]; then
    echo '{"text": ""}'
    exit 0
fi

CANTIDAD=$(grep -c . <<< "$LISTA")
TOOLTIP=$(awk -F'\t' '{printf "%s  ·  %s\n", $1, $2}' <<< "$LISTA")
TOOLTIP+=$'\nClic para ver los contenedores'

jq -nc --arg t "󰡨 $CANTIDAD" --arg tt "$TOOLTIP" '{text: $t, tooltip: $tt}'
