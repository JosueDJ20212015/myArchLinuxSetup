# astronaut-ejr

Tema de GRUB. Base: `astronaut-catppuccin 1.02`, readaptado a la paleta
Arch Blue (`#33ccff`) con acentos ámbar (`#FFB300`).

## Cambios respecto al original

- `background.png` reemplazado por la imagen EJR (1920x1080, resolución nativa,
  sin reescalar; el lienzo se extendió con el color de borde `#00060D`)
- Panel de cristal recoloreado de negro a azul marino `#040E16`, opacidad 49% -> 57%
- Texto de los ítems: `#CDD6F4` -> `#7FDFFF`
- Ítem seleccionado: `#CDD6F4` -> `#FFB300` (ámbar, igual que el cursor Neon Amber Glass)
- Barra del ítem seleccionado recoloreada a cian oscuro `#0B2A3A`
- Barra de progreso: relleno `#0E5A73`, fondo `#00060D`
- Texto de cuenta atrás traducido al español
- `desktop-image-scale-method` cambiado de `stretch` a `crop`
- Añadido `icons/garuda.png` (copia de `arch.png`) — Garuda reporta `ID=garuda`
  y GRUB busca ese nombre exacto

## Instalación

    sudo mkdir -p /boot/grub/themes
    sudo cp -r astronaut-ejr /boot/grub/themes/

En `/etc/default/grub`:

    GRUB_THEME="/boot/grub/themes/astronaut-ejr/theme.txt"
    GRUB_GFXMODE=1920x1080x32
    GRUB_GFXPAYLOAD_LINUX=keep

Y regenerar:

    sudo grub-mkconfig -o /boot/grub/grub.cfg

## Nota sobre actualizaciones

`/boot/grub/themes/` no pertenece a ningún paquete, así que el tema sobrevive
a las actualizaciones de Garuda. `/etc/default/grub` **sí** pertenece a un
paquete: revisa el `.pacnew` con `pacdiff` tras cada actualización.
