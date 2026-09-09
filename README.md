# ESPhome projects

# Repo Structure
```
./               is my /esphome folder containing YAML config for my devices
/common         includes templates used by devices
/build-(name)   device build details like wiring diagrams and component references
```
There are two special devices:
* Blank is a minimal device that works with the tempalate. Copied into new devices.
* Proto is a dev board on my bench before starting a build

## Build & deploy

Firmware compiles on **VM 151** (the `esphome-builder` Device Builder stack, not
HAOS). GitHub is the source of truth; HAOS's `/config/esphome` and the VM 151
stack are both pull-only mirrors of `main`.

- **VM 151 host** brings the stack up with `dahome_private_config/estate/hosts/stack-launch.sh esphome-builder`
  (which runs `launch.sh` → `refresh-secrets.sh` → `docker compose`). `stop.sh`
  shreds the rendered secrets.
- **Active dev** (VM 151 workspace): `esphome config` / `esphome compile` against
  a `cp secrets.yaml.example secrets.yaml` copy — config/YAML checks only; the
  binary isn't flashable with real credentials.
- **Routine version bumps**: the HAOS ESPHome add-on stays installed + enabled as
  a trigger/console, paired to the VM 151 stack (`vscode.scpotter.com:6055`)
  which does the compile; the add-on OTAs.
- **Real builds + OTA** go through the VM 151 stack — the single compile authority.

`secrets.yaml` is gitignored. On the host it is rendered from Infisical
(`core-infra` `/wifi/potter_net/` + `smarthome-selfhosted` `/esphome/`) by
`refresh-secrets.sh`; per-device fallback IPs come from
`dahome_private_config`'s `host_config.env`. See `secrets.yaml.example` and
`example.env`.

## Critical devices

Deploys to these are **operator actions**, even if Claude gets a broader `esphome
run` grant:

* Fireplace
* Humidor
* RO
* range hood

`esphome-proto` and `esphome-desk` are prototypes and are freer.
