# niri: some settings are set here; ~/.config/niri/config.kdl stays your own file. It
# includes two files from here (both `include optional=true …`):
# - nix-outputs.kdl: the laptop panel, with HDR. Written by the niri-hdr-brightness
#   service below (it has to change at runtime). Included *before* DMS's dms/outputs.kdl,
#   because niri uses the first `output` block for a given name and ignores later ones.
# - nix-binds.kdl: key binds, written by Home Manager. Included after config.kdl's `binds`
#   block, because a later bind replaces an earlier one for the same key.
# Change them here and `just switch`; niri reloads by itself.
{
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  # In HDR the panel ignores its backlight, so brightness has to be done in software, as
  # Plasma does: the SDR white level (niri-spicy's `reference-luminance`) follows the
  # backlight level. The brightness keys, DMS's slider and DMS's idle dimming all still set
  # the backlight (DMS's on-screen number stays right); this service watches it for changes
  # and rewrites the output block with a matching SDR white. Changing it only redraws the
  # screen, no mode switch.
  hdrBrightness = pkgs.writeShellApplication {
    name = "niri-hdr-brightness";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.systemd # udevadm
      osConfig.programs.niri.package # niri msg
    ];
    text = ''
      out="''${XDG_CONFIG_HOME:-$HOME/.config}/niri/nix-outputs.kdl"
      dev=""
      for d in /sys/class/backlight/*; do
        if [[ -e $d/brightness ]]; then dev=$d; break; fi
      done
      [[ -n $dev ]] || { echo "no backlight device" >&2; exit 1; }
      last=""

      write() {
        local cur max ref tmp
        cur=$(<"$dev/brightness")
        max=$(<"$dev/max_brightness")
        # 100% = 400 nits SDR white (Plasma's "SDR brightness"). The floor is 1 nit, not 0:
        # niri also tells apps this value, and 0 breaks their color math.
        ref=$(( 400 * cur / max ))
        (( ref >= 1 )) || ref=1
        [[ $ref != "$last" ]] || return 0
        tmp=$(mktemp "$out.XXXXXX")
        cat > "$tmp" <<EOF
      // Written by the niri-hdr-brightness service; settings are in ~/nixos-config
      // (home/hisoft/niri.nix). Don't edit, it's rewritten on every brightness change.
      // This block wins over the one DMS writes to dms/outputs.kdl, so change the panel's
      // resolution/refresh/scale in niri.nix, not in DMS's display settings; DMS still
      // handles other monitors. mode, scale, position and VRR are what DMS had written.
      output "eDP-1" {
          mode "2880x1800@120.000"
          scale 1
          position x=0 y=0
          variable-refresh-rate on-demand=true
          // niri-spicy's experimental HDR. mode="on" keeps the desktop in HDR like Plasma,
          // so windowed HDR content (e.g. HDR video in Vivaldi) shows as HDR.
          hdr mode="on" {
              reference-luminance $ref // SDR white in nits: the brightness
              peak-luminance 950 // Plasma's peak brightness override for this panel
          }
      }
      EOF
        mv -f "$tmp" "$out"
        last=$ref
        # Apply now instead of waiting for niri's file check (every 0.5 s).
        niri msg action load-config-file >/dev/null 2>&1 || true
      }

      write
      udevadm monitor --udev --subsystem-match=backlight | while read -r _; do
        # A held key sends ~30 events a second: take them as one update.
        while read -r -t 0.05 _; do :; done
        write
      done
    '';
  };
in
{
  home.packages = [ hdrBrightness ];

  # Runs only in niri (started and stopped with niri.service), never in Plasma.
  systemd.user.services.niri-hdr-brightness = {
    Unit = {
      Description = "HDR brightness for niri (SDR white follows the backlight level)";
      PartOf = [ "niri.service" ];
      After = [ "niri.service" ];
    };
    Service = {
      ExecStart = lib.getExe hdrBrightness;
      Restart = "on-failure";
    };
    Install.WantedBy = [ "niri.service" ];
  };

  xdg.configFile."niri/nix-binds.kdl".text = ''
    binds {
        // DMS launcher. Not Mod+Space (DMS's usual key): Super+Space switches the keyboard
        // layout (XKB option grp:win_space_toggle, from localectl). Alt+Space as in Plasma's
        // KRunner and PowerToys Run.
        Mod+D hotkey-overlay-title="Run an Application: DMS" { spawn "dms" "ipc" "call" "spotlight" "toggle"; }
        Alt+Space hotkey-overlay-title="Run an Application: DMS" { spawn "dms" "ipc" "call" "spotlight" "toggle"; }

        // Volume and brightness keys; DMS's on-screen bar shows the new value. 5% per press,
        // 1% with Shift (like Plasma), 10% with Ctrl. allow-when-locked=true keeps them
        // working on the lock screen. Brightness uses brightnessctl instead of DMS's own
        // command, which never goes below 1%; DMS still shows its bar because it watches the
        // backlight for changes.
        XF86AudioRaiseVolume        allow-when-locked=true { spawn "dms" "ipc" "call" "audio" "increment" "5"; }
        XF86AudioLowerVolume        allow-when-locked=true { spawn "dms" "ipc" "call" "audio" "decrement" "5"; }
        Shift+XF86AudioRaiseVolume  allow-when-locked=true { spawn "dms" "ipc" "call" "audio" "increment" "1"; }
        Shift+XF86AudioLowerVolume  allow-when-locked=true { spawn "dms" "ipc" "call" "audio" "decrement" "1"; }
        Ctrl+XF86AudioRaiseVolume   allow-when-locked=true { spawn "dms" "ipc" "call" "audio" "increment" "10"; }
        Ctrl+XF86AudioLowerVolume   allow-when-locked=true { spawn "dms" "ipc" "call" "audio" "decrement" "10"; }
        XF86AudioMute               allow-when-locked=true { spawn "dms" "ipc" "call" "audio" "mute"; }
        XF86AudioMicMute            allow-when-locked=true { spawn "dms" "ipc" "call" "audio" "micmute"; }
        XF86MonBrightnessUp         allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "5%+"; }
        XF86MonBrightnessDown       allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "5%-"; }
        Shift+XF86MonBrightnessUp   allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "1%+"; }
        Shift+XF86MonBrightnessDown allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "1%-"; }
        Ctrl+XF86MonBrightnessUp    allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "10%+"; }
        Ctrl+XF86MonBrightnessDown  allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "10%-"; }
    }
  '';
}
