# Deck: system design

A repurposed Android phone running as a battery-backed, LTE-connected Linux node.
This document exists so the thing stays comprehensible in six months.

## What this is actually good at

Not a laptop replacement. Not a USB host. It is a small, always-on, network-reachable
device with a modem, GPS, camera, microphone and a battery, in a sealed unit.

Everything it is good at follows from that sentence. Everything that has ever been
frustrating about it came from ignoring it.

## Layer model

```
  Android          owns hardware   camera, mic, GPS, modem, radios, USB
     |             exposes it over a socket or via Termux:API
  Termux (native)  owns reach      sshd, Tailscale, wake lock, mode state
     |             always running, never stopped by a mode
  Debian (proot)   owns logic      services, analysis, anything scriptable
```

**Rule 1: Android owns hardware, Linux owns logic.**
If a peripheral is hard to reach from Linux, the answer is not root. The answer is an
Android app that exposes it on a socket, and Linux consumes that socket. This is why
the camera is IP Webcam over HTTP and not `/dev/video0`, and why an OBD reader should
be the WiFi model and not the Bluetooth one.

**Rule 2: Base never stops.**
sshd, Tailscale, wake lock and the mode notification run in every mode. They are how
you reach the device regardless of what it is doing. A mode that stops them is a bug.

## Modes

**Rule 3: a mode is a physical situation, not a feature.**

Physical situation is what actually changes power budget, data budget, reachability
and friction. Feature-shaped modes multiply without limit and then rot unused.

| Mode | Where the device physically is |
|---|---|
| `base`    | resting, anywhere |
| `docked`  | on the desk, mains power, good wifi |
| `camera`  | placed somewhere, watching |
| `tracker` | in a pocket or bag |
| `hotspot` | with you, sharing data |
| `car`     | in the car (needs a WiFi ELM327) |

If a new idea is not a place, it is not a mode. It is either:

- a **Base service** (always on: uptime monitoring, SMS gateway), or
- a **script you invoke** (transcribe a file, run an nmap sweep, fire the panic alert).

Check which of the three it is before writing anything.

**The test a mode must pass:** if using it requires a ritual you must remember every
time (mount it, aim it, plug it in, start it), you will stop doing it within two weeks.
A dashcam mode failed this test. A meter reader passes it, because its setup cost is
paid once and is then zero forever.

## State

One state file, one writer at a time:

```
~/.deck/mode      # a single lowercase word: base, camera, tracker, ...
```

Everything else derives from it. The notification renders it, `.bashrc` prints it on
SSH login, and mode scripts set it. Nothing else stores mode state anywhere.

Every mode script has the same shape, no exceptions:

```
  stop what should not be running  ->  set state  ->  start what should  ->  notify
```

`mode_enter` in `lib/common.sh` does the first two. Keep it that way.

## Where work runs

**Rule 4: capture and decide on the deck, think on the laptop.**

| On the deck, always | Offloaded to the laptop |
|---|---|
| Capture (camera, mic, GPS, sensors) | Whisper transcription |
| Real-time triggers (person detection, sound classification, VAD) | Embedding and indexing |
| Alerting (SMS, push) | LLM summarisation |
| | Video re-encoding |

The split is **latency, not capability**. Anything whose value is being immediate runs
locally. Anything batch, where nobody is waiting, gets offloaded. Conveniently the
latency-critical models are also the cheap ones.

Offload transport is **Syncthing, used as a queue**. Deck writes to `inbox/`, the
laptop processes and writes to `outbox/`, it syncs back. No custom job queue, no
daemon to babysit, survives either machine being offline for days.

Exception: an unattended remote deployment with no companion machine does everything
locally and slowly, because there is no alternative and nothing there is latency-
sensitive either.

## Data discipline

**Rule 5: never stream continuously over the cellular link.**

1080p MJPEG is roughly 1.8 GB/hour. Even 720p H.264 at 1 Mbps is about 10 GB/day.
Continuous streaming over a mobile bundle is not expensive, it is *not viable*.

The pattern that works: record locally to storage, stream live only on demand, and
push stills or short clips for alerts. A JPEG is tens of kilobytes; you can send
thousands for the cost of one minute of video.

## Constraints (do not rediscover these)

The device is unrooted by design, so Android's sandbox is enforced. This is the deal:
a fully working phone in exchange for a Linux guest with walls.

| Wall | Consequence | Work around it by |
|---|---|---|
| No `/dev/video0` | USB webcams invisible to Linux | Android app streaming RTSP |
| No `/dev/ttyUSB0` | USB serial painful (`termux-usb` fd, permission dialog per reconnect, no DTR auto-reset) | Do it over the network (ESP32 OTA, WiFi ELM327) |
| No ports < 1024 | No DNS on 53, no privileged binds | Everything on high ports |
| No iptables/nftables | No NAT or firewall rules in Linux | Android owns routing and NAT |
| No raw sockets | nmap is TCP-connect only, no tcpdump capture, no ARP tooling | Accept it; recon is inventory, not packet work |
| No monitor mode | No wifi injection, ever | Not solvable on this hardware |
| No NNAPI from proot | ML inference is CPU-only | Nano models at 1-2 fps, or do it in an Android app |
| microSD shares SIM 2 slot | Card or dual SIM, not both | Choose the card |
| No DP Alt Mode | No wired external display, at all | The laptop is the screen |

## Hardware conflicts

- **The wifi radio is single-purpose.** Hotspot, WiFi ELM327 and travel router all
  want it. One at a time.
- **Battery is the binding constraint on every mobile mode.** A power bank does more
  for this build than any other purchase.
- **Heat kills.** Sustained capture plus charging plus sun degrades the battery.
  Battery protection at 85% is not optional on a device that lives on a charger.

## Layout

```
  ~/.deck/
    mode              state, one word
    deck.conf         per-device config (DECK_NAME)
    notify            renders the persistent notification
    lib/common.sh     shared functions
  ~/.shortcuts/       mode scripts (Termux:Widget reads this dir)
  ~/.termux/boot/     boot scripts (Termux:Boot runs these in name order)
```

Runtime lives in `~/.deck`. The repo is the source of truth; `bootstrap.sh` installs
from repo to runtime and is safe to re-run.

## Adding a mode

1. Confirm it is a *place*, not a feature. If not, it is a Base service or a script.
2. Confirm it passes the friction test.
3. Copy `modes/base` as a template. Keep the four-step shape.
4. Add a `--buttonN` entry to `notify` if it deserves one-tap access.
5. Re-run `bootstrap.sh`.

Do not build a mode speculatively. Build it the day you have the reason.
