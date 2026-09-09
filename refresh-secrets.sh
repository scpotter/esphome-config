#!/bin/bash
set -euo pipefail

# esphome-config -- render secrets.yaml (tier 4 of the four-tier secrets model).
#
# Runs on the VM 151 HOST, invoked by launch.sh (cold start) or by the 20-min
# esphome-builder.timer on the host (which also picks up a changed host_config.env
# -- the post-commit hook in dahome_private_config only prints a reminder).
# Renders ./secrets.yaml in place -- no compose restart; the running Device
# Builder re-reads it on the next compile. Also renders ./esphome-builder/.env
# with the dashboard credentials and the trusted-domains list.
#
# secrets.yaml is a gitignored, mode-0600 file. It is recreated on every run and
# shredded by stop.sh; it is never committed and never in a mirror-clone DR copy.
#
# The esphome CLI in the VM 151 container does NOT run this -- it has no
# launch-Esphome credential. It uses a copy of secrets.yaml.example for
# config/compile checks; real builds and OTA go through the stack.
#
# Invoked by dahome_private_config/estate/hosts/stack-launch.sh, which pulls this
# repo fresh and writes ./host_config.env (the bare contract in example.env)
# before exec'ing launch.sh.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Bare contract (example.env): the Infisical project IDs + coordinates + the
# per-device fallback IPs (DEV_*_IP, private config, not secret). `set -a` so a
# sourced var without its own `export` still reaches the render below.
set -a
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/host_config.env"
set +a

# Bootstrap credential -- this deployment's Infisical identity (launch-Esphome ->
# LAUNCH_ESPHOME_*). Never in git; lives only on this host, regenerated on rebuild.
# shellcheck source=/dev/null
source ~/.secrets/infisical.env

command -v infisical >/dev/null || {
  echo "refresh-secrets: infisical CLI missing -- see secrets-routing.md bootstrap" >&2
  exit 1
}

export INFISICAL_TOKEN
INFISICAL_TOKEN=$(infisical login \
  --method=universal-auth \
  --client-id="${LAUNCH_ESPHOME_CLIENT_ID}" \
  --client-secret="${LAUNCH_ESPHOME_CLIENT_SECRET}" \
  --domain="${INFISICAL_API_URL}" \
  --silent --plain)

# One export per Infisical folder, captured then eval'd (not eval'd straight off
# the substitution) so a failed export trips `set -e` rather than rendering an
# empty secret. The two folders share no key names, so no rename needed.
_pull() {  # _pull <projectId> <path>
  infisical export --domain="${INFISICAL_API_URL}" \
    --projectId="$1" --env=prod --path="$2" --format=dotenv-export
}

WIFI_EXPORT=$(_pull "${CORE_INFRA_PROJECT_ID}" "/wifi/potter_net/")
eval "$WIFI_EXPORT"                       # -> wifi_ssid, wifi_password
ESP_EXPORT=$(_pull "${SMARTHOME_SELFHOSTED_PROJECT_ID}" "/esphome/")
eval "$ESP_EXPORT"                        # -> API_key, ESPadmin_password,
                                          #    ota_password, builder_un, builder_pw

# --- render secrets.yaml (the !secret values the device YAML resolves) --------
# The values below (wifi_ssid, API_key, builder_un, ...) are set by the two
# `eval`s above; shellcheck cannot see through eval.
umask 077
# shellcheck disable=SC2154
{
  printf '# rendered by refresh-secrets.sh -- do not edit, do not commit\n'
  printf 'wifi_ssid: "%s"\n'         "${wifi_ssid}"
  printf 'wifi_password: "%s"\n'     "${wifi_password}"
  printf 'API_key: "%s"\n'           "${API_key}"
  printf 'ESPadmin_password: "%s"\n' "${ESPadmin_password}"
  printf 'ota_password: "%s"\n'      "${ota_password}"
  # per-device fallback IPs: DEV_HUMIDOR_IP -> humidor_ip (added in slice 6 step 22)
  for _v in "${!DEV_@}"; do
    _name=$(printf '%s' "${_v#DEV_}" | sed 's/_IP$//' | tr '[:upper:]' '[:lower:]')
    printf '%s_ip: "%s"\n' "${_name}" "${!_v}"
  done
} > "${SCRIPT_DIR}/secrets.yaml"
chmod 600 "${SCRIPT_DIR}/secrets.yaml"

# --- render esphome-builder/.env (Device Builder dashboard creds + trusted
#     domains) --- builder_un / builder_pw are set by the /esphome/ eval above;
#     TRUSTED_DOMAINS comes from host_config.env (ESPHOME_BUILDER_TRUSTED_DOMAINS,
#     prefix stripped by stack-launch.sh) -- the hostnames/IPs allowed as the
#     Host header on the dashboard + remote-build peer link. Not a secret, but
#     rendered here so it stays out of the public compose file.
# shellcheck disable=SC2154
{
  printf 'ESPHOME_USERNAME=%s\n' "${builder_un}"
  printf 'ESPHOME_PASSWORD=%s\n' "${builder_pw}"
  printf 'ESPHOME_TRUSTED_DOMAINS=%s\n' "${TRUSTED_DOMAINS:?ESPHOME_BUILDER_TRUSTED_DOMAINS missing from host_config.env}"
} > "${SCRIPT_DIR}/esphome-builder/.env"
chmod 600 "${SCRIPT_DIR}/esphome-builder/.env"

echo "refresh-secrets: secrets.yaml + esphome-builder/.env rendered"
