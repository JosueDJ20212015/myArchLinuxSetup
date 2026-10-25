#!/bin/bash

# Terminal desplegable (Super + tecla de arriba a la izquierda).
# La primera vez abre kitty en el workspace especial "dropterm" (las reglas de
# hyprland.lua la ponen flotante debajo de la barra); despues solo la muestra
# u oculta, conservando lo que tenias escrito.

if hyprctl clients -j | jq -e '.[] | select(.class == "dropterm")' >/dev/null; then
    hyprctl dispatch 'hl.dsp.workspace.toggle_special("dropterm")' >/dev/null
else
    setsid -f kitty --class dropterm >/dev/null 2>&1
fi
