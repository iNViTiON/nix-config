# Plasma's emoji picker for niri, with auto-paste. plasma-emojier copies the chosen emoji to
# the clipboard but stays open and can't type it (Wayland has no portal for that here), so
# this waits for the clipboard to change, closes the picker and presses the paste key for
# you, like Meta+. in Plasma. Closing it with Esc pastes nothing. (Picking the very same
# emoji as the one already on the clipboard isn't noticed; paste it by hand and close the
# picker.) The window is made floating by a rule in ./niri.nix.

# Terminals paste with Ctrl+Shift+V, everything else with Ctrl+V.
app_id=$(niri msg -j focused-window | jq -r '.app_id // ""')

before=$(wl-paste --no-newline 2>/dev/null || true)
plasma-emojier &
picker=$!

emoji=""
while kill -0 "$picker" 2>/dev/null; do
  now=$(wl-paste --no-newline 2>/dev/null || true)
  if [[ $now != "$before" ]]; then
    emoji=$now
    break
  fi
  sleep 0.1
done
[[ -n $emoji ]] || exit 0

# The clipboard belongs to the program that copied to it, so it would be empty once the
# picker exits. Take it over first.
printf %s "$emoji" | wl-copy
kill "$picker" 2>/dev/null || true
wait "$picker" 2>/dev/null || true

# Give the focus a moment to come back to the window that had it.
sleep 0.15
case ${app_id,,} in
  alacritty | foot | kitty | org.kde.konsole | konsole | wezterm* | xterm | org.wezfurlong.wezterm)
    wtype -M ctrl -M shift -k v -m shift -m ctrl
    ;;
  *)
    wtype -M ctrl -k v -m ctrl
    ;;
esac
