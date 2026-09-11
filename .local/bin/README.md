# Scripts personales

Scripts de uso diario y de primer arranque para esta configuración de Hyprland.

## De uso diario

* **`cambiarWallpaper.sh`** — Aplica un wallpaper aleatorio de `~/Pictures/Wallpapers/` con una transición aleatoria (`awww`).
* **`wallpaper-loop.sh`** — Corre `cambiarWallpaper.sh` cada 30s en bucle. Se lanza con `exec-once = wallpaper-loop.sh` en `hyprland.conf`.
* **`nmtui-colors`** — Wrapper de `nmtui` con un esquema de color propio (blanco sobre rojo).
* **`wrappedhl`** — Wrapper para lanzar Hyprland con variables de entorno (cursor, soporte IME con fcitx, logging de WLR).

## De primer arranque (se autodesactivan)

* **`garuda-locale.sh`** — Configura `kb_layout` en `hyprland.conf` según el teclado detectado por `localectl`. Al terminar, comenta su propia línea `exec-once` para no volver a correr.
* **`mon.sh`** — Detecta la configuración de monitores con `hyprctl monitors` y la escribe en `hyprland.conf`. Al terminar, también se autodesactiva.

Si reinstalas y quieres que vuelvan a correr, descomenta su línea `exec-once` correspondiente en `hyprland.conf`.

## Instalador (no forma parte del setup en uso)

* **`calamares.sh`** — Diálogo gráfico para lanzar el instalador Calamares de Garuda Hyprland. Viene del ISO/entorno de instalación, no algo que se ejecute en un sistema ya instalado.
