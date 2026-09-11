#!/usr/bin/env python3
"""
Parcheo idempotente de --unrestricted en scripts de GRUB con dueno de
paquete (10_linux, 30_os-prober), ninguno declarado como Backup File.

Se ejecuta dos veces: una vez ahora (aplicacion inicial) y automaticamente
via el hook de pacman 99-ejr-grub-unrestricted.hook tras cada actualizacion
del paquete grub, para reaplicar si el paquete restauro su version de
fabrica.

No falla en silencio: si el patron esperado no aparece exactamente una vez
(y el parche tampoco esta ya aplicado), imprime un aviso explicito y sale
con codigo distinto de cero, para que el hook de pacman lo muestre en
pantalla durante la transaccion.
"""
import sys

PATCHES = [
    (
        "/etc/grub.d/10_linux",
        "\\$menuentry_id_option 'gnulinux-simple-$boot_device_id'",
        "--unrestricted \\$menuentry_id_option 'gnulinux-simple-$boot_device_id'",
    ),
    (
        "/etc/grub.d/30_os-prober",
        "$CLASS --class os \\$menuentry_id_option 'osprober-efi-",
        "$CLASS --class os --unrestricted \\$menuentry_id_option 'osprober-efi-",
    ),
]


def patch_one(path, old, new):
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    if content.count(new) >= 1:
        print(f"YA APLICADO: {path} ya tiene el parche, no se toca.")
        return True

    count = content.count(old)
    if count == 1:
        content = content.replace(old, new)
        with open(path, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"OK: {path} parcheado.")
        return True

    print(f"!!! AVISO: {path} -- patron esperado no encontrado "
          f"(coincidencias: {count}, se esperaba 1).")
    print(f"!!! El script probablemente cambio en una actualizacion de grub.")
    print(f"!!! Arch/Windows pueden estar pidiendo contrasena de nuevo sin aviso.")
    print(f"!!! Revisar manualmente y actualizar este script si hace falta.")
    return False


def main():
    ok = True
    for path, old, new in PATCHES:
        if not patch_one(path, old, new):
            ok = False
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
