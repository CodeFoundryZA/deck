#!/data/data/com.termux/files/usr/bin/sh
# Provision a deck from a fresh Termux install. Safe to re-run.
#
#   pkg install -y git && git clone <repo> && cd deck && ./bootstrap.sh [NAME]
#
# GUI-only steps are NOT here because they cannot be scripted. See MANUAL.md.

set -eu

REPO="$(cd "$(dirname "$0")" && pwd)"
DECK_HOME="$HOME/.deck"

say() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

[ -d /data/data/com.termux ] || die "must run inside Termux"

# --- name -------------------------------------------------------------------
DECK_NAME="${1:-}"
if [ -z "$DECK_NAME" ] && [ -f "$DECK_HOME/deck.conf" ]; then
    . "$DECK_HOME/deck.conf"
fi
if [ -z "${DECK_NAME:-}" ]; then
    printf 'Device name [DECK-01]: '
    read -r DECK_NAME || true
    DECK_NAME="${DECK_NAME:-DECK-01}"
fi

say "provisioning $DECK_NAME"

# --- packages ---------------------------------------------------------------
say "packages"
pkg update -y
pkg install -y openssh mosh termux-api proot-distro termux-services jq git

# --- storage (shows an Android permission dialog: tap Allow) ----------------
if [ ! -d "$HOME/storage" ]; then
    say "storage permission"
    termux-setup-storage
    sleep 3
fi

# --- layout -----------------------------------------------------------------
say "layout"
mkdir -p "$DECK_HOME/lib" "$HOME/.shortcuts" "$HOME/.termux/boot"
printf 'DECK_NAME=%s\n' "$DECK_NAME" > "$DECK_HOME/deck.conf"

install -m 644 "$REPO/lib/common.sh" "$DECK_HOME/lib/common.sh"
install -m 700 "$REPO/notify"        "$DECK_HOME/notify"

# --- modes -> ~/.shortcuts (Termux:Widget reads this dir, shows filenames) ---
say "modes"
for m in "$REPO"/modes/*; do
    [ -f "$m" ] || continue
    n=$(basename "$m")
    label=$(printf '%s' "$n" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')
    install -m 700 "$m" "$HOME/.shortcuts/$label"
    printf '    %s\n' "$label"
done
chmod 700 "$HOME/.shortcuts"

# --- boot -------------------------------------------------------------------
say "boot hook"
cat > "$HOME/.termux/boot/00-base" <<'EOF'
#!/data/data/com.termux/files/usr/bin/sh
. "$HOME/.deck/lib/common.sh"
deck_base_up
sleep 5
notify_update
EOF
chmod 700 "$HOME/.termux/boot/00-base"

# --- login banner -----------------------------------------------------------
grep -q 'deck:' "$HOME/.bashrc" 2>/dev/null || \
    echo 'echo "deck: $(cat ~/.deck/mode 2>/dev/null || echo unknown)"' >> "$HOME/.bashrc"

# --- state ------------------------------------------------------------------
[ -f "$DECK_HOME/mode" ] || echo base > "$DECK_HOME/mode"
: > "$DECK_HOME/running"

# --- debian -----------------------------------------------------------------
if [ -d "$PREFIX/var/lib/proot-distro/installed-rootfs/debian" ]; then
    say "debian already installed"
else
    say "debian (slow, several minutes)"
    proot-distro install debian
fi

# --- go ---------------------------------------------------------------------
say "entering base mode"
"$HOME/.shortcuts/Base"

cat <<EOF

  $DECK_NAME provisioned.

  SSH:  ssh -p 8022 $(whoami)@<ip>

  Remaining steps cannot be scripted. See MANUAL.md:
    [ ] Tailscale from F-Droid, sign in, always-on VPN
    [ ] Battery -> Unrestricted for Termux, Termux:API, Tailscale
    [ ] Open Termux:Boot once, manually
    [ ] Place the Termux:Widget on the home screen
    [ ] Wallpaper from assets/wallpaper.svg
    [ ] Reboot, wait 2-3 hours screen-off, then SSH in

EOF
