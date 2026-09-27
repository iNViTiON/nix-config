# niri: a few binds are set here; ~/.config/niri/config.kdl stays your own file. Home
# Manager writes them to ~/.config/niri/nix-binds.kdl, and the end of config.kdl includes it
# (`include optional=true "nix-binds.kdl"`). niri lets a later bind replace an earlier one
# for the same key, so these win over config.kdl's binds.
# Change them here and `just switch`; niri reloads by itself.
{ ... }:
{
  xdg.configFile."niri/nix-binds.kdl".text = ''
    binds {
        // DMS launcher. Not Mod+Space (DMS's usual key): Super+Space switches the keyboard
        // layout (XKB option grp:win_space_toggle, from localectl).
        Mod+D hotkey-overlay-title="Run an Application: DMS" { spawn "dms" "ipc" "call" "spotlight" "toggle"; }

        // Volume and brightness keys; DMS's on-screen bar shows the new value. 5% per press, 1% with Shift (like Plasma), 10% with Ctrl.
        // allow-when-locked=true keeps them working on the lock screen. Brightness uses
        // brightnessctl instead of DMS's own command, which never goes below 1%; DMS still
        // shows its bar because it watches the backlight for changes.
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
