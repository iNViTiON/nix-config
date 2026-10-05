# next-boot.sh — select next boot entry on NixOS (one-time, not permanent)
# Packaged by ../scripts.nix; writeShellApplication adds the shebang and
# `set -o errexit -o nounset -o pipefail`.

# Re-run as root when needed (bootctl can't read the EFI partition otherwise).
if [[ $EUID -ne 0 ]]; then
  exec /run/wrappers/bin/sudo "$0" "$@"
fi

# Requires: systemd-boot (bootctl) or grub
# Auto-detect bootloader
if command -v bootctl &>/dev/null && bootctl is-installed &>/dev/null; then
  BOOTLOADER="systemd-boot"
elif command -v grub-reboot &>/dev/null; then
  BOOTLOADER="grub"
else
  echo "Error: No supported bootloader found (systemd-boot or GRUB)." >&2
  exit 1
fi

if [[ "$BOOTLOADER" == "systemd-boot" ]]; then
  # List all boot entries
  mapfile -t entries < <(bootctl list --no-pager 2>/dev/null | grep -E "^\s+title:|^\s+id:" | awk '{print $2}' | paste - -)
  # Better approach: parse entry IDs and titles together
  declare -a ids titles
  while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]+id:[[:space:]]+(.+)$ ]]; then
      ids+=("${BASH_REMATCH[1]}")
    elif [[ "$line" =~ ^[[:space:]]+title:[[:space:]]+(.+)$ ]]; then
      titles+=("${BASH_REMATCH[1]}")
    fi
  done < <(bootctl list --no-pager 2>/dev/null)

  if [[ ${#ids[@]} -eq 0 ]]; then
    echo "No boot entries found." >&2
    exit 1
  fi

  echo "Available boot entries:"
  for i in "${!ids[@]}"; do
    printf "  [%d] %s  (%s)\n" "$((i+1))" "${titles[$i]:-unknown}" "${ids[$i]}"
  done

  echo
  read -rp "Select entry [1-${#ids[@]}]: " choice

  if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#ids[@]} )); then
    echo "Invalid selection." >&2
    exit 1
  fi

  selected_id="${ids[$((choice-1))]}"
  echo "Setting next boot to: ${titles[$((choice-1))]} ($selected_id)"
  bootctl set-oneshot "$selected_id"
  echo "Done. This applies only to the next boot."

elif [[ "$BOOTLOADER" == "grub" ]]; then
  grub_cfg="/boot/grub/grub.cfg"
  [[ ! -f "$grub_cfg" ]] && grub_cfg="/boot/grub2/grub.cfg"

  mapfile -t entries < <(grep -oP "(?<=menuentry ')[^']+" "$grub_cfg" 2>/dev/null || \
                          grep -oP '(?<=menuentry ")[^"]+' "$grub_cfg" 2>/dev/null)

  if [[ ${#entries[@]} -eq 0 ]]; then
    echo "No GRUB entries found in $grub_cfg" >&2
    exit 1
  fi

  echo "Available boot entries:"
  for i in "${!entries[@]}"; do
    printf "  [%d] %s\n" "$((i+1))" "${entries[$i]}"
  done

  echo
  read -rp "Select entry [1-${#entries[@]}]: " choice

  if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#entries[@]} )); then
    echo "Invalid selection." >&2
    exit 1
  fi

  # GRUB uses 0-based index
  selected_index="$((choice-1))"
  echo "Setting next boot to: ${entries[$selected_index]}"
  grub-reboot "$selected_index"
  echo "Done. This applies only to the next boot."
fi
