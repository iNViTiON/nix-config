# niri: only the DMS launcher hotkey is set here; ~/.config/niri/config.kdl stays your own
# file. Home Manager writes the bind to ~/.config/niri/nix-binds.kdl, and the end of
# config.kdl includes it (`include optional=true "nix-binds.kdl"`). niri lets a later bind
# replace an earlier one for the same key, so this one wins over config.kdl's binds.
# Change it here and `just switch`; niri reloads by itself.
{ ... }:
{
  xdg.configFile."niri/nix-binds.kdl".text = ''
    binds {
        // Not Mod+Space (DMS's usual key): Super+Space switches the keyboard layout
        // (XKB option grp:win_space_toggle, from localectl).
        Mod+D hotkey-overlay-title="Run an Application: DMS" { spawn "dms" "ipc" "call" "spotlight" "toggle"; }
    }
  '';
}
