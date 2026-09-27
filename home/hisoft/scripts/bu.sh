# Unlock and mount the BitLocker partition; run as root (alias `bu` = `sudo bu`).
# Packaged by ../scripts.nix; writeShellApplication adds the shebang and
# `set -o errexit -o nounset -o pipefail`. The recovery key stays in /etc/blrk,
# outside the Nix store.
#
# The key is piped to cryptsetup on stdin, never passed as an argument: sudo logs every
# command line it runs to the journal, and /proc/<pid>/cmdline is readable by everyone.
# (The old dislocker version put the key on the command line.)

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root: sudo bu" >&2
  exit 1
fi

# CHANGE THESE
BITLOCKER_DEV="/dev/disk/by-uuid/5efd3aed-ae4c-4ee8-bf0a-72df22859652"
RECOVERY_KEY_FILE="/etc/blrk"
MAPPER_NAME="bitlocker"
MOUNT_POINT="/mnt/bitlocker-unlocked"

mkdir -p "$MOUNT_POINT"

echo "Unlocking BitLocker volume…"
tr -d '\n\r\t ' < "$RECOVERY_KEY_FILE" |
  cryptsetup open --type bitlk --key-file=- "$BITLOCKER_DEV" "$MAPPER_NAME"

echo "Mounting NTFS (read/write)…"
mount -t ntfs-3g "/dev/mapper/$MAPPER_NAME" "$MOUNT_POINT" || {
  # Don't leave the unlocked mapping behind, or the next run fails with
  # "device already exists".
  cryptsetup close "$MAPPER_NAME"
  exit 1
}

echo "✅ Mounted at $MOUNT_POINT"

echo "Press any key to unmount BitLocker volume"
# ntfs-3g is a FUSE filesystem; suspending while it is mounted can freeze the system.
systemd-inhibit --what sleep --who bu --why "keep the system from suspending while the BitLocker volume is mounted" bash -c 'read -r -n 1 -s'

until {
  umount "$MOUNT_POINT" &&
  cryptsetup close "$MAPPER_NAME"
}; do
  echo "Failed to unmount BitLocker volume. Press any key to retry"
  read -r -n 1 -s
done

echo "✅ Unmounted"
