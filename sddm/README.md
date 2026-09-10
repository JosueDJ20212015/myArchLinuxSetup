# SDDM — fondo custom blindado (ejr-sddm)

Fork de `Sweet6` con el fondo cambiado a `ninja.jpg` (1920x1080), forkeado a una
ruta sin dueño de paquete para que sobreviva a actualizaciones del sistema.

## Cómo llegamos aquí

El tema `Sweet6` (activo en `/etc/sddm.conf`) pertenece a **dos paquetes**:

| Ruta | Paquete |
|---|---|
| `theme.conf`, QML, `metadata.desktop` | `sddm-theme-sweet-git` |
| `theme.conf.user`, `assets/bg-blue-tillidie.png` y otros wallpapers alternativos | `garuda-hyprland-settings` |

En diciembre de 2025 se editó `theme.conf` a mano. El 2026-09-09 a las 23:59,
`garuda-hyprland-settings` se actualizó y reinstaló su propio `theme.conf.user`
(su versión de fábrica, sin relación con la edición de diciembre). Como
`theme.conf.user` tiene prioridad sobre `theme.conf` (ver más abajo), el efecto
visible fue que el tema "volvió" a su fondo por defecto.

**Corrección importante sobre esto:** no fue un borrado ni una reversión de un
archivo del usuario. `theme.conf.user` y los wallpapers alternativos siempre
fueron de fábrica de `garuda-hyprland-settings`, no algo creado por el usuario.
Lo que pasó fue un **eclipse**: se editó `theme.conf` sin saber que
`theme.conf.user` lo anula, así que la edición nunca tuvo efecto real una vez
que `theme.conf.user` existía con un valor distinto. No hubo pérdida de datos
propios — la comparación contra el paquete cacheado (`sddm-theme-sweet-git`
r2.a283203-2, en `/var/cache/pacman/pkg/`) mostró que el único cambio de
diciembre fue la línea `Background`, y ese valor ya vivía en el archivo antes
de este trabajo.

## El mecanismo `theme.conf` / `theme.conf.user`

- Es un mecanismo **interno de SDDM**, no algo que el tema `Sweet6` implemente.
  Confirmado leyendo el QML: solo usa `config.Background`, `config.color`,
  etc. — nunca referencia `.user` directamente. `metadata.desktop` declara
  `ConfigFile=theme.conf` sin mención de `.user`; SDDM añade la capa `.user`
  por su cuenta si el archivo existe.
- Su propósito documentado (wiki oficial de SDDM y ArchWiki) es proteger las
  ediciones del usuario: `theme.conf` lo trae el paquete del tema,
  `theme.conf.user` es donde el usuario debía guardar sus cambios para que
  sobrevivieran a actualizaciones del paquete.
- **Garuda anula ese contrato**: empaqueta `theme.conf.user` dentro de
  `garuda-hyprland-settings` en vez de dejarlo como archivo libre para el
  usuario. El archivo que SDDM reserva para protegerte de los paquetes, aquí
  lo distribuye un paquete.
- Ninguno de los dos paquetes (`sddm-theme-sweet-git`, `garuda-hyprland-settings`)
  declara `Backup Files` (verificado con `pacman -Qi`). Sin `backup=()`, pacman
  **sobrescribe en silencio** en cada actualización — no genera `.pacnew`, así
  que no hay ni siquiera un aviso de conflicto.

## El riesgo real que cierra el fork

No es `garuda-migrations` (investigado y descartado, ver más abajo) ni
`theme.conf.user` en sí — es que **`theme.conf` pertenece a un paquete `-git`**
(`sddm-theme-sweet-git`). Los paquetes `-git` se reconstruyen desde el
repositorio upstream en cada actualización; en la próxima reconstrucción,
`theme.conf` se habría vuelto a sobrescribir con la versión de fábrica, sin
aviso, exactamente como ya pasó una vez con `theme.conf.user`.

El fork (`ejr-sddm`) resuelve esto porque toda la carpeta queda **sin dueño de
ningún paquete** — confirmado con `pacman -Qoq`, que falla con
`error: No package owns ...`. Nada la va a tocar en una actualización.

## `garuda-migrations`: investigado y descartado

Se investigó como sospechoso inicial porque `/etc/sddm.conf` contenía el
comentario `# Modified by garuda-migrations: Sweet -> Sweet6`. Resultado:

- Es un paquete que instala hooks de pacman
  (`/usr/share/libalpm/hooks/{00,95}-garuda-migrations.hook`), disparados solo
  cuando se instala/actualiza el propio paquete `garuda-migrations`.
- Cada migración interna está gateada por versión (`vercmp`) y corre **una
  sola vez**, cuando `applied_version` cruza su umbral.
- La migración relevante hace `grep -q '^Current=Sweet$'` (match exacto y
  anclado) — nunca coincidiría con `Current=ejr-sddm` ni con `Current=Sweet6`.
- Ya se ejecutó: `applied_version` y `current_version` coinciden en
  `4.1.0-1`, por encima del umbral de esa migración (`3.4.3-1`). No puede
  volver a dispararse.

Conclusión: riesgo histórico y consumido, no una amenaza activa. No se
implementó ningún hook de pacman adicional para contrarrestarlo — habría sido
complejidad sin un mecanismo real que mitigar.

## Orden de precedencia real de SDDM (citado del man page)

**Contraintuitivo: es lo opuesto a la convención de drop-ins de systemd.**
En systemd el drop-in gana; en SDDM pierde.

`man 5 sddm.conf`, sección SYNOPSIS:

> "Configuration loads all files in the configuration directories followed by
> the configuration file in the order listed below with the latter having
> highest precedence."
>
> 1. `/usr/lib/sddm/sddm.conf.d` — System configuration directory
> 2. `/etc/sddm.conf.d` — Local configuration directory
> 3. `/etc/sddm.conf` — Local configuration file for compatibility

Es decir: `/etc/sddm.conf` está **al final** y gana sobre cualquier drop-in en
`/etc/sddm.conf.d/`. Por eso `Current=ejr-sddm` se editó **directamente en
`/etc/sddm.conf`** en vez de usar un drop-in — un drop-in habría sido
letra muerta.

Nota sobre comentarios inline: la línea original
`Current=Sweet6 # Modified by garuda-migrations: Sweet -> Sweet6` cargaba
correctamente, así que SDDM/Qt sí tolera comentarios `#` al final de línea. En
este archivo se puso el comentario en líneas aparte por claridad de lectura,
no porque el inline fallara.

## La consolidación de `theme.conf` / `theme.conf.user`

En el fork **se eliminó `theme.conf.user`** y solo queda `theme.conf`. Fue
deliberado, no un descuido:

- El propósito de `.user` es sobrevivir a actualizaciones de un paquete que
  posee `theme.conf`. En `ejr-sddm` no hay ningún paquete dueño — no hay nada
  de qué protegerse.
- Mantener los dos archivos habría conservado la misma trampa que causó el
  problema original: dos archivos que deben mantenerse sincronizados a mano.
- **Advertencia para el futuro:** si alguien (una herramienta de KDE, un
  script, o yo mismo sin recordar esto) crea un `theme.conf.user` dentro de
  `ejr-sddm/`, **vuelve a introducir el problema** — ese archivo anularía a
  `theme.conf` otra vez, silenciosamente. Si el fondo del ninja deja de verse
  algún día, lo primero a revisar es si apareció un `theme.conf.user` nuevo.

## Inventario de `assets/`

El fork conserva todos los wallpapers originales de `Sweet6` como respaldo
interno, sin necesidad de ir a buscarlos fuera:

- `bg.jpg` — fondo de fábrica de `sddm-theme-sweet-git`
- `bg-blue-tillidie.png`, `bg-dark-01.png`, `bg-dark-02.png`,
  `bg-red-tillidie.png`, `bg.png` — wallpapers alternativos de fábrica de
  `garuda-hyprland-settings`
- `bg-blue-tillidie_COPY.png` — copia de seguridad propia del usuario, hecha
  el 2025-10-02 antes de tocar el tema por primera vez. No es un archivo de
  ningún paquete ni un duplicado accidental de este trabajo; se conserva tal
  cual. Si algún día se decide podar wallpapers sobrantes, se poda el
  conjunto completo de Garuda junto, no como archivo suelto.
- `ninja.jpg` — el fondo activo actual, 1920x1080, copiado sin recomprimir
  desde `~/Downloads/ninja.jpg` (hash SHA256 verificado idéntico)

## Rutas sin dueño (blindadas)

- `/usr/share/sddm/themes/ejr-sddm/` — confirmado con `pacman -Qoq`
- `/etc/sddm.conf` — nunca tuvo dueño de paquete (verificado: `pacman -Ql sddm`
  solo trackea `/usr/lib/sysusers.d/sddm.conf` y `/usr/lib/tmpfiles.d/sddm.conf`,
  no `/etc/sddm.conf`)

## Rutas que siguen perteneciendo a paquetes

- `/usr/share/sddm/themes/Sweet6/` — sigue existiendo tal cual, intacto, como
  quedó en el respaldo. Sigue siendo propiedad de `sddm-theme-sweet-git` y
  `garuda-hyprland-settings`, y sí puede generar sobreescrituras silenciosas
  en el futuro (ninguno declara backup files) — pero ya no es el tema activo,
  así que no afecta el fondo visible.
- `/usr/lib/sddm/sddm.conf.d/default.conf` — propiedad de `sddm`. No se tocó.

## Recuperar el `theme.conf` de fábrica (sin depender del respaldo)

`backup-<fecha>/` es una carpeta **local, sin versionar** (ver `.gitignore`:
`sddm/backup-*/`) — es un snapshot puntual de un estado que ya no existe, no
configuración a mantener. Si algún día no está disponible (reinstalación,
carpeta borrada, otra máquina), el `theme.conf` original de `Sweet6` se puede
volver a extraer directamente del paquete cacheado por pacman, sin necesidad
de reinstalar nada:

```bash
mkdir -p /tmp/sweet-orig
cd /tmp/sweet-orig
tar --use-compress-program=unzstd -xf /var/cache/pacman/pkg/sddm-theme-sweet-git-*.pkg.tar.zst usr/share/sddm/themes/Sweet6/theme.conf
cat usr/share/sddm/themes/Sweet6/theme.conf
```

**Ojo con la ruta interna del paquete:** va **sin** el `./` inicial
(`usr/share/...`, no `./usr/share/...`) — con el `./` `tar` responde
`Not found in archive` aunque el archivo sí esté ahí. Para confirmar la ruta
exacta dentro de cualquier paquete cacheado:

```bash
tar --use-compress-program=unzstd -tf /var/cache/pacman/pkg/sddm-theme-sweet-git-*.pkg.tar.zst | grep theme.conf
```

Esto solo funciona mientras el paquete siga en la caché de pacman
(`/var/cache/pacman/pkg/`, no se limpia por defecto). Si ya no está, buscar la
versión correspondiente en el
[AUR](https://aur.archlinux.org/packages/sddm-theme-sweet-git) o el
[repo upstream](https://github.com/EliverLara/Sweet).

## Restaurar tras una reinstalación

```bash
sudo cp -r ~/.dotfiles/sddm/ejr-sddm /usr/share/sddm/themes/ejr-sddm
sudo chmod 644 /usr/share/sddm/themes/ejr-sddm/assets/ninja.jpg
sudo sed -i '/^\[Theme\]/,/^\[/{s|^Current=.*|# restaurado desde dotfiles\nCurrent=ejr-sddm|}' /etc/sddm.conf
```

O, más simple, restaurar `/etc/sddm.conf` completo desde
`~/.dotfiles/sddm/sddm.conf` si no hay otros cambios locales que conservar en
ese archivo:

```bash
sudo cp ~/.dotfiles/sddm/sddm.conf /etc/sddm.conf
```

Verificar después:

```bash
grep -n '^Current=' /etc/sddm.conf
pacman -Qoq /usr/share/sddm/themes/ejr-sddm   # debe fallar (sin dueño)
```

## Qué revisar si el tema se revierte tras un `-Syu`

1. `grep -n '^Current=' /etc/sddm.conf` — si ya no dice `ejr-sddm`, algo
   escribió sobre el archivo. `garuda-migrations` está descartado como causa
   (ver arriba), pero una **versión futura** de ese paquete podría introducir
   una migración nueva — revisar
   `/usr/share/libalpm/scripts/garuda-migrations-runner` en busca de lógica
   que toque `Current=`.
2. `ls /usr/share/sddm/themes/ejr-sddm/theme.conf.user` — si existe, alguien o
   algo lo creó y está anulando `theme.conf` de nuevo. Borrarlo.
3. `pacman -Qoq /usr/share/sddm/themes/ejr-sddm` — si esto alguna vez
   encuentra un dueño, algo empaquetó por encima de esta ruta; investigar qué
   paquete y por qué antes de tocar nada.
4. Confirmar que `/usr/share/sddm/themes/ejr-sddm/assets/ninja.jpg` sigue
   existiendo con permisos `644`.
