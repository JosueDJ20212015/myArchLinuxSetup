# Manual: manejar Hyprland sin mouse

Este manual describe **tus** atajos reales (los de `~/.config/hypr/hyprland.lua`).
`Super` es la tecla de Windows.

---

## 1. La idea que lo hace fácil

Casi todo sigue **una sola regla**:

| Si pulsas… | …actúas sobre… |
|---|---|
| `Super + algo` | **Ir / enfocar** (moverte tú) |
| `Super + Shift + algo` | **Mover la ventana** (llevarte la ventana) |

Ejemplos de la regla:

- `Super + 3` → **tú** vas al escritorio 3.
  `Super + Shift + 3` → **la ventana** se va al escritorio 3.
- `Super + ←` → **tú** enfocas la ventana de la izquierda.
  `Super + Shift + ←` → **la ventana** se mueve a la izquierda.

Si te acuerdas de esto, ya sabes la mitad del manual.

---

## 2. Escritorios (workspaces) — lo que más te cuesta

En la barra, cada punto `·` de la isla izquierda es un escritorio y el
**pacman** `󰮯` es el que estás viendo.

| Atajo | Qué hace |
|---|---|
| `Super + 1` … `Super + 9` | Ir al escritorio 1 … 9 |
| `Super + 0` | Ir al escritorio 10 |
| `Super + Shift + número` | Mandar la ventana a ese escritorio **y quedarte donde estás** |
| `Alt + Shift + número` | Mandar la ventana a ese escritorio **y irte con ella** |
| `Super + rueda del mouse` | Escritorio siguiente / anterior (único caso que usa mouse) |

### Por qué cuesta y cómo practicarlo

Lo difícil no es la tecla, es **saber qué hay en cada escritorio**. La solución
es darle un "trabajo fijo" a cada número y siempre abrir las cosas ahí:

| Escritorio | Úsalo para |
|---|---|
| `1` | Terminal / código |
| `2` | Navegador |
| `3` | Archivos (ranger) |
| `4` | Música / chat |
| `5` | Lo que sea temporal |

Con eso, después de unos días tu mano va sola: "quiero el navegador" → `Super + 2`.

**Ejercicio de 5 minutos (hazlo varios días):**

1. `Super + 1`, abre una terminal (`Super + Enter`).
2. `Super + 2`, abre Firefox (`Super + O`).
3. `Super + 3`, abre ranger (`Super + N`).
4. Ahora salta: `Super + 1` → `Super + 3` → `Super + 2` → `Super + 1`… sin mirar la barra.
5. Desde el escritorio 1, manda la terminal al 5 con `Super + Shift + 5`
   y ve a buscarla con `Super + 5`.
6. Repite el paso 5 pero con `Alt + Shift + 5` y nota la diferencia
   (la ventana y tú se van juntos).

---

## 3. Moverte entre ventanas del mismo escritorio

Puedes usar **flechas** o **`H J K L`** (las mismas de vim y ranger):

| Atajo | Enfoca la ventana de… |
|---|---|
| `Super + ←` o `Super + H` | la izquierda |
| `Super + →` o `Super + L` | la derecha |
| `Super + ↑` o `Super + K` | arriba |
| `Super + ↓` o `Super + J` | abajo |
| `Super + Tab` | Pasar a la siguiente ventana (en orden) |

> El borde **blanco más visible** marca la ventana con foco.

---

## 4. Mover y acomodar ventanas

| Atajo | Qué hace |
|---|---|
| `Super + Shift + ←/→/↑/↓` (o `H/L/K/J`) | Mover la ventana en esa dirección |
| `Super + Shift + P` | Cambiar la división: lado a lado ↔ una encima de otra |
| `Super + P` | Modo "pseudo" (la ventana conserva su tamaño dentro de su espacio) |
| `Super + Shift + Espacio` | Hacer flotante / volver a mosaico |
| `Super + Shift + M` | **Minimizar**: la ventana se esconde y su icono aparece en la isla central |

### Minimizar y restaurar

- `Super + Shift + M` esconde la ventana enfocada; las demás se reacomodan solas.
- En la isla central, a la izquierda de la hora, aparece un icono por cada ventana minimizada.
- **Clic** en el icono → restaura la **última** minimizada en su escritorio original.
- **Clic derecho** → eliges cuál restaurar (si hay varias).

### Cambiar el tamaño (modo resize)

1. Pulsa `Super + R` → entras al **modo resize**.
2. Usa `←/→/↑/↓` (o `H/L/K/J`) — puedes **mantenerlas pulsadas**.
3. Pulsa `Esc` para salir del modo.

> Mientras estés en modo resize, las flechas no hacen otra cosa: si "el
> teclado no responde", probablemente olvidaste pulsar `Esc`.

---

## 5. Pantalla completa

| Atajo | Qué hace |
|---|---|
| `Super + M` | Maximizar (ocupa todo, pero la barra sigue visible) |
| `Super + F` | Pantalla completa real (sin barra) |
| `Super + Shift + F` | Pantalla completa "falsa": la app cree que está en completa, pero sigue en su recuadro |

Las tres se quitan pulsando el mismo atajo otra vez.

---

## 6. Abrir y cerrar cosas

| Atajo | Abre |
|---|---|
| `Super` (sola, tocar y soltar) | **Lanzador** de aplicaciones (wofi): escribe el nombre y `Enter` |
| `Super + Enter` o `Super + T` | Terminal (kitty) |
| `Super + tecla de arriba a la izquierda` (`` ` `` / `º`) | **Terminal desplegable** (aparece y se esconde) |
| `Super + N` | Archivos (ranger) |
| `Super + O` | Firefox |
| `Super + Shift + D` | Cajón con todas las apps (nwg-drawer) |
| `Super + V` | Historial del portapapeles |
| `Super + E` | Selector de emojis |
| `Super + Q` | **Cerrar** la ventana con foco |
| `Super + Shift + E` | Menú de apagado / bloquear / reiniciar |

### Tus apps en las teclas F

| Atajo | App | Atajo | App |
|---|---|---|---|
| `Super + F1` | FireDragon | `Super + F7` | Inkscape |
| `Super + F2` | Thunderbird | `Super + F8` | Blender |
| `Super + F3` | Thunar | `Super + F9` | Meld |
| `Super + F4` | Geany | `Super + F10` | Joplin |
| `Super + F5` | GitHub Desktop | `Super + F11` | Snapper tools |
| `Super + F6` | GParted | `Super + F12` | Calculadora |

---

## 7. Sistema y escritorio

| Atajo | Qué hace |
|---|---|
| `Super + Espacio` | Cambiar teclado inglés ↔ español |
| `Super + W` | Siguiente wallpaper |
| `Super + Shift + W` | "No me gusta": descarta el wallpaper descargado y pasa al siguiente |
| `Print` | Captura de un **área** (arrastra para seleccionar) |
| `Ctrl + Print` | Captura de la **ventana** activa |
| `Shift + Print` | Captura de **toda la pantalla** |
| `Super + Shift + R` | Recargar la configuración de Hyprland |
| Teclas de volumen / brillo | Una sola notificación con barra que se actualiza |
| Teclas multimedia | Play/pausa, siguiente, anterior |

Las capturas se guardan en `~/Pictures/Screenshots/` y se copian al portapapeles.

---

## 8. Hoja de bolsillo

```
IR                         LLEVAR LA VENTANA
Super + 1..0   escritorio  Super + Shift + 1..0   (te quedas)
                           Alt   + Shift + 1..0   (te vas con ella)
Super + ←→↑↓   ventana     Super + Shift + ←→↑↓   mover ventana
Super + Tab    siguiente   Super + R  →  flechas  →  Esc   (tamaño)

Super          lanzador    Super + Q        cerrar
Super + Enter  terminal    Super + `/º      terminal desplegable
Super + N      archivos    Super + Shift+E  apagar / bloquear
Super + Shift + M  minimizar (clic en su icono de la isla central para volver)
Super + F      completa    Super + M        maximizar
```

---

## 9. Cosas raras que encontré en tu config

No las cambié; te las dejo anotadas por si quieres que las arregle:

- **`Super + Espacio`** ejecuta `swaymsg …`, que es de Sway y no hace nada en
  Hyprland. El cambio de idioma funciona igual porque también está configurado
  en `kb_options = "grp:win_space_toggle"`. El atajo sobra.
- **`Super + Shift + S`** tiene 5 acciones encadenadas sobre el escritorio
  especial "magic" (mostrar, mover, mostrar, mover, mostrar). El resultado es
  confuso; la idea original parece ser "mandar la ventana a un escritorio
  escondido", pero conviene dejarlo en una sola acción.
- **`Super + Shift + C`** reinicia `wpaperd`, que ya no usas (ahora es `awww`).
- No tienes atajo de teclado para **escritorio siguiente / anterior** (solo con
  la rueda). Si te cuesta recordar números, se puede agregar
  `Super + Ctrl + ←/→` como en Windows/GNOME.
