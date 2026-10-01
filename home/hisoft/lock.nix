# Point DMS's lock at `mitch-lock` (../../modules/lock-screen). DMS keeps the idle timers, lock before suspend
# and the loginctl handling, and runs this command whenever it would lock. DMS's settings.json stays its own
# file (DMS rewrites it), so only this one key is set in it, on every switch. Skipped until DMS has created
# the file. A running DMS is also told directly: it doesn't reliably reload the file when it's changed from
# outside. Same approach as the hibernate command in ./niri.nix.
{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
{
  home.activation.dmsLockCommand = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    f=${lib.escapeShellArg "${config.xdg.configHome}/DankMaterialShell/settings.json"}
    cmd=/run/current-system/sw/bin/mitch-lock
    jq=${lib.getExe pkgs.jq}
    if [[ -f $f && $("$jq" -r '.customPowerActionLock // ""' "$f") != "$cmd" ]]; then
      tmp=$(mktemp "$f.XXXXXX")
      if "$jq" --arg cmd "$cmd" '.customPowerActionLock = $cmd' "$f" > "$tmp"; then
        chmod --reference="$f" "$tmp"
        run mv -f "$tmp" "$f"
      else
        rm -f "$tmp"
      fi
    fi
    if [[ -f $f ]]; then
      XDG_RUNTIME_DIR=''${XDG_RUNTIME_DIR:-/run/user/$(id -u)} run ${pkgs.coreutils}/bin/timeout 5 \
        ${lib.getExe osConfig.programs.dms-shell.package} ipc call settings set \
        customPowerActionLock "$cmd" >/dev/null 2>&1 || true
    fi
  '';
}
