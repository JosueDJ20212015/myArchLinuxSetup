# Cambios de sistema — rebrandeo cosmético Garuda → Arch Linux

> Este archivo documenta cambios hechos **fuera de `~`** (o decisiones de
> NO hacerlos) durante el intento de rebrandeo cosmético de Garuda Linux a
> "Arch Linux" en la terminal. Los dotfiles normales no capturan `/etc` ni
> `/usr`, así que esta es la única forma de no perder este contexto en una
> reinstalación/migración.
>
> Alcance: **puramente cosmético**. En ningún momento se desinstalaron
> paquetes `garuda-*` ni se cambiaron repos de pacman.

Fecha: 2026-09-10

## Resumen

Objetivo real: que `fastfetch` muestre "Arch Linux" en vez de "Garuda Linux"
al abrir una terminal. **Se logró completamente sin tocar nada fuera de
`~/.config`.** Las fases que tocaban archivos de sistema (`/usr/lib/os-release`,
`/etc/lsb-release`, `/etc/default/grub`, SDDM, Plymouth) se investigaron pero
se decidió **no aplicarlas**, por el riesgo de reversión silenciosa descrito
abajo. Se documentan igual para no repetir la investigación si en el futuro
se decide continuar.

## Aplicado: fastfetch (dentro de `~`, fuera del alcance de este doc pero anotado por completitud)

Archivo: `~/.config/fastfetch/config.jsonc` (no versionado en este repo de
dotfiles todavía — si quieres que sobreviva una reinstalación, hay que
agregarlo a `~/.dotfiles/.config/fastfetch/`).

Cambios:
- `logo.source` = `"arch"` (logo built-in de Arch Linux), con
  `logo.color.1` y `logo.color.2` en `#33ccff` (paleta cyan/teal del resto
  de la config).
- Módulo `os` cambiado de string simple a objeto con
  `"format": "Arch Linux {arch}"`, para que ignore el `NAME`/`PRETTY_NAME`
  de `/etc/os-release` (que sigue diciendo "Garuda Linux") y siempre
  muestre "Arch Linux x86_64".

Backup local: `~/.config/fastfetch/config.jsonc.bak-20260910`.

Reproducir en instalación limpia:
```sh
mkdir -p ~/.config/fastfetch
fastfetch --gen-config   # genera un config.jsonc base si no existe
```
Luego editar `~/.config/fastfetch/config.jsonc`:
```jsonc
"logo": {
    "source": "arch",
    "color": { "1": "#33ccff", "2": "#33ccff" }
},
```
y cambiar la entrada `"os"` del array `modules` por:
```jsonc
{ "type": "os", "format": "Arch Linux {arch}" }
```

## Investigado, NO aplicado: `/etc/os-release` y `/etc/lsb-release`

### El symlink

`/etc/os-release` es un symlink a `../usr/lib/os-release`. El archivo real
a editar sería `/usr/lib/os-release`, propiedad del paquete `filesystem`
(paquete base de Arch). Contenido actual (Garuda):

```
NAME="Garuda Linux"
PRETTY_NAME="Garuda Linux"
ID=garuda
ID_LIKE=arch
BUILD_ID=rolling
ANSI_COLOR="38;2;23;147;209"
HOME_URL="https://garudalinux.org/"
DOCUMENTATION_URL="https://wiki.garudalinux.org/"
SUPPORT_URL="https://forum.garudalinux.org/"
BUG_REPORT_URL="https://gitlab.com/groups/garuda-linux/"
PRIVACY_POLICY_URL="https://terms.archlinux.org/docs/privacy-policy/"
LOGO=garudalinux
```

`pacman -Qkk filesystem` marca este archivo con mismatch de tamaño/checksum:
ya diverge del paquete original (Garuda lo sobrescribió al instalar el
sistema), pero **no está en la lista de "Backup Files" del paquete
`filesystem`** (`pacman -Qii filesystem`). Esto es relevante para lo
siguiente.

### Por qué `NoUpgrade` en `pacman.conf` NO protegería el cambio

La idea original era añadir `NoUpgrade = usr/lib/os-release` a
`/etc/pacman.conf` para que pacman no pisara el archivo al actualizar
`filesystem`. **Esto no habría funcionado**, porque el mecanismo real que
mantiene el branding Garuda no es la extracción del paquete — es un **hook
de pacman** que corre `sed -i` sobre el archivo después de la transacción,
sin importar `NoUpgrade`:

- `/usr/share/libalpm/hooks/20-os-release.hook` (paquete `garuda-hooks`):
  se dispara `PostTransaction` al instalar/actualizar el paquete
  **`filesystem`**. Ejecuta
  `/usr/share/libalpm/scripts/garuda-hooks-runner filesystem`, cuya
  función `Filesystem()` hace `sed -i` sobre `/usr/lib/os-release`
  reescribiendo `NAME`, `PRETTY_NAME`, `ID`, `ID_LIKE`, `BUILD_ID`,
  `HOME_URL`, `DOCUMENTATION_URL`, `SUPPORT_URL`, `BUG_REPORT_URL`, `LOGO`
  de vuelta a los valores de Garuda, y además reemplaza `Arch`→`Garuda` en
  `/etc/issue` y `/usr/share/factory/etc/issue`.
- `/usr/share/libalpm/hooks/20-lsb-release.hook` (mismo paquete): igual
  pero para `/etc/lsb-release`, disparado al actualizar el paquete
  `lsb-release`. Reescribe `DISTRIB_ID`, `DISTRIB_RELEASE`,
  `DISTRIB_CODENAME`, `DISTRIB_DESCRIPTION`.
- `/usr/share/libalpm/hooks/garuda-hooks-runner.hook`: corre **ambas**
  funciones (`Filesystem` + `Lsb_release`) sin condición cada vez que se
  actualiza el propio paquete `garuda-hooks`.

Conclusión: cualquier edición manual a estos dos archivos se revertiría
solo silenciosamente la próxima vez que `pacman -Syu` actualice
`filesystem`, `lsb-release` o `garuda-hooks` (en un rolling release, pasa
con cierta frecuencia impredecible).

### ¿Rompe esto a `garuda-update`?

No. Se revisaron los scripts de `garuda-update`
(`/usr/bin/garuda-update`, `/usr/lib/garuda/garuda-update/main-update`,
`auto-pacman`, `update-helper-scripts`) y **ninguno lee ni depende del
contenido de `/etc/os-release`** — la lógica de actualización se descarga
en caliente desde `garudalinux.org` en cada ejecución. Cambiar `os-release`
no rompería `garuda-update` funcionalmente; solo se revertiría el
cosmético.

### Si en el futuro se decide continuar

Opciones evaluadas (ninguna aplicada):
1. **Hook contrarrestante**: agregar un hook propio en
   `/etc/pacman.d/hooks/` (mecanismo estándar de pacman para hooks de
   usuario — no toca ningún archivo de paquete) con los mismos triggers
   (`Target = filesystem`, `Target = lsb-release`, `Target = garuda-hooks`)
   pero numerado para correr después de `20-os-release.hook`/
   `20-lsb-release.hook`, reaplicando el branding Arch. Auto-sanador.
2. **Edición manual sin protección**: aceptar que se revertirá
   eventualmente y volver a aplicar el `sed` cuando se note.
3. Se descartó tocar `garuda-hooks-runner.hook` o los hooks de
   `garuda-hooks` directamente por ser archivos de paquete (se
   sobrescriben en cada actualización de `garuda-hooks`, y modificarlos
   cuenta como "romper" el paquete).

**Decisión tomada (2026-09-10): no aplicar ninguna.** El objetivo real
(verlo en fastfetch) ya se cumplió sin tocar archivos de sistema.

## No auditado: Fase 3 (GRUB / SDDM / Plymouth)

Se saltó por decisión explícita, dado que el objetivo cosmético ya estaba
cumplido. Dato de contexto encontrado de paso (vía
`/etc/garuda/garuda-config-agent/grub.yaml`, gestionado por
`garuda-config-agent`): ese pipeline fuerza
`GRUB_DISTRIBUTOR="Arch"` → `GRUB_DISTRIBUTOR="Garuda"` en
`/etc/default/grub` cada vez que se toca `/etc/*` en una transacción de
pacman (mismo patrón de "hook que revierte cambios manuales" que en
os-release). Cualquier intento futuro de tocar GRUB debería auditar este
mecanismo primero, igual que se hizo aquí con os-release.

## Paquetes `garuda-*` instalados (referencia, ninguno desinstalado)

```
garuda-bash-config, garuda-browser-settings, garuda-common-settings,
garuda-config-agent, garuda-dracut-support, garuda-fish-config,
garuda-hardware-profile-standard, garuda-hardware-tool, garuda-health,
garuda-hooks, garuda-hyprland-settings, garuda-icons, garuda-libs,
garuda-migrations, garuda-network-assistant, garuda-setup-assistant,
garuda-starship-prompt, garuda-system-maintenance, garuda-toolbox,
garuda-update, garuda-wallpapers, garuda-zsh-config, grub-garuda,
grub-theme-garuda
```
