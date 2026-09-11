#!/usr/bin/env python3
"""
Valida el hash PBKDF2 escrito en /etc/grub.d/05_ejr_grub_password contra la
contrasena que se teclee, replicando el mismo PBKDF2-HMAC-SHA512 que usa
GRUB. El hash se lee directo del archivo -- nunca se copia ni se pega a
mano, evitando exactamente el fallo del intento anterior.
"""
import hashlib
import getpass
import re
import sys

PATH = "/etc/grub.d/05_ejr_grub_password"

with open(PATH, "r", encoding="utf-8") as f:
    content = f.read()

m = re.search(
    r"password_pbkdf2\s+admin\s+(grub\.pbkdf2\.sha512\.\d+\.[0-9A-Fa-f]+\.[0-9A-Fa-f]+)",
    content,
)
if not m:
    print(f"NO SE ENCONTRO password_pbkdf2 en {PATH}")
    sys.exit(1)

s = m.group(1)
parts = s.split(".")
if len(parts) != 6:
    print(f"FORMATO INVALIDO: se esperaban 6 campos separados por '.', hay {len(parts)}")
    print("(esto es exactamente el bug del intento anterior: prefijo duplicado)")
    sys.exit(1)

algo, iters, salt_hex, hash_hex = parts[2], int(parts[3]), parts[4], parts[5].lower()
salt = bytes.fromhex(salt_hex)

pw = getpass.getpass("Contrasena a verificar: ")
derived = hashlib.pbkdf2_hmac(algo, pw.encode(), salt, iters, dklen=len(hash_hex) // 2)

if derived.hex() == hash_hex:
    print("VALIDA")
else:
    print("NO COINCIDE")
    sys.exit(1)
