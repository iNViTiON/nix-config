# Reset the fingerprint reader and stop fprintd.
# Packaged by ../scripts.nix; writeShellApplication adds the shebang and
# `set -o errexit -o nounset -o pipefail`.

sudo usbreset 06cb:0123
sudo systemctl stop fprintd
