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

GitHub is the source of truth. HAOS's `/config/esphome` is a pull-only mirror of
`main`.

- **Active dev** (VM 151 workspace): `esphome config` validates against the real
  `secrets.yaml`, which the estate's render agent delivers into the checkout
  (gitignored; see `secrets.yaml.example` for its keys). Builds and installs from
  VM 151 come with its own Device Builder, documented here once it exists.
- **Routine version bumps and real builds**: the HAOS ESPHome add-on stays
  installed and enabled as a trigger and console, paired to the ESPHome build
  server (LXC 252), which does the compile; the add-on OTAs.

`secrets.yaml` is rendered from Infisical (`core-infra` `/wifi/potter_net/` +
`smarthome-selfhosted` `/esphome/`) by the estate's `yaml-render-agent`;
per-device fallback IPs come from `dahome_private_config`'s `host_config.env`.

## Critical devices

Deploys to these are **operator actions**, even if Claude gets a broader `esphome
run` grant:

* Fireplace
* Humidor
* RO
* range hood

`esphome-proto` and `esphome-desk` are prototypes and are freer.
