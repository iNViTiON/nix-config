# The personal scripts that lived in ~/.local/bin, built with writeShellApplication:
# shellcheck runs at build time (a finding fails `nixos-rebuild build` with its SC code),
# `set -o errexit -o nounset -o pipefail` is added, and `runtimeInputs` are put in front
# of PATH. The normal PATH stays behind them, so `sudo` is still the setuid
# /run/wrappers/bin/sudo; never add pkgs.sudo to runtimeInputs.
# `claude` and `python3.12` stay in ~/.local/bin (their installers manage them).
{
  osConfig,
  pkgs,
  ...
}:
{
  home.packages = [
    # Pick the entry for the next boot only (`boot-next`, asks for sudo itself).
    (pkgs.writeShellApplication {
      name = "boot-next";
      runtimeInputs = with pkgs; [
        systemd
        gnugrep
        gawk
        coreutils
      ];
      text = builtins.readFile ./scripts/boot-next.sh;
    })

    # Unlock and mount the BitLocker partition (alias `bu` runs it with sudo).
    # mount/umount and the mount.ntfs-3g helper come from the system (util-linux only
    # looks for mount helpers in system paths, so ntfs3g stays in ../../modules/packages.nix).
    (pkgs.writeShellApplication {
      name = "bu";
      runtimeInputs = with pkgs; [
        cryptsetup
        systemd # systemd-inhibit
        coreutils
      ];
      text = builtins.readFile ./scripts/bu.sh;
    })

    # Hibernate even when Bitwarden is running (it blocks hibernation, see the script).
    # DMS's power menu is pointed at it in ./niri.nix.
    (pkgs.writeShellApplication {
      name = "hibernate-safe";
      runtimeInputs = with pkgs; [
        systemd
        procps # pgrep, pkill
        glib # gdbus
        gnugrep
        util-linux # setsid
        coreutils
      ];
      text = builtins.readFile ./scripts/hibernate-safe.sh;
    })

    # Emoji picker on Mod+Shift+Period (./niri.nix): Plasma's picker, plus auto-paste.
    (pkgs.writeShellApplication {
      name = "emoji-pick";
      runtimeInputs = [
        pkgs.kdePackages.plasma-desktop # plasma-emojier
        pkgs.wtype
        pkgs.wl-clipboard
        pkgs.jq
        osConfig.programs.niri.package # niri msg
      ];
      text = builtins.readFile ./scripts/emoji-pick.sh;
    })

    (pkgs.writeShellApplication {
      name = "refprintd";
      runtimeInputs = with pkgs; [
        usbutils
        systemd
      ];
      text = builtins.readFile ./scripts/refprintd.sh;
    })

    (pkgs.writeShellApplication {
      name = "scrcpy-connect";
      runtimeInputs = [ pkgs.android-tools ];
      text = builtins.readFile ./scripts/scrcpy-connect.sh;
    })

    (pkgs.writeShellApplication {
      name = "scrcpy-nd";
      runtimeInputs = [ pkgs.scrcpy ];
      text = "scrcpy --render-driver=vulkan --new-display=1920x1080";
    })

    # Same as the `so` alias.
    (pkgs.writeShellApplication {
      name = "soff";
      runtimeInputs = [ pkgs.kdePackages.libkscreen ];
      text = "kscreen-doctor --dpms off";
    })

    (pkgs.writeShellApplication {
      name = "usbmon";
      runtimeInputs = [ pkgs.usbeehive ];
      text = "usbeehive --watch";
    })
  ];
}
