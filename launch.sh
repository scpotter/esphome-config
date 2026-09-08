#!/bin/bash
set -euo pipefail

# esphome-config -- bring up the esphome-builder Device Builder stack on the
# VM 151 HOST. Invoked by dahome_private_config/estate/hosts/stack-launch.sh,
# which pulls this repo fresh and writes ./host_config.env before exec'ing this.
# Never run inside the code-server container.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

set -a
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/host_config.env"
set +a

# Render secrets.yaml + esphome-builder/.env from Infisical (cold start).
"${SCRIPT_DIR}/refresh-secrets.sh"

cd "${SCRIPT_DIR}"
exec docker compose -f esphome-builder/compose.yaml up -d
