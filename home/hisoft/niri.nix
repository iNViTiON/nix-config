# niri: some settings are set here; ~/.config/niri/config.kdl stays your own file. Home
# Manager writes two files that config.kdl includes (both `include optional=true …`):
# - nix-outputs.kdl: the laptop panel, with HDR. Included *before* DMS's dms/outputs.kdl,
#   because niri uses the first `output` block for a given name and ignores later ones.
# - nix-binds.kdl: key binds. Included after config.kdl's `binds` block, because a later
#   bind replaces an earlier one for the same key.
# Change them here and `just switch`; niri reloads by itself.
{ ... }:
{
  xdg.configFile."niri/nix-outputs.kdl".text = ''
    // The laptop panel (Samsung OLED). This block wins over the one DMS writes to
    // dms/outputs.kdl, so change resolution/refresh/scale here, not in DMS's display
    // settings; DMS still handles other monitors. mode, scale, position and VRR are what
    // DMS had written.
    output "eDP-1" {
        mode "2880x1800@120.000"
        scale 1
        position x=0 y=0
        variable-refresh-rate on-demand=true
        // niri-spicy's experimental HDR. mode="on" keeps the desktop in HDR like Plasma, so
        // windowed HDR content (e.g. HDR video in Vivaldi) shows as HDR; the default
        // mode="auto" only switches for a fullscreen HDR app.
        hdr mode="on" {
            reference-luminance 400 // SDR white in nits, Plasma's "SDR brightness"
            peak-luminance 950 // Plasma's peak brightness override for this panel
        }
    }
  '';

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
