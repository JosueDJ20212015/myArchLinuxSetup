# SDDM — Pantalla de login personalizada

* **Rol:** Tema del greeter de SDDM (pantalla de login)
* **Propósito:** Fork de `Sweet6` con fondo propio, guardado en una ruta que ningún paquete reclama — sobrevive a actualizaciones del sistema.
* **Archivos:**
   * `ejr-sddm/` — tema completo, listo para copiar
   * `sddm.conf` — config de SDDM con el tema activado

## Instalar en una máquina nueva

```bash
sudo cp -r ejr-sddm /usr/share/sddm/themes/ejr-sddm
sudo chmod 644 /usr/share/sddm/themes/ejr-sddm/assets/*
sudo cp sddm.conf /etc/sddm.conf
```

Probar sin reiniciar la sesión:

```bash
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/ejr-sddm/
```

## Cambiar el fondo por otro

1. Copia tu imagen a `ejr-sddm/assets/`
2. Edita `ejr-sddm/theme.conf`, línea `Background="assets/tu-imagen.jpg"`
3. Repite el `cp -r` de arriba y prueba con el comando de test-mode

**Tip:** guarda siempre el tema en una carpeta propia (`ejr-sddm`, no `Sweet6` directamente) — si editas el tema original, una actualización del sistema te lo revierte sin avisar.
