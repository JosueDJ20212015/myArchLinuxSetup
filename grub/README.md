# GRUB — tema de arranque personalizado (astronaut-ejr)

Tema `astronaut-ejr` (fork de `astronaut-catppuccin`, recoloreado a paleta Arch
Blue/ámbar) instalado en `/boot/grub/themes/`, con el paquete que causaba las
roturas eliminado y un fragmento de blindaje en `/etc/default/grub.d/`.

## La causa real (no la que parecía)

El tema se revertía a "Garuda" tras ciertas actualizaciones. La sospecha
inicial era el mismo patrón que en SDDM (pacman sobrescribiendo un archivo sin
`backup=()` declarado). **Era otra cosa.**

`/etc/default/grub` sí es un *Backup File* declarado por el paquete `grub`
(`pacman -Qii grub` lo confirma) — pacman nunca lo sobrescribe en silencio, ahí
genera `.pacnew`. El mecanismo real era el **script de instalación del paquete
`grub-theme-garuda`**, que en su `post_install()`/`post_upgrade()` hacía esto
sin condición alguna, en cada instalación o actualización de ese paquete
específico:

```sh
sed -i -e 's,.*GRUB_THEME=.*,GRUB_THEME="/usr/share/grub/themes/garuda/theme.txt",' /etc/default/grub
sed -i -e 's,.*GRUB_GFXMODE=.*,GRUB_GFXMODE=auto,' /etc/default/grub
sed -i -e 's,.*GRUB_DISTRIBUTOR=.*,GRUB_DISTRIBUTOR="Garuda",' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
```

No verifica si ya hay un valor personalizado — reemplaza cualquier línea que
contenga `GRUB_THEME=`, sin importar el valor anterior, y regenera `grub.cfg`
en el acto. Esto no depende de si el archivo tiene `backup=()` declarado ni de
si vive en una ruta con dueño: es un script que edita el archivo activamente,
por fuera del mecanismo de extracción de paquetes de pacman.

**Evidencia en `/var/log/pacman.log`, la noche del 2026-09-09** (la misma
ventana de mantenimiento que rompió SDDM):

```
[2026-09-09T23:59:08-0600] [ALPM] upgraded grub-theme-garuda (r26.972b17c-2 -> 1.0.0-3)
[2026-09-09T23:59:10-0600] [ALPM-SCRIPTLET] Found theme: /usr/share/grub/themes/garuda/theme.txt
[2026-09-09T23:59:13-0600] [ALPM-SCRIPTLET] ==> Installation: Theme is added to your /etc/default/grub: GRUB_THEME="/usr/share/grub/themes/garuda/theme.txt"
```

Es la **única** actualización de `grub-theme-garuda` en todo el historial de
pacman — explica el revert completo de una sola vez, no gradualmente.

## Las dos capas de blindaje

1. **Causa eliminada:** `grub-theme-garuda` fue desinstalado
   (`pacman -Qi grub-theme-garuda` → *"was not found"*). Verificado que nada
   lo requería (`pacman -Qi` → `Required By: None`, `Optional For: None`;
   `pactree -r grub-theme-garuda` solo se lista a sí mismo). Su `post_remove()`
   solo imprime un aviso informativo (`cat` a un heredoc) — no toca ningún
   archivo, así que la desinstalación en sí no tiene efectos secundarios.
2. **Defensa ante mecanismos futuros:** `/etc/default/grub.d/zz-ejr-grub.cfg`,
   ruta sin dueño de ningún paquete, fija `GRUB_THEME`, `GRUB_GFXMODE` y
   `GRUB_DISTRIBUTOR`. Ya no depende de que `grub-theme-garuda` exista o no —
   si algún otro mecanismo de Garuda alguna vez vuelve a tocar
   `/etc/default/grub`, este fragmento sigue ganando.

## Precedencia real de `grub-mkconfig` (al revés de SDDM)

En SDDM, `/etc/sddm.conf` gana sobre los drop-ins de `/etc/sddm.conf.d/`
(contraintuitivo). **Aquí es la convención normal: el fragmento gana.**
Verificado leyendo `/usr/bin/grub-mkconfig`:

```sh
if test -f ${sysconfdir}/default/grub ; then
  . ${sysconfdir}/default/grub          # se carga primero
fi
for dropin in ${sysconfdir}/default/grub.d/*.cfg ; do
  ...                                    # se cargan despues, en orden alfabetico
done
```

`/etc/default/grub` se hace `source` primero; los fragmentos de
`/etc/default/grub.d/*.cfg` se hacen `source` **después**, en orden
alfabético. Como son asignaciones de variables de shell, la última en
ejecutarse gana — por eso el fragmento (prefijo `zz-`, ordena al final) se
impone sin importar qué escriba `grub-theme-garuda` (o cualquier otro script)
en el archivo principal. **No dar por sentado que ambos gestores de arranque
siguen la misma regla de precedencia** fue justo el error que casi se repite
al planear esto — GRUB y SDDM la resuelven al revés uno del otro.

## Compatibilidad de hardware

El `background.png` del tema es 1920×1080 exacto, con posiciones de menú en
porcentajes calculados para 16:9. Los dos monitores de esta máquina
(`eDP-1` y `DP-4`) son 1920×1080. `GRUB_GFXMODE` no se dejó en `auto`
—el firmware UEFI podría ofrecer una resolución distinta a la que reporta
Wayland/Hyprland— sino con una lista de reserva:

```
GRUB_GFXMODE=1920x1080x32,1920x1080,auto
```

GRUB prueba cada valor en orden hasta que el firmware soporte uno. Si
`1920x1080x32` no está disponible, cae a `1920x1080` sin canal alfa de 32
bits; si tampoco, cae a `auto` como último recurso — nunca se queda sin menú
por falta de un modo de video.

## Inventario

* `astronaut-ejr/` — tema completo, copia real desde `/boot/grub/themes/astronaut-ejr/`
* `grub` — copia de `/etc/default/grub` (sin el fragmento; el fragmento vive aparte)
* `zz-ejr-grub.cfg` — el fragmento de blindaje, copia de `/etc/default/grub.d/zz-ejr-grub.cfg`

## Rutas sin dueño

* `/boot/grub/themes/astronaut-ejr/` — confirmado con `pacman -Qoq`
* `/etc/default/grub.d/zz-ejr-grub.cfg` — archivo propio en un directorio de
  fragmentos; nada reclama ese nombre de archivo específico

## Rutas que siguen perteneciendo a paquetes

* `/etc/default/grub` — propiedad de `grub`, declarado *Backup File* (si
  `grub` se actualiza y el archivo está modificado, pacman genera `.pacnew`
  en vez de sobrescribir — comportamiento correcto, no es una amenaza)
* `/etc/default/grub.d/00_garuda-kernel-params.cfg` (paquete
  `garuda-common-settings`) y `20-garuda-dracut-support.cfg` (paquete
  `garuda-dracut-support`) — no se tocaron; nuestro fragmento ordena después
  de ambos alfabéticamente, así que sigue ganando aunque cambien

## Instalar en una máquina nueva

```bash
sudo cp -r astronaut-ejr /boot/grub/themes/astronaut-ejr
sudo cp zz-ejr-grub.cfg /etc/default/grub.d/zz-ejr-grub.cfg
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

Verificar:

```bash
sudo grep -n 'theme\|gfxmode\|distributor' /boot/grub/grub.cfg
```

Si `grub-theme-garuda` está instalado en la máquina nueva, considera
desinstalarlo (`pacman -Qi grub-theme-garuda` para revisar dependientes
primero) — si no, su próximo `post_upgrade()` seguirá intentando escribir
sobre `/etc/default/grub` (inofensivo gracias al fragmento, pero innecesario).

## Qué revisar tras un `-Syu` o una actualización de kernel

1. `sudo grep -n '^Current=\|GRUB_THEME' /etc/default/grub.d/zz-ejr-grub.cfg` — el fragmento no debería cambiar solo
2. `sudo grep -n 'theme' /boot/grub/grub.cfg` — debe seguir apuntando a `astronaut-ejr`
3. `pacman -Qi grub-theme-garuda` — si alguna vez vuelve a aparecer instalado (reintroducido como dependencia de algo), revisar por qué antes de que su script vuelva a correr
4. Una actualización de kernel regenera `grub.cfg` (vía `99-update-grub.hook` u otro mecanismo de Garuda) — eso es normal y no debería afectar el tema, ya que relee `/etc/default/grub` + fragmentos cada vez

## Restaurar tras una reinstalación o si algo sale mal

```bash
sudo cp -r astronaut-ejr /boot/grub/themes/astronaut-ejr
sudo cp zz-ejr-grub.cfg /etc/default/grub.d/zz-ejr-grub.cfg
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

Si el sistema no arranca bien tras un cambio manual, desde el menú de GRUB
usa `c` (consola de comandos) o `e` (editar entrada) para arrancar igual, o
usa un USB live para montar la partición y restaurar `/boot/grub/grub.cfg` y
`/etc/default/grub` desde `~/.dotfiles/grub/backup-<fecha>/` (local, sin
versionar — ver `.gitignore`).
