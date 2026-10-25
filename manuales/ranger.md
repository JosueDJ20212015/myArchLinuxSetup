# Manual de ranger

ranger es un gestor de archivos que se usa **solo con el teclado**, dentro de la
terminal. Este manual está hecho para **tu** configuración
(`~/.config/ranger/rc.conf`): todas las teclas de aquí están verificadas en ella.

> **Abrirlo:** `Super + N` (abre kitty con ranger).
> Thunar sigue disponible en `Super + F3` por si alguna vez lo necesitas.
> Desde una terminal: `ranger` o `ranger ~/Pictures`.

---

## 1. Cómo se lee la pantalla

```
 ~/Pictures/Wallpapers/online           ← ruta actual (barra arriba)
┌──────────┬──────────────────┬─────────────────────┐
│ Screen…  │ online        30 │ wallhaven-0q2q17.jpg│
│ Wallp… ◄ │ 1.jpg       6.7M │ wallhaven-01jej9.jpg│
│          │ 350868.jpg  440K │        …            │
└──────────┴──────────────────┴─────────────────────┘
   padre        carpeta actual      vista previa
```

- **Columna izquierda:** la carpeta de arriba (padre).
- **Columna central:** donde estás. La línea resaltada es el archivo seleccionado.
- **Columna derecha:** vista previa de lo seleccionado (contenido de la carpeta,
  texto, o la **imagen** en sí — tu config usa el protocolo de imágenes de kitty).

Moverse en ranger es literalmente **caminar por esas columnas**.

---

## 2. Lo mínimo para empezar (apréndete solo esto el primer día)

| Tecla | Qué hace |
|---|---|
| `j` / `k` (o `↓` / `↑`) | Bajar / subir en la lista |
| `l` (o `→`, `Enter`) | Entrar a la carpeta / **abrir** el archivo |
| `h` (o `←`) | Volver a la carpeta de arriba |
| `gg` / `G` | Ir al primer / último archivo |
| `/` + texto + `Enter` | Buscar en la carpeta (`n` = siguiente coincidencia) |
| `zh` (o `Ctrl + h`) | Mostrar / ocultar archivos ocultos (los que empiezan con `.`) |
| `q` | Salir |
| `?` | Ayuda dentro de ranger |

> **Truco mental:** `h j k l` son las flechas pero sin mover la mano.
> `h` = izquierda (salir), `l` = derecha (entrar).

---

## 3. Saltos rápidos a carpetas

Teclas que empiezan con `g` = **"go to"** (ir a):

| Tecla | Va a |
|---|---|
| `gh` | Tu carpeta personal (`~`) |
| `gr` | La raíz del sistema (`/`) |
| `ge` | `/etc` |
| `gR` | La carpeta de ranger |

### Marcadores (tus propios atajos)

1. Entra a una carpeta que usas mucho, por ejemplo `~/.dotfiles`.
2. Pulsa `m` y luego una letra, por ejemplo `md` (marcador "d").
3. Desde cualquier lugar, pulsa `'d` (comilla + letra) y vuelves ahí.

Ideas: `md` → `~/.dotfiles`, `mw` → `~/Pictures/Wallpapers`, `ms` → `~/Pictures/Screenshots`.

---

## 4. Copiar, cortar, pegar y borrar

ranger usa el estilo de **vim**: se "tira" (yank) para copiar y se "borra" para cortar.

| Tecla | Qué hace |
|---|---|
| `yy` | **Copiar** el archivo seleccionado (o los marcados) |
| `dd` | **Cortar** (para mover) |
| `pp` | **Pegar** en la carpeta actual |
| `po` | Pegar **sobrescribiendo** si ya existe |
| `pl` | Pegar como **enlace simbólico** |
| `ya` / `da` | Añadir a lo ya copiado / cortado (juntar archivos de varias carpetas) |
| `dD` | **Borrar** (te pide confirmación) |
| `dT` | Mandar a la papelera — *requiere `trash-cli`, que no tienes instalado* |

**Ejemplo — mover una foto a otra carpeta:**
selecciónala → `dd` → navega a la carpeta destino → `pp`.

> ⚠️ `dD` borra de verdad, no a la papelera. Si prefieres papelera, instala
> `trash-cli` y usa `dT`.

---

## 5. Seleccionar varios archivos

| Tecla | Qué hace |
|---|---|
| `Espacio` | Marcar / desmarcar el archivo actual (y baja al siguiente) |
| `v` | Invertir la selección de **todos** |
| `uv` | Quitar todas las marcas |
| `V` | Modo visual: muévete con `j`/`k` y se marcan todos los del camino |

Luego de marcar, `yy`, `dd`, `dD`, etc. actúan sobre **todos** los marcados.

---

## 6. Renombrar y crear

| Tecla / comando | Qué hace |
|---|---|
| `cw` | Renombrar escribiendo el nombre completo nuevo |
| `a` | Renombrar con el cursor **antes de la extensión** (ideal para `foto.jpg`) |
| `A` | Renombrar con el cursor **al final** |
| `I` | Renombrar con el cursor **al inicio** |
| `:mkdir nombre` | Crear una carpeta |
| `:touch nombre.txt` | Crear un archivo vacío |
| `:bulkrename` | Renombrar **muchos** archivos marcados a la vez en un editor de texto |

> `:` abre la línea de comandos de ranger (como en vim). `Esc` la cancela.

---

## 7. Abrir archivos

| Tecla | Qué hace |
|---|---|
| `l` / `Enter` | Abrir con el programa predeterminado |
| `r` | **Elegir** con qué programa abrirlo (te muestra una lista numerada) |
| `i` | Ver el archivo a pantalla completa dentro de ranger |
| `zp` | Activar / desactivar la vista previa |

---

## 8. Buscar y filtrar

| Tecla | Qué hace |
|---|---|
| `/texto` | Buscar y saltar al primer archivo que coincida; `n` = siguiente |
| `f texto` | **Find**: salta mientras escribes; si queda uno solo, lo abre |
| `zf texto` | **Filtrar**: muestra solo los archivos que contienen "texto" (`zf` + `Enter` vacío lo quita) |

---

## 9. Ordenar

Teclas que empiezan con `o` = **"order"**:

| Tecla | Ordena por |
|---|---|
| `on` | Nombre (natural: `2` antes que `10`) |
| `os` | Tamaño |
| `om` | Fecha de modificación (lo más reciente al revisar con `G`) |
| `oz` | Aleatorio |

---

## 10. Pestañas (varias carpetas a la vez)

| Tecla | Qué hace |
|---|---|
| `gn` (o `Ctrl + n`) | Nueva pestaña |
| `Tab` / `gt` | Siguiente pestaña |
| `gT` | Pestaña anterior |
| `Ctrl + w` | Cerrar pestaña |
| `uq` | Recuperar la última pestaña cerrada |

**Ejemplo — copiar entre dos carpetas cómodamente:** abre la carpeta origen,
`gn` para una pestaña nueva, ve a la carpeta destino, `Tab` para volver,
`yy`, `Tab`, `pp`.

---

## 11. Información y terminal

| Tecla | Qué hace |
|---|---|
| `dc` | Calcular el tamaño real de la carpeta seleccionada |
| `du` | Ver cuánto pesa cada subcarpeta |
| `yp` | Copiar la **ruta** completa del archivo al portapapeles |
| `yn` | Copiar solo el **nombre** |
| `S` | Abrir una terminal (fish) en la carpeta actual; `exit` para volver a ranger |
| `!comando` | Ejecutar un comando en la carpeta actual |
| `@comando` | Igual, pero con los archivos seleccionados como argumento (`%s`) |

---

## 12. Plan para acostumbrarte (una semana)

| Día | Practica solo esto |
|---|---|
| 1 | `h j k l`, `gg`/`G`, `q`. Navega tus carpetas sin abrir nada. |
| 2 | `/` para buscar, `zh` para ocultos, `gh` para volver a casa. |
| 3 | `yy`, `dd`, `pp`. Ordena tu carpeta `Downloads` moviendo cosas. |
| 4 | `Espacio` y `V` para marcar varios, luego `dd`/`pp`. |
| 5 | Marcadores: crea `md`, `mw`, `ms` y úsalos con `'`. |
| 6 | `a`/`cw` para renombrar, `:mkdir`, pestañas con `gn` y `Tab`. |
| 7 | `r` para abrir con otro programa, `S` para la terminal, `:bulkrename`. |

---

## 13. Extras opcionales (no instalados)

Mejoran las vistas previas de ranger:

| Paquete | Para qué |
|---|---|
| `highlight` | Código con colores en la vista previa |
| `poppler` | Vista previa de PDFs |
| `atool` | Ver el contenido de `.zip`, `.tar.gz`, etc. sin descomprimir |
| `mediainfo` | Info de videos y audios |
| `trash-cli` | Habilita `dT` (papelera) |

```bash
sudo pacman -S highlight poppler atool mediainfo trash-cli
```
