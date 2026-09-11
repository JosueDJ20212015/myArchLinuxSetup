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

## Tema v2 (menú centrado, título propio)

`astronaut-ejr` se actualizó a v2: `background.png` recompuesto, menú centrado
(antes iba a la derecha), y un `label` con el título "GRUB OS SELECTOR". Sigue
siendo 1920×1080, sin reescalar. Reemplazo directo — no coexiste con v1.

## Menú duplicado: tres parejas de scripts idénticos

Además del tema, el menú mostraba **Windows, Shutdown y Restart duplicados**,
y `os-prober` corría dos veces en cada regeneración. Causa, con evidencia:

`/etc/grub.d/` tenía tres parejas de archivos **byte-idénticos** (`diff` sin
salida en los tres casos) — uno sin dueño (más viejo) y uno con dueño de
paquete (más nuevo), ambos ejecutándose y emitiendo la misma entrada dos
veces, porque `grub-mkconfig` corre **todo** archivo ejecutable en
`/etc/grub.d/` y concatena su salida (a diferencia de `/etc/default/grub.d/`,
aquí no hay "el último gana": cada script que corre *añade* contenido, no
sobrescribe el de otro):

| Duplicado sin dueño (eliminado) | Original con dueño (intacto) |
|---|---|
| `15_os-prober` (9-nov-2025) | `30_os-prober` (`grub`) |
| `16_custom_leave_options` (1-oct-2025) | `61_custom_leave_options` (`garuda-common-settings`) |
| `90_uefi-firmware` (28-oct-2025) | `30_uefi-firmware` (`grub`) |

Ninguno de los tres archivos con dueño (`30_os-prober`, `61_custom_leave_options`,
`30_uefi-firmware`) está declarado *Backup File* por su paquete — así que
modificarlos o quitarles el permiso de ejecución no está garantizado a
sobrevivir la próxima actualización de ese paquete. Por eso **no se tocó
ninguno**: se borraron solo los tres duplicados sin dueño (riesgo cero,
permanente, nada los gestiona) y se dejaron los originales corriendo tal
cual.

**`garuda-common-settings` no se puede desinstalar** para eliminar la causa de
raíz (como sí se hizo con `grub-theme-garuda`): es dependencia dura de
`garuda-hyprland-settings` (`Required By` lo confirma). La estrategia aquí es
distinta a la del tema — no eliminar la causa, sino reordenar/ocultar su
efecto sin tocarla.

## Reorganización del menú (scripts propios, sin dueño)

Orden pedido: `Arch Linux` (default) → `Windows` → `UEFI Firmware Settings` →
`Shutdown` → `Restart` → todo lo demás dentro de un submenú `More Options`.

Tres archivos nuevos en `/etc/grub.d/`, todos sin dueño, todos ejecutables:

* **`31_ejr_leave_options`** — copia propia de las entradas Shutdown/Restart,
  numerada para correr justo después de `30_os-prober`/`30_uefi-firmware`.
  El original `61_custom_leave_options` (con dueño) sigue corriendo también
  — su salida (un segundo Shutdown/Restart, redundante) queda oculta dentro
  del submenú de abajo en vez de aparecer arriba.
* **`35_ejr_submenu_open`** — emite `submenu "More Options" {`
* **`95_ejr_submenu_close`** — emite `}`

Todo lo que cae entre 35 y 95 alfabéticamente (`35_fwupd`, `40_custom`,
`41_custom`, `61_custom_leave_options` redundante, `70_snapshots-btrfs`,
`80_memtest86+`) queda anidado dentro de `More Options`, sin haber tocado
ninguno de esos scripts — el bloque `submenu { }` de GRUB puede abarcar la
salida concatenada de varios scripts distintos, no tiene que ser un solo
archivo.

**Sin tilde a propósito** ("More Options", no "Más Opciones"): las fuentes
`.pf2` del tema se generaron con `grub-mkfont` y no está confirmado que
incluyan glifos acentuados — un carácter ausente no da error, simplemente no
se dibuja, y solo se vería al reiniciar.

**Decisión consciente: `UEFI Firmware Settings` queda top-level, fuera del
submenú.** Meterlo dentro requeriría deshabilitar `30_uefi-firmware` (con
dueño, sin backup declarado) — cambiar un problema ya resuelto por una
vigilancia permanente, para ocultar una entrada que casi nunca se ve (solo
aparece si el firmware soporta `fwsetup --is-supported`). No compensa.

**`'Garuda Linux snapshots'` sigue diciendo "Garuda"** — es texto literal
dentro de `70_snapshots-btrfs`, no usa la variable `$GRUB_DISTRIBUTOR`. No es
un fallo del blindaje, ese script simplemente no lee esa variable para su
propio título.

**Verificación antes de reiniciar:** `grub-script-check` (herramienta oficial
de GRUB para validar sintaxis) confirmado con salida limpia y código de
salida `0` — el archivo generado es sintácticamente válido. Un conteo manual
de llaves de cierre (`grep -c "^}"`) **no sirve** para esto: no captura las
llaves indentadas de `menuentry` anidados dentro de submenús, así que un
conteo bajo no significa desbalance real. Usar siempre `grub-script-check`.

## Contraseña de GRUB: bloquear `e`/`c`, sin bloquear el arranque

Objetivo: que nadie con acceso físico pueda editar una entrada (`e`) o abrir
la consola (`c`) para meter `init=/bin/bash` y entrar como root — pero que
`Arch Linux` y `Windows Boot Manager` sigan arrancando libres, sin pedir
nada.

### Qué falló en el intento anterior

Quedó un residuo en `/etc/grub.d/40_custom` (comentado, ya limpiado):

```
#set superusers="admin"
#password_pbkdf2 admin grub.pbkdf2.sha512.10000.grub.pbkdf2.sha512.10000.A3C256DD...
```

Separando por puntos, el formato correcto es `grub.pbkdf2.sha512.<iter>.<salt>.<hash>`
— 6 campos. Este tenía **10**: el prefijo `grub.pbkdf2.sha512.10000.` estaba
**duplicado**, probablemente por pegar la salida completa de
`grub-mkpasswd-pbkdf2` sobre una plantilla que ya tenía el mismo prefijo
escrito. El hash nunca podía validar — el síntoma (credenciales correctas
rechazadas) era indistinguible de una contraseña mal tecleada.

Esta vez el hash se generó y se escribió **directo al archivo destino en una
sola operación**, sin pasar por pantalla ni portapapeles, y se validó con un
script Python que replica PBKDF2-HMAC-SHA512 **antes** de tocar nada más.

### Diseño: dos mecanismos independientes

1. **Autenticación** (`/etc/grub.d/05_ejr_grub_password`, sin dueño):
   ```
   set superusers="admin"
   export superusers
   password_pbkdf2 admin <hash>
   ```
   El `export` es imprescindible y nada obvio — la documentación de GRUB
   (`info grub`, nodo *Authentication and authorisation*) dice explícitamente:
   *"The environment variable needs to be exported to also affect the section
   defined by the `submenu` command."* Sin `export`, la protección no llega a
   las entradas dentro de submenús (podrían quedar sin protección real, sin
   avisar).

2. **Excepciones libres** (`--unrestricted`), en las entradas/submenús exactos:
   - `Arch Linux` (entrada simple, dentro de `10_linux`)
   - `Windows Boot Manager` (dentro de `30_os-prober`, variante EFI)
   - `Garuda Linux snapshots` (dentro de `70_snapshots-btrfs`, ya lo soportaba
     de fábrica vía `GRUB_BTRFS_DISABLE_PROTECTION_SUBMENU`)

   **Protegido a propósito:** `Advanced options for Arch Linux` (kernels
   antiguos, fallback, **recovery mode**) — es el vector principal para
   conseguir una shell con privilegios, dejarlo libre anularía el propósito
   de la tarea.

   **Snapshots libres a propósito:** son la red de recuperación si una
   actualización rompe el arranque — si quedaran protegidos y en ese momento
   no se recuerda la contraseña, se pierde la red de seguridad justo cuando
   se necesita. El riesgo es menor de lo que parece: un snapshot arranca un
   sistema normal que pide login, no una shell privilegiada como recovery
   mode.

### GRUB usa teclado US siempre

Por eso la contraseña es solo letras y dígitos, sin símbolos: los caracteres
alfanuméricos ASCII ocupan la misma posición física en cualquier
distribución de teclado, así que no hay ambigüedad posible sin importar qué
layout tenga el sistema en uso. Un símbolo (`@`, `"`, etc.) sí podría estar
en una tecla distinta según el layout que GRUB asuma internamente.

### Archivos con dueño que se tocaron, y qué revisar

`10_linux` y `30_os-prober` (paquete `grub`, **sin backup file declarado**)
se editaron para agregar `--unrestricted` a las entradas simples de Arch y
Windows. Un parche Python idempotente y auto-validante
(`scripts/ejr-grub-unrestricted-patch.py`) hace esto — aborta y avisa si el
patrón esperado no aparece exactamente una vez, en vez de fallar en
silencio como haría un `sed` sin coincidencia.

**Blindaje:** hook de pacman (`hooks/99-ejr-grub-unrestricted.hook`,
`Target = grub`, `PostTransaction`) que reaplica el parche automáticamente
tras cada actualización de `grub`, y regenera `grub.cfg`. Si el patrón ya no
coincide (porque `grub` cambió el texto exacto de la línea), el parche
**avisa en pantalla durante el `-Syu`** — no falla en silencio.

**Modo de fallo, en ambos casos:** Arch/Windows vuelven a pedir la
contraseña que tú mismo elegiste. No es "no arranca" — es "hay que teclear
la contraseña de nuevo hasta que se note y se corrija".

### Verificar el hash (repetible en cualquier momento)

```bash
python3 scripts/verify-grub-hash.py
```

Lee el hash directo de `/etc/grub.d/05_ejr_grub_password`, pide la
contraseña de forma oculta (`getpass`), y compara — nunca hay que copiar ni
pegar el hash a mano.

### Probado en VM antes de tocar el arranque real

`grub-script-check` solo valida sintaxis, no el motor de autorización en
tiempo de ejecución. Se instaló `qemu` + `edk2-ovmf`, se construyó una
imagen EFI de prueba (`grub-install --removable` + copia del `grub.cfg`
real), y se verificó en un GRUB real corriendo en la VM:

- `Arch Linux` arrancó automáticamente al vencer el timeout, **sin pedir
  contraseña** (falló después por no encontrar el kernel — la imagen de
  prueba no tiene `/boot` real, es esperado)
- `Advanced options for Arch Linux` con usuario/contraseña **incorrectos**:
  `error: ...grub_auth_check_authentication...access denied`
- `Advanced options for Arch Linux` con la contraseña **real**: acceso
  concedido, se pudo ver el contenido del submenú

`Garuda Linux snapshots` no se pudo probar visualmente en la VM (necesita un
archivo compañero, `grub-btrfs.cfg`, que no se copió a la imagen de prueba),
pero el texto generado (`submenu 'Garuda Linux snapshots' --unrestricted {`)
ya pasó `grub-script-check` y usa el mismo mecanismo `--unrestricted` ya
verificado empíricamente con Arch Linux.

### Qué protege esto y qué no

**Protege:** que alguien con acceso físico presione `e` para editar una
entrada y arrancar con `init=/bin/bash`, o `c` para abrir la consola de
GRUB y montar/manipular discos manualmente antes de que arranque el SO.

**No protege:**
- Contra alguien que se lleve el disco físico y lo monte en otra máquina —
  para eso hace falta cifrado completo del disco (LUKS), que esto no
  sustituye.
- Contra arranque desde un USB/red si el firmware UEFI no tiene su propia
  contraseña y el orden de arranque no está fijado — cualquiera puede
  simplemente elegir arrancar otro medio desde el menú de firmware.

## Inventario

* `astronaut-ejr/` — tema completo v2, copia real desde `/boot/grub/themes/astronaut-ejr/`
* `grub` — copia de `/etc/default/grub` (sin el fragmento; el fragmento vive aparte)
* `zz-ejr-grub.cfg` — el fragmento de blindaje, copia de `/etc/default/grub.d/zz-ejr-grub.cfg`
* `grub.d/31_ejr_leave_options`, `grub.d/35_ejr_submenu_open`, `grub.d/95_ejr_submenu_close` — los tres scripts propios de reorganización del menú, copias de `/etc/grub.d/`
* `grub.d/05_ejr_grub_password` — `superusers`/`export`/`password_pbkdf2` (el hash, nunca la contraseña en claro)
* `grub.d/10_linux`, `grub.d/30_os-prober` — copias parcheadas con `--unrestricted`, con dueño de paquete
* `grub.d/40_custom` — copia ya limpia, sin el residuo del intento anterior
* `hooks/99-ejr-grub-unrestricted.hook` — hook de pacman que reaplica el parche tras actualizar `grub`
* `scripts/ejr-grub-unrestricted-patch.py` — el parche idempotente y auto-validante
* `scripts/verify-grub-hash.py` — verificación repetible del hash
* `grub-btrfs.config.d/zz-ejr-unrestricted.cfg` — snapshots libres, vía mecanismo oficial de `grub-btrfs`

## Rutas sin dueño

* `/boot/grub/themes/astronaut-ejr/` — confirmado con `pacman -Qoq`
* `/etc/default/grub.d/zz-ejr-grub.cfg` — archivo propio en un directorio de
  fragmentos; nada reclama ese nombre de archivo específico
* `/etc/grub.d/05_ejr_grub_password`, `31_ejr_leave_options`,
  `35_ejr_submenu_open`, `95_ejr_submenu_close` — scripts propios
* `/etc/pacman.d/hooks/99-ejr-grub-unrestricted.hook` — directorio de
  usuario, nunca pertenece a un paquete
* `/usr/local/bin/ejr-grub-unrestricted-patch.py` — `/usr/local` está
  reservado para el administrador local por convención, pacman no lo toca
* `/etc/default/grub-btrfs/config.d/zz-ejr-unrestricted.cfg` — fragmento
  propio en el directorio de drop-ins de `grub-btrfs`

## Rutas que siguen perteneciendo a paquetes

* `/etc/default/grub` — propiedad de `grub`, declarado *Backup File* (si
  `grub` se actualiza y el archivo está modificado, pacman genera `.pacnew`
  en vez de sobrescribir — comportamiento correcto, no es una amenaza)
* `/etc/default/grub.d/00_garuda-kernel-params.cfg` (paquete
  `garuda-common-settings`) y `20-garuda-dracut-support.cfg` (paquete
  `garuda-dracut-support`) — no se tocaron; nuestro fragmento ordena después
  de ambos alfabéticamente, así que sigue ganando aunque cambien
* `/etc/grub.d/10_linux`, `/etc/grub.d/30_os-prober` — propiedad de `grub`,
  **sin backup file declarado**. Editados para agregar `--unrestricted`;
  blindados con el hook de pacman (ver sección de contraseña arriba)
* `/etc/grub.d/40_custom` — propiedad de `grub`, **con backup file
  declarado**. Solo se le quitó el residuo del intento anterior; no se le
  agregó nada activo

## Instalar en una máquina nueva

```bash
sudo cp -r astronaut-ejr /boot/grub/themes/astronaut-ejr
sudo cp zz-ejr-grub.cfg /etc/default/grub.d/zz-ejr-grub.cfg
sudo cp grub.d/31_ejr_leave_options grub.d/35_ejr_submenu_open grub.d/95_ejr_submenu_close /etc/grub.d/
sudo chmod +x /etc/grub.d/31_ejr_leave_options /etc/grub.d/35_ejr_submenu_open /etc/grub.d/95_ejr_submenu_close
sudo grub-mkconfig -o /boot/grub/grub.cfg
sudo grub-script-check /boot/grub/grub.cfg
```

Revisa también si la máquina nueva tiene duplicados propios de
`os-prober`/`custom_leave_options`/`uefi-firmware` en `/etc/grub.d/` antes de
copiar estos scripts — la causa (una copia manual vieja sin dueño, sin borrar
tras una actualización del paquete) puede repetirse en cualquier instalación
de Garuda con historial similar.

Verificar:

```bash
sudo grep -n 'theme\|gfxmode\|distributor' /boot/grub/grub.cfg
```

Si `grub-theme-garuda` está instalado en la máquina nueva, considera
desinstalarlo (`pacman -Qi grub-theme-garuda` para revisar dependientes
primero) — si no, su próximo `post_upgrade()` seguirá intentando escribir
sobre `/etc/default/grub` (inofensivo gracias al fragmento, pero innecesario).

Para la contraseña, en una máquina nueva:

```bash
sudo cp grub.d/05_ejr_grub_password /etc/grub.d/05_ejr_grub_password
sudo chmod +x /etc/grub.d/05_ejr_grub_password
sudo cp scripts/ejr-grub-unrestricted-patch.py /usr/local/bin/
sudo chmod +x /usr/local/bin/ejr-grub-unrestricted-patch.py
sudo python3 /usr/local/bin/ejr-grub-unrestricted-patch.py
sudo cp hooks/99-ejr-grub-unrestricted.hook /etc/pacman.d/hooks/
sudo mkdir -p /etc/default/grub-btrfs/config.d
sudo cp grub-btrfs.config.d/zz-ejr-unrestricted.cfg /etc/default/grub-btrfs/config.d/
sudo grub-mkconfig -o /boot/grub/grub.cfg
sudo grub-script-check /boot/grub/grub.cfg
python3 scripts/verify-grub-hash.py
```

El hash es el mismo en cualquier máquina donde se copie este archivo — si
quieres una contraseña distinta en la máquina nueva, genera un `05_ejr_grub_password`
nuevo en vez de copiar este (ver la Fase 2 de la tarea original: generar y
escribir en una sola operación, sin copiar/pegar el hash a mano).

## Qué revisar tras un `-Syu` o una actualización de kernel

1. `sudo grep -n '^Current=\|GRUB_THEME' /etc/default/grub.d/zz-ejr-grub.cfg` — el fragmento no debería cambiar solo
2. `sudo grep -n 'theme' /boot/grub/grub.cfg` — debe seguir apuntando a `astronaut-ejr`
3. `pacman -Qi grub-theme-garuda` — si alguna vez vuelve a aparecer instalado (reintroducido como dependencia de algo), revisar por qué antes de que su script vuelva a correr
4. Una actualización de kernel regenera `grub.cfg` (vía `99-update-grub.hook` u otro mecanismo de Garuda) — eso es normal y no debería afectar el tema, ya que relee `/etc/default/grub` + fragmentos cada vez
5. `sudo grep -n 'unrestricted' /etc/grub.d/10_linux /etc/grub.d/30_os-prober` — debe seguir habiendo exactamente una coincidencia en cada archivo tras cualquier actualización de `grub`. Si el hook de pacman corrió, revisa el log de esa transacción (`grep -A5 'ejr-grub-unrestricted' /var/log/pacman.log`) por si avisó de un patrón que ya no coincide.

## Restaurar tras una reinstalación o si algo sale mal

```bash
sudo cp -r astronaut-ejr /boot/grub/themes/astronaut-ejr
sudo cp zz-ejr-grub.cfg /etc/default/grub.d/zz-ejr-grub.cfg
sudo cp grub.d/31_ejr_leave_options grub.d/35_ejr_submenu_open grub.d/95_ejr_submenu_close grub.d/05_ejr_grub_password /etc/grub.d/
sudo chmod +x /etc/grub.d/31_ejr_leave_options /etc/grub.d/35_ejr_submenu_open /etc/grub.d/95_ejr_submenu_close /etc/grub.d/05_ejr_grub_password
sudo python3 scripts/ejr-grub-unrestricted-patch.py
sudo grub-mkconfig -o /boot/grub/grub.cfg
sudo grub-script-check /boot/grub/grub.cfg
```

Si el sistema no arranca bien tras un cambio manual, desde el menú de GRUB
usa `c` (consola de comandos) o `e` (editar entrada) para arrancar igual, o
usa un USB live para montar la partición y restaurar `/boot/grub/grub.cfg` y
`/etc/default/grub` desde `~/.dotfiles/grub/backup-<fecha>/` (local, sin
versionar — ver `.gitignore`).
