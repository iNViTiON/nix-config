# `adb connect` to a device before starting scrcpy (address optional).
# Packaged by ../scripts.nix; writeShellApplication adds the shebang and
# `set -o errexit -o nounset -o pipefail`. adb comes from runtimeInputs.

ADDR="${1:-}"

if [ -n "$ADDR" ]; then
  echo "Connecting to $ADDR..."
  adb connect "$ADDR" >/dev/null || {
    echo "Failed to connect to $ADDR"
    exit 1
  }
else
  echo "No address provided — skipping adb connect."
fi

# echo "Starting scrcpy..."
# scrcpy --render-driver=vulkan
