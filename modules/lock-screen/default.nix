# Lock screen: DMS hands every lock to `mitch-lock` (customPowerActionLock, set in home/hisoft/lock.nix). It is
# a Quickshell session lock showing the desktop wallpaper behind the same scene as the boot splash and login
# screen, with a clock, password and fingerprint unlock, media controls and a count of new notifications.
# Sprites, Friend.qml and Anim.js are shared with the boot splash and the SDDM theme and copied in at build time.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  sprites = [
    "mitch" "malu" "pear_n" "pear_f" "bean_n" "bean_f" "round_n" "round_f" "bean2_n" "bean2_f" "flat_n"
    "a_star" "a_yarc" "a_arc" "a_bdash" "a_pdash" "swish0" "swish1" "swish2"
  ];

  # Gaegu with ä ö ü õ and kana added (../mitch-font)
  font = import ../mitch-font { inherit pkgs; };

  qml = pkgs.stdenvNoCC.mkDerivation {
    pname = "mitch-lock-qml";
    version = "1";
    src = ./qml;
    dontBuild = true;
    installPhase = ''
      runHook preInstall
      mkdir -p $out/assets
      cp *.qml $out/
      cp ${../sddm-theme/theme/Friend.qml} $out/Friend.qml
      cp ${../sddm-theme/theme/Anim.js} $out/Anim.js
      ${lib.concatMapStringsSep "\n" (n: "cp ${../boot-animation/mitch-theme}/${n}.png $out/assets/") sprites}
      cp ${font}/share/fonts/truetype/GaeguMitch-Regular.ttf $out/assets/GaeguMitch.ttf
      runHook postInstall
    '';
  };

  quickshell = config.programs.dms-shell.quickshell.package;

  # Small helper the lock screen runs for the status line, the profile picture and the weather location.
  mitch-lock-info = pkgs.writeShellApplication {
    name = "mitch-lock-info";
    runtimeInputs = with pkgs; [
      coreutils
      gawk
      gnugrep
      imagemagick
      networkmanager
      wireplumber
      bluez
      socat
    ];
    text = ''
      case "''${1:-}" in
        status)
          bat=""
          for d in /sys/class/power_supply/BAT*; do
            if [ -r "$d/capacity" ]; then
              bat="$(cat "$d/capacity") $(cat "$d/status")"
              break
            fi
          done
          echo "battery=$bat"
          net=$(timeout 3 nmcli -t -f TYPE,STATE,CONNECTION device 2>/dev/null \
            | awk -F: '$2 == "connected" && ($1 == "wifi" || $1 == "ethernet") { print $1 ":" $3; exit }' || true)
          echo "network=$net"
          vol=$(timeout 3 wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || true)
          echo "volume=$vol"
          if timeout 3 bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
            n=$(timeout 3 bluetoothctl devices Connected 2>/dev/null | wc -l || true)
            echo "bluetooth=on $n"
          else
            echo "bluetooth=off"
          fi
          ;;
        luma)
          # average brightness of a wallpaper, 0 (black) to 1 (white), so the lock only dims bright pictures
          magick "$2" -resize '1x1!' -colorspace Gray -format '%[fx:mean]' info:
          ;;
        profile)
          for f in "/var/lib/AccountsService/icons/$(id -un)" "$HOME/.face" "$HOME/.face.icon"; do
            if [ -f "$f" ]; then
              echo "$f"
              break
            fi
          done
          ;;
        location)
          # DMS keeps the detected location; ask it over its socket, like DMS's own weather does
          sock="''${DMS_SOCKET:-}"
          if [ -z "$sock" ]; then
            for f in "/run/user/$(id -u)"/danklinux-*.sock; do
              if [ -S "$f" ]; then
                sock="$f"
                break
              fi
            done
          fi
          if [ -n "$sock" ]; then
            { printf '{"id":1,"method":"location.getState"}\n'; sleep 2; } \
              | timeout 6 socat - "UNIX-CONNECT:$sock" 2>/dev/null | grep '"id":1' | head -n 1 || true
          fi
          ;;
        *)
          echo "usage: mitch-lock-info status|profile|location|luma PATH" >&2
          exit 2
          ;;
      esac
    '';
  };

  # Stable command name for DMS's settings; the QML store path inside changes with every edit. If Quickshell
  # fails for any reason (QML error, crash), fall back to swaylock so the screen never stays unlocked.
  mitch-lock = pkgs.writeShellApplication {
    name = "mitch-lock";
    runtimeInputs = [
      quickshell
      mitch-lock-info
      pkgs.swaylock
      pkgs.util-linux
      pkgs.coreutils
    ];
    text = ''
      exec 9>"''${XDG_RUNTIME_DIR:-/tmp}/mitch-lock.lock"
      flock -n 9 || exit 0
      log="''${XDG_STATE_HOME:-$HOME/.local/state}/mitch-lock.log"
      mkdir -p "$(dirname "$log")"
      if quickshell -p ${qml} >>"$log" 2>&1; then
        exit 0
      fi
      echo "$(date -Is) mitch-lock: quickshell failed, falling back to swaylock" >>"$log"
      exec swaylock -c 000000
    '';
  };
in
{
  environment.systemPackages = [
    mitch-lock
    mitch-lock-info
  ];

  # Password-only stack, and a fingerprint-only stack: run side by side so a fingerprint wait never blocks the
  # password prompt (pam_fprintd inside the password stack would).
  security.pam.services.mitch-lock.fprintAuth = false;
  security.pam.services.mitch-lock-fprint = {
    unixAuth = false;
    fprintAuth = true;
  };
}
