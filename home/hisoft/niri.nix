# niri: some settings are set here; ~/.config/niri/config.kdl stays your own file. It
# includes three files from here (each `include optional=true …`):
# - nix-outputs.kdl: the laptop panel, with HDR. Written by the niri-hdr-brightness
#   service below (it has to change at runtime). Included *before* DMS's dms/outputs.kdl,
#   because niri uses the first `output` block for a given name and ignores later ones.
# - nix-input.kdl: input settings (focus follows mouse), written by Home Manager.
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
  waitForTray = pkgs.writeShellScript "wait-for-tray" ''
    for ((i = 0; i < 150; i++)); do
      ${pkgs.systemd}/bin/busctl --user status org.kde.StatusNotifierWatcher >/dev/null 2>&1 && exit 0
      ${pkgs.coreutils}/bin/sleep 0.2
    done
    exit 0 # start the app anyway, just without a tray icon
  '';
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

  # Input settings, merged into config.kdl's `input` block (a later value wins).
  xdg.configFile."niri/nix-input.kdl".text = ''
    input {
        // Focus the window under the mouse, like Plasma's "Focus follows mouse".
        // max-scroll-amount="100%": hovering a partly visible column also scrolls it into
        // view ("0%" would only focus windows that are already fully visible).
        focus-follows-mouse max-scroll-amount="100%"
    }
  '';

  xdg.configFile."niri/nix-binds.kdl".text = ''
    binds {
        // DMS launcher. Not Mod+Space (DMS's usual key): Super+Space switches the keyboard
        // layout (fcitx5, modules/japanese.nix). Alt+Space as in Plasma's
        // KRunner and PowerToys Run.
        Mod+D hotkey-overlay-title="Run an Application: DMS" { spawn "dms" "ipc" "call" "spotlight" "toggle"; }
        Alt+Space hotkey-overlay-title="Run an Application: DMS" { spawn "dms" "ipc" "call" "spotlight" "toggle"; }

        // File manager, like Super+E on Windows and in Plasma.
        Mod+E hotkey-overlay-title="Open File Manager: Strata" { spawn "strata"; }

        // Default browser (Vivaldi now), whichever app is set as default in the system.
        Mod+B hotkey-overlay-title="Open Web Browser" { spawn-sh "${pkgs.gtk3}/bin/gtk-launch \"$(${pkgs.xdg-utils}/bin/xdg-settings get default-web-browser)\""; }

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

  # Mount USB drives and SD cards automatically, with a notification (shown by DMS). Plasma
  # has its own device handling, so this runs only in niri. No tray icon: udiskie's needs
  # Home Manager's tray.target, which niri doesn't have.
  services.udiskie = {
    enable = true;
    automount = true;
    notify = true;
    tray = "never";
  };

  # Autostart apps (Bitwarden, RQuickShare, KDE Connect, ...) start at the same moment as
  # DMS, before its tray is ready, so their tray icon never appears (Electron apps only try
  # once), and with "start to tray" they look like they never started. Make every autostart
  # app wait for the tray (up to 30 s). In Plasma the tray is already there, so the wait
  # ends at once. The drop-in name matches every app-*@autostart.service.
  xdg.configFile."systemd/user/app-@autostart.service.d/wait-for-tray.conf".text = ''
    [Unit]
    After=dms.service
    [Service]
    ExecStartPre=${waitForTray}
  '';

  systemd.user.services.udiskie = {
    Unit = {
      PartOf = lib.mkForce [ "niri.service" ];
      After = lib.mkForce [ "niri.service" ];
    };
    Install.WantedBy = lib.mkForce [ "niri.service" ];
  };
}
