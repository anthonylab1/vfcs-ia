#!/usr/bin/env bash
set -euo pipefail

./scripts/export_package.sh
./scripts/verify.sh

echo "VFCS ROUNDTRIP: OK"
