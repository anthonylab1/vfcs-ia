#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "VFCS VERIFY: FAIL - $1" >&2
  exit 1
}

require_file() {
  local f="$1"
  [[ -f "$f" ]] || fail "falta archivo requerido: $f"
}

echo "[1/5] Comprobando archivos base..."
require_file "package/manifest.json"
require_file "package/checksums.sha512"
require_file "package/signature.asc"

echo "[2/5] Validando manifest, hashes y event_chain..."
python3 <<'PY' || exit 1
import json, hashlib, os, sys

def fail(msg):
    print(f"VFCS VERIFY: FAIL - {msg}", file=sys.stderr)
    sys.exit(1)

def sha512_file(path):
    h = hashlib.sha512()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()

def sha512_text(s):
    return hashlib.sha512(s.encode("utf-8")).hexdigest()

try:
    with open("package/manifest.json", encoding="utf-8") as f:
        manifest = json.load(f)
except Exception as e:
    fail(f"manifest.json inválido: {e}")

files = manifest.get("files")
if not isinstance(files, list) or not files:
    fail("manifest.json no contiene 'files' válido")

event_chain = manifest.get("event_chain")
if not isinstance(event_chain, list) or not event_chain:
    fail("manifest.json no contiene 'event_chain' válido")

manifest_hashes = {}
for item in files:
    path     = item.get("path")
    expected = item.get("sha512")
    if not path or not expected:
        fail("entrada inválida en manifest.files")
    if not os.path.isfile(path):
        fail(f"falta archivo listado en manifest: {path}")
    actual = sha512_file(path)
    if actual.lower() != expected.lower():
        fail(f"hash no coincide para {path}")
    manifest_hashes[path] = actual.lower()

ZERO = "0" * 128
prev_chain_expected = ZERO

for i, item in enumerate(event_chain):
    path       = item.get("path")
    event_sha  = item.get("event_sha512")
    prev_chain = item.get("prev_chain")
    chain_sha  = item.get("chain_sha512")
    if not path or not event_sha or not prev_chain or not chain_sha:
        fail(f"entrada inválida en event_chain[{i}]")
    if path not in manifest_hashes:
        fail(f"event_chain referencia archivo no declarado en files: {path}")
    if manifest_hashes[path] != event_sha.lower():
        fail(f"event_sha512 no coincide con el hash real de {path}")
    if prev_chain.lower() != prev_chain_expected.lower():
        fail(f"prev_chain inválido en {path}")
    recomputed = sha512_text(prev_chain.lower() + event_sha.lower())
    if recomputed.lower() != chain_sha.lower():
        fail(f"chain_sha512 inválido en {path}")
    prev_chain_expected = recomputed.lower()

# Verificar coherencia de CLASS.references
class_path = "package/events/0003_CLASS.json"
if class_path in manifest_hashes:
    with open(class_path, encoding="utf-8") as f:
        class_event = json.load(f)
    refs      = class_event.get("references", {})
    gen_path  = refs.get("gen_event")
    gen_hash  = refs.get("gen_event_sha512", "")
    eval_path = refs.get("eval_event")
    eval_hash = refs.get("eval_event_sha512", "")
    if not gen_path or not gen_hash or not eval_path or not eval_hash:
        fail("CLASS.references incompleto")
    if manifest_hashes.get(gen_path) != gen_hash.lower():
        fail("gen_event_sha512 no coincide con manifest")
    if manifest_hashes.get(eval_path) != eval_hash.lower():
        fail("eval_event_sha512 no coincide con manifest")
else:
    fail("CLASS no encontrado en manifest")

print("Manifest, hashes, event_chain y CLASS OK")
PY

echo "[3/5] Verificando integridad SHA-512..."
sha512sum -c package/checksums.sha512 || fail "fallo de integridad en checksums.sha512"

echo "[4/5] Verificando firma GPG..."
gpg --verify package/signature.asc package/manifest.json >/dev/null 2>&1 || fail "firma GPG inválida o no verificable"

echo "[5/5] Verificación completada."
echo "VFCS VERIFY: OK"
