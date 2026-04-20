#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "VFCS EXPORT: FAIL - $1" >&2
  exit 1
}

require_file() {
  local f="$1"
  [[ -f "$f" ]] || fail "falta archivo requerido: $f"
}

echo "[1/6] Comprobando estructura base..."
require_file "package/policy.json"
require_file "package/system_under_test.json"
require_file "package/events/0001_GEN.json"
require_file "package/events/0002_EVAL.json"
require_file "package/events/0003_CLASS.json"

echo "[2/6] Generando checksums.sha512..."
sha512sum \
  package/system_under_test.json \
  package/policy.json \
  package/events/0001_GEN.json \
  package/events/0002_EVAL.json \
  package/events/0003_CLASS.json \
  > package/checksums.sha512

echo "[3/6] Construyendo manifest.json..."
python3 <<'PY'
import json, hashlib, uuid
from datetime import datetime, timezone

FILES = [
    "package/system_under_test.json",
    "package/policy.json",
    "package/events/0001_GEN.json",
    "package/events/0002_EVAL.json",
    "package/events/0003_CLASS.json",
]

EVENTS = [
    "package/events/0001_GEN.json",
    "package/events/0002_EVAL.json",
    "package/events/0003_CLASS.json",
]

ZERO = "0" * 128

def sha512_file(path):
    h = hashlib.sha512()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()

def sha512_text(s):
    return hashlib.sha512(s.encode("utf-8")).hexdigest()

files_block = []
for path in FILES:
    files_block.append({"path": path, "sha512": sha512_file(path)})

event_chain = []
prev_chain = ZERO
for path in EVENTS:
    event_sha = sha512_file(path)
    chain_sha = sha512_text(prev_chain + event_sha)
    event_chain.append({
        "path": path,
        "event_sha512": event_sha,
        "prev_chain": prev_chain,
        "chain_sha512": chain_sha
    })
    prev_chain = chain_sha

manifest = {
    "schema_version": "vfcs-vdp-manifest-0.2",
    "package_id": str(uuid.uuid4()),
    "created_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "signing": {
        "method": "gpg_detached_signature",
        "signature_file": "signature.asc",
        "signer_key_fingerprint": "PENDING",
        "note": "Run ./scripts/sign.sh to generate a real signature."
    },
    "files": files_block,
    "event_chain": event_chain
}

with open("package/manifest.json", "w", encoding="utf-8") as f:
    json.dump(manifest, f, indent=2, ensure_ascii=False)
    f.write("\n")

with open(".export_hashes_tmp.json", "w", encoding="utf-8") as f:
    json.dump({item["path"]: item["sha512"] for item in files_block}, f)
PY

echo "[3b/6] Verificando coherencia de CLASS.references..."
python3 <<'PY'
import json, sys, os

def fail(msg):
    print(f"VFCS EXPORT: FAIL - {msg}", file=sys.stderr)
    sys.exit(1)

with open(".export_hashes_tmp.json") as f:
    computed = json.load(f)

with open("package/events/0003_CLASS.json", encoding="utf-8") as f:
    class_event = json.load(f)

refs = class_event.get("references", {})
gen_path  = refs.get("gen_event")
gen_hash  = refs.get("gen_event_sha512", "")
eval_path = refs.get("eval_event")
eval_hash = refs.get("eval_event_sha512", "")

if computed.get(gen_path, "").lower() != gen_hash.lower():
    fail("gen_event_sha512 en CLASS no coincide")

if computed.get(eval_path, "").lower() != eval_hash.lower():
    fail("eval_event_sha512 en CLASS no coincide")

os.remove(".export_hashes_tmp.json")
print("CLASS.references coherente con hashes calculados")
PY

echo "[4/6] Regenerando checksums.sha512 incluyendo manifest.json..."
sha512sum \
  package/system_under_test.json \
  package/policy.json \
  package/events/0001_GEN.json \
  package/events/0002_EVAL.json \
  package/events/0003_CLASS.json \
  package/manifest.json \
  > package/checksums.sha512

echo "[5/6] Firmando manifest.json..."
./scripts/sign.sh

echo "[6/6] Export completado."
echo "VFCS EXPORT: OK"
