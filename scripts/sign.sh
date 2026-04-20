#!/usr/bin/env bash
set -euo pipefail

gpg --armor --output package/signature.asc --detach-sign package/manifest.json

echo "Signed package/manifest.json -> package/signature.asc"
