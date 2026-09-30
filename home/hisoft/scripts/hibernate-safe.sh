# Hibernate with Bitwarden running. Bitwarden keeps its vault keys in secret memory
# (memfd_secret), and the kernel refuses to hibernate while any program holds some:
# "disk" disappears from /sys/power/state and `systemctl hibernate` fails with "Sleep verb
# 'hibernate' is not configured or configuration is not supported by kernel". So: quit
# Bitwarden, hibernate, and start it again after resume (the vault has to be unlocked again).

bitwarden='bitwarden-desktop-[^/]*/opt/Bitwarden'
unit=app-bitwarden@autostart.service

start_bitwarden() {
  # The login autostart unit, so it starts to the tray as at login.
  systemctl --user start --no-block "$unit" 2>/dev/null ||
    (setsid -f bitwarden --autostart >/dev/null 2>&1 || true)
}

was_running=false
if pgrep -u "$UID" -f "$bitwarden" >/dev/null; then
  was_running=true
  systemctl --user stop "$unit" 2>/dev/null || true
  pkill -u "$UID" -f "$bitwarden" || true
  # The kernel allows hibernation again once the last secret memory is freed.
  for ((i = 0; i < 50; i++)); do
    grep -q disk /sys/power/state && break
    sleep 0.2
  done
fi

if [[ $was_running == true ]]; then
  # Wait for logind's "woke up" signal, then start Bitwarden. Started before hibernating
  # so the signal can't be missed; runs on its own so this script can return.
  (
    exec 3< <(gdbus monitor --system --dest org.freedesktop.login1 \
      --object-path /org/freedesktop/login1)
    monitor=$!
    while read -r line <&3; do
      if [[ $line == *"PrepareForSleep (false,)"* ]]; then
        start_bitwarden
        break
      fi
    done
    kill "$monitor" 2>/dev/null || true
  ) >/dev/null 2>&1 &
  waiter=$!
  disown "$waiter"
fi

if ! systemctl hibernate; then
  if [[ $was_running == true ]]; then
    pkill -P "$waiter" 2>/dev/null || true
    kill "$waiter" 2>/dev/null || true
    start_bitwarden
  fi
  exit 1
fi
