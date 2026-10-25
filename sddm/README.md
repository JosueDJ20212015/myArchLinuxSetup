# SDDM — Pantalla de login personalizada

* **Rol:** Tema del greeter de SDDM (pantalla de login)
* **Propósito:** Fork de `Sweet6` con fondo propio, guardado en una ruta que ningún paquete reclama — sobrevive a actualizaciones del sistema.
* **Archivos:**
   * `ejr-sddm/` — tema completo, listo para copiar
   * `sddm.conf` — config de SDDM con el tema activado
   * `faces/josuepc.face.icon` — avatar del login (inicial estilo islas)

## Instalar en una máquina nueva

```bash
# -T: copia el contenido encima (sin -T, si el tema ya existe crea ejr-sddm/ejr-sddm)
sudo cp -rT ejr-sddm /usr/share/sddm/themes/ejr-sddm
sudo chmod 644 /usr/share/sddm/themes/ejr-sddm/assets/*
sudo cp sddm.conf /etc/sddm.conf
# Avatar (SDDM no puede leer ~/.face.icon porque el home es 700)
sudo install -m 644 faces/josuepc.face.icon /usr/share/sddm/faces/josuepc.face.icon
```

Probar sin reiniciar la sesión:

```bash
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/ejr-sddm/
```

## Cambiar el fondo por otro

1. Copia tu imagen a `ejr-sddm/assets/`
2. Edita `ejr-sddm/theme.conf`, línea `Background="assets/tu-imagen.jpg"`
3. Repite el `cp -rT` de arriba y prueba con el comando de test-mode

**Tip:** guarda siempre el tema en una carpeta propia (`ejr-sddm`, no `Sweet6` directamente) — si editas el tema original, una actualización del sistema te lo revierte sin avisar.
