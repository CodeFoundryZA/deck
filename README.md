# deck

Turning a retired Android phone into a battery-backed, LTE-connected Linux node.
Unrooted, so it stays a fully working phone underneath.

- **[DESIGN.md](DESIGN.md)** — architecture, the five rules, and the Android walls
  documented so you never rediscover them
- **[MANUAL.md](MANUAL.md)** — the GUI steps a script cannot do
- **bootstrap.sh** — everything a script can do, idempotent

## Provisioning a new deck

Do sections 1 to 5 of `MANUAL.md`, then:

```bash
pkg install -y git
git clone <your-repo-url> deck && cd deck
./bootstrap.sh DECK-02
```

Then finish sections 7 to 10.

## Layout

```
  bootstrap.sh        provisioner, safe to re-run
  notify              persistent notification / mode switcher
  lib/common.sh       shared functions
  modes/              one file per mode -> installed to ~/.shortcuts
  assets/wallpaper.svg
```

Repo is the source of truth. `~/.deck` is runtime. Never edit runtime directly;
edit here and re-run `bootstrap.sh`.

## Adding a mode

Read the "Adding a mode" section of DESIGN.md first. The short version:

1. Is it a **place**? If not, it is a Base service or a script, not a mode.
2. Does it pass the friction test? If using it needs a ritual you must remember
   every time, you will stop within two weeks.
3. Copy `modes/base`, keep the four-step shape.
4. Re-run `bootstrap.sh`.

## Status

| Mode | State |
|---|---|
| `base` | done |
| `camera` | next, needs IP Webcam via Aurora Store |
| `tracker` | needs a SIM |
| `docked` | when other modes are producing data worth processing |
| `car` | when a WiFi ELM327 arrives. No camera, see DESIGN.md |
