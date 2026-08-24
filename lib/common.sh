# Deck shared functions. Sourced by mode scripts and by notify.
# Keep this small and obvious. A clever shell framework is its own spaghetti.

DECK_HOME="$HOME/.deck"
DECK_MODE_FILE="$DECK_HOME/mode"
DECK_RUNNING="$DECK_HOME/running"

[ -f "$DECK_HOME/deck.conf" ] && . "$DECK_HOME/deck.conf"
DECK_NAME="${DECK_NAME:-DECK-01}"

deck_log() {
    printf '%s  %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$DECK_HOME/deck.log"
}

deck_mode() {
    cat "$DECK_MODE_FILE" 2>/dev/null || echo unknown
}

# Base services. Started by every mode. Stopped by none. See DESIGN.md rule 2.
deck_base_up() {
    pgrep -x sshd >/dev/null 2>&1 || sshd
    termux-wake-lock
}

# Start a long-running process owned by the current mode, and register it
# so the next mode switch can stop it.
#   deck_svc_start <label> <command> [args...]
deck_svc_start() {
    _label="$1"; shift
    "$@" >/dev/null 2>&1 &
    printf '%s %s\n' "$_label" "$!" >> "$DECK_RUNNING"
    deck_log "started $_label (pid $!)"
}

# Stop everything the previous mode registered. Base is untouched.
deck_svc_stop_all() {
    [ -f "$DECK_RUNNING" ] || return 0
    while read -r _label _pid; do
        [ -n "${_pid:-}" ] || continue
        kill "$_pid" 2>/dev/null && deck_log "stopped $_label (pid $_pid)"
    done < "$DECK_RUNNING"
    : > "$DECK_RUNNING"
}

# Every mode script begins with this: stop others, then set state.
# The mode then starts its own services and calls notify_update.
mode_enter() {
    deck_svc_stop_all
    printf '%s\n' "$1" > "$DECK_MODE_FILE"
    deck_base_up
    deck_log "mode -> $1"
}

notify_update() {
    "$DECK_HOME/notify"
}
