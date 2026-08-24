# Manual steps

`bootstrap.sh` handles everything scriptable. These are the GUI-only steps that
Android will never let a script do. Work top to bottom on a new device.

## 1. Before wiping the old phone

- [ ] Remove Google and Samsung accounts in Settings (or Factory Reset Protection
      locks the device on first boot)
- [ ] Confirm authenticator codes work on your main phone. **TOTP seeds do not always
      transfer and are gone permanently after a wipe.**
- [ ] Pull the SIM and microSD

## 2. First boot

- [ ] **Skip Google sign-in.** Everything needed is on F-Droid, and no Play Services
      measurably improves idle battery
- [ ] Skip app-restore and wifi-restore prompts
- [ ] Set a screen lock
- [ ] Take the pending system update
- [ ] Optional but recommended: Samsung account (email only, no phone number) and
      enable **Find My Mobile**. Without a Google account this is your only remote wipe

## 3. Android settings that decide whether any of this works

- [ ] Battery → **Battery protection ON** (85% cap). Non-negotiable on a device that
      lives on a charger
- [ ] Battery → **Adaptive battery OFF**
- [ ] Battery → **Sleeping apps / Deep sleeping apps: empty**
- [ ] Developer options → **Stay awake while charging**
- [ ] Disable bloat you will never open

## 4. F-Droid and apps

- [ ] Browser → f-droid.org → download APK → allow "install unknown apps" → install
- [ ] Let the repo sync (a few minutes on first run)
- [ ] Install: **Termux, Termux:API, Termux:Boot, Termux:Widget, Tailscale**
- [ ] **All from the same source.** Mixed F-Droid and GitHub builds have different
      signing keys and the addons silently fail
- [ ] **Open Termux:Boot once, manually.** It shows nothing but does not arm until
      launched at least once

## 5. Battery exemptions

- [ ] Settings → Apps → **Termux** → Battery → Unrestricted
- [ ] Settings → Apps → **Termux:API** → Battery → Unrestricted
- [ ] Settings → Apps → **Tailscale** → Battery → Unrestricted

## 6. Run bootstrap

```bash
pkg install -y git
git clone <your-repo-url> deck && cd deck
./bootstrap.sh DECK-02
```

Tap **Allow** when the storage permission dialog appears.

## 7. Tailscale

- [ ] Open, sign in, note the tailnet IP
- [ ] Enable **always-on VPN** in its settings

## 8. Widget

- [ ] Long-press home screen → Widgets → **Termux:Widget** → place it
- [ ] Mode scripts appear as tappable icons automatically

## 9. Wallpaper

From your laptop:

```bash
rsvg-convert -w 1080 -h 2340 assets/wallpaper.svg -o wallpaper.png
scp -P 8022 wallpaper.png <user>@<tailscale-ip>:~/storage/pictures/
```

- [ ] Set from Gallery for both home and lock screen
- [ ] Turn **off** wallpaper effects and colour-adaptive theming so black stays black

Edit `DECK-01` in the SVG first if this device has a different name.

## 10. The test that actually matters

- [ ] **Reboot. Do not touch the phone. Leave it screen-off for 2 to 3 hours.
      Then SSH in from your laptop.**

If it answers, the foundation is real. If it does not, the problem is section 3,
not your scripts. Fix it before building anything on top.

## Later, as needed

- **Aurora Store** (F-Droid) for Play-only apps. Currently that is just IP Webcam,
  needed for camera mode
- A **prepaid SIM** for tracker mode, the SMS gateway and hotspot mode. That new
  number is also what Google wants if you ever decide you do want an account
