#!/bin/bash
set -euo pipefail

# esphome-config -- stop the esphome-builder stack and shred the rendered
# secrets. Run on the VM 151 HOST.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

docker compose -f esphome-builder/compose.yaml down || true

# shred the rendered secrets; leave an empty secrets.yaml so a stale bind-mount
# reference (if the stack is somehow still up) resolves to nothing sensitive.
[ -f secrets.yaml ] && shred -u secrets.yaml
: > secrets.yaml && chmod 600 secrets.yaml
[ -f esphome-builder/.env ] && shred -u esphome-builder/.env

echo "stop: stack down, secrets shredded"
